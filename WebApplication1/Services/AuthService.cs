using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Auth;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace allonbiz.AdminAPI.Services;

public class AuthService : IAuthService
{
    private const string AccountTypeAdmin = "admin";
    private const string AccountTypeUser = "user";
    private const string ChallengeTypeOtp = "otp";
    private const string ChallengeTypePasswordReset = "password_reset";
    private const int MaxFailedLoginAttempts = 5;
    private static readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);

    private readonly AppDbContext _db;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;
    private readonly IAuditService _auditService;

    public AuthService(
        AppDbContext db,
        IJwtService jwtService,
        ILogger<AuthService> logger,
        IConfiguration configuration,
        IEmailService emailService,
        IAuditService auditService)
    {
        _db = db;
        _jwtService = jwtService;
        _logger = logger;
        _configuration = configuration;
        _emailService = emailService;
        _auditService = auditService;
    }

    public async Task<TokenResponseDto> RefreshTokenAsync(string refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            throw new ArgumentException("Refresh token is required.");
        }

        var storedToken = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.Token == HashSecret(refreshToken));

        if (storedToken == null || !storedToken.IsActive)
        {
            throw new UnauthorizedAccessException("Invalid or expired refresh token.");
        }

        var subject = await ResolveTokenSubjectAsync(storedToken.UserId, storedToken.Role);
        var newRefreshToken = _jwtService.GenerateRefreshToken();

        storedToken.IsUsed = true;
        storedToken.ReplacedByToken = HashSecret(newRefreshToken);
        _db.RefreshTokens.Add(CreateRefreshTokenEntity(storedToken.UserId, subject.Role, newRefreshToken));

        var newAccessToken = _jwtService.GenerateAccessToken(
            storedToken.UserId,
            subject.Email,
            subject.Role,
            subject.Permissions);

        await _db.SaveChangesAsync();

        return new TokenResponseDto
        {
            AccessToken = newAccessToken,
            RefreshToken = newRefreshToken,
            ExpiresIn = GetAccessTokenExpiryMinutes() * 60
        };
    }

    public async Task LogoutAsync(ClaimsPrincipal user)
    {
        var userId = user.GetUserId();
        await RevokeActiveTokensAsync(userId);
        await _db.SaveChangesAsync();
        await _auditService.LogAsync(userId, "LOGOUT", "Auth", userId.ToString(), null, "N/A");
        _logger.LogInformation("User {UserId} logged out and active refresh tokens were revoked", userId);
    }

    public async Task ForgotPasswordAsync(string email)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(email);
        if (!await AccountExistsAsync(normalizedEmail))
        {
            return;
        }

        await SendOtpAsync(normalizedEmail);
        _logger.LogInformation("Password recovery initiated for an existing account");
    }

    public async Task ResetPasswordAsync(string token, string newPassword)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new ArgumentException("Password reset token is required.");
        }

        AdminAccountHelper.ValidatePassword(newPassword);

        var challenge = await _db.AuthChallenges
            .Where(item =>
                item.ChallengeType == ChallengeTypePasswordReset &&
                item.ConsumedAt == null &&
                item.ExpiresAt > DateTime.UtcNow &&
                item.SecretHash == HashSecret(token))
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync();

        if (challenge == null)
        {
            throw new UnauthorizedAccessException("Invalid or expired password reset token.");
        }

        if (challenge.AccountType == AccountTypeAdmin)
        {
            var admin = await _db.AdminAccounts.FirstOrDefaultAsync(a => EF.Functions.ILike(a.Email, challenge.Email))
                ?? throw new KeyNotFoundException("Account not found.");

            admin.PasswordHash = PasswordHelper.HashPassword(newPassword);
            admin.UpdatedAt = DateTime.UtcNow;
            challenge.ConsumedAt = DateTime.UtcNow;
            await RevokeActiveTokensAsync(admin.AdminId);
            await _db.SaveChangesAsync();

            await _auditService.LogAsync(admin.AdminId, "RESET_PASSWORD_ADMIN", "AdminAccount", admin.AdminId.ToString(), null, "N/A");
            _logger.LogInformation("Password reset completed for admin {AdminId}", admin.AdminId);
            return;
        }

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email != null && EF.Functions.ILike(u.Email, challenge.Email))
            ?? throw new KeyNotFoundException("Account not found.");

        user.PasswordHash = PasswordHelper.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;
        challenge.ConsumedAt = DateTime.UtcNow;
        await RevokeActiveTokensAsync(user.UserId);
        await _db.SaveChangesAsync();
        await _auditService.LogAsync(user.UserId, "RESET_PASSWORD_USER", nameof(User), user.UserId.ToString(), null, "N/A");

        _logger.LogInformation("Password reset completed for user {UserId}", user.UserId);
    }

    public async Task SendOtpAsync(string email)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(email);
        var account = await ResolveAccountAsync(normalizedEmail);
        if (account == null)
        {
            return;
        }

        await ExpireOpenChallengesAsync(normalizedEmail, account.Value.AccountType);

        var otp = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        _db.AuthChallenges.Add(new AuthChallenge
        {
            AccountType = account.Value.AccountType,
            AccountId = account.Value.AccountId,
            Email = normalizedEmail,
            ChallengeType = ChallengeTypeOtp,
            SecretHash = HashSecret(otp),
            ExpiresAt = DateTime.UtcNow.AddMinutes(5),
            CreatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
        await _emailService.SendOtpEmailAsync(normalizedEmail, otp);
    }

    public async Task<string?> ValidateOtpAsync(string email, string otp)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(email);
        var challenge = await _db.AuthChallenges
            .Where(item =>
                item.Email == normalizedEmail &&
                item.ChallengeType == ChallengeTypeOtp &&
                item.ConsumedAt == null &&
                item.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync();

        if (challenge == null || !challenge.SecretHash.Equals(HashSecret(otp?.Trim() ?? string.Empty), StringComparison.Ordinal))
        {
            return null;
        }

        challenge.ConsumedAt = DateTime.UtcNow;
        var resetToken = _jwtService.GenerateRefreshToken();

        _db.AuthChallenges.Add(new AuthChallenge
        {
            AccountType = challenge.AccountType,
            AccountId = challenge.AccountId,
            Email = challenge.Email,
            ChallengeType = ChallengeTypePasswordReset,
            SecretHash = HashSecret(resetToken),
            ExpiresAt = DateTime.UtcNow.AddMinutes(15),
            CreatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
        return resetToken;
    }

    public async Task<UserLoginResponseDto> RegisterUserAsync(UserRegisterRequestDto dto, string? ipAddress = null)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(dto.Email);
        AdminAccountHelper.ValidatePassword(dto.Password);

        if (await AccountExistsAsync(normalizedEmail))
        {
            throw new InvalidOperationException("Email is already taken.");
        }

        var now = DateTime.UtcNow;
        var user = new User
        {
            Email = normalizedEmail,
            FirstName = AdminAccountHelper.RequireValue(dto.FirstName, "First name"),
            LastName = AdminAccountHelper.RequireValue(dto.LastName, "Last name"),
            PasswordHash = PasswordHelper.HashPassword(dto.Password),
            Role = Roles.Customer,
            IsActive = true,
            Status = UserStatus.Active,
            StatusChangedAt = now,
            LastLoginAt = now,
            LastLoginIp = ipAddress,
            CreatedAt = now,
            UpdatedAt = now
        };
        _db.Users.Add(user);
        var permissions = ResolvePermissions(Roles.Customer, null);
        var accessToken = _jwtService.GenerateAccessToken(user.UserId, user.Email, Roles.Customer, permissions);
        var refreshToken = _jwtService.GenerateRefreshToken();
        _db.RefreshTokens.Add(CreateRefreshTokenEntity(user.UserId, Roles.Customer, refreshToken, ipAddress));

        await _db.SaveChangesAsync();

        _logger.LogInformation("Registered customer account {UserId}", user.UserId);

        return new UserLoginResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = GetAccessTokenExpiryMinutes() * 60,
            Role = Roles.Customer,
            UserId = user.UserId
        };
    }

    public async Task<UserLoginResponseDto> RegisterKeeperAsync(KeeperRegisterRequestDto dto, string? ipAddress = null)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(dto.Email);
        AdminAccountHelper.ValidatePassword(dto.Password);

        if (await AccountExistsAsync(normalizedEmail))
        {
            throw new InvalidOperationException("Email is already taken.");
        }

        var now = DateTime.UtcNow;
        var user = new User
        {
            Email = normalizedEmail,
            FirstName = AdminAccountHelper.RequireValue(dto.FirstName, "First name"),
            LastName = AdminAccountHelper.RequireValue(dto.LastName, "Last name"),
            PasswordHash = PasswordHelper.HashPassword(dto.Password),
            Role = Roles.Keeper,
            IsActive = true,
            Status = UserStatus.Active,
            StatusChangedAt = now,
            LastLoginAt = now,
            LastLoginIp = ipAddress,
            CreatedAt = now,
            UpdatedAt = now
        };
        _db.Users.Add(user);

        var keeper = new Keeper
        {
            UserId = user.UserId,
            BusinessName = AdminAccountHelper.RequireValue(dto.BusinessName, "Business name"),
            BusinessLicense = dto.BusinessLicense?.Trim(),
            Status = KeeperStatus.PendingApproval
        };
        _db.Keepers.Add(keeper);

        var permissions = ResolvePermissions(Roles.Keeper, null);
        var accessToken = _jwtService.GenerateAccessToken(user.UserId, user.Email, Roles.Keeper, permissions);
        var refreshToken = _jwtService.GenerateRefreshToken();
        _db.RefreshTokens.Add(CreateRefreshTokenEntity(user.UserId, Roles.Keeper, refreshToken, ipAddress));

        await _db.SaveChangesAsync();

        _logger.LogInformation("Registered keeper account {UserId}", user.UserId);

        return new UserLoginResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = GetAccessTokenExpiryMinutes() * 60,
            Role = Roles.Keeper,
            UserId = user.UserId
        };
    }

    public async Task<UserLoginResponseDto> UserLoginAsync(UserLoginRequestDto dto, string? ipAddress = null)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(dto.Email);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email != null && EF.Functions.ILike(u.Email, normalizedEmail));

        if (user == null)
        {
            _logger.LogWarning("Failed login attempt for non-existent user: {Email}", normalizedEmail);
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        if (user.LockoutEnd.HasValue && user.LockoutEnd.Value > DateTime.UtcNow)
        {
            _logger.LogWarning("Login attempt for locked out user: {Email}", normalizedEmail);
            throw new UnauthorizedAccessException("Account is temporarily locked. Please try again later.");
        }

        if (string.IsNullOrWhiteSpace(user.PasswordHash) || !PasswordHelper.VerifyPassword(dto.Password, user.PasswordHash))
        {
            _logger.LogWarning("Invalid password for user: {Email}", normalizedEmail);
            await RegisterFailedUserLoginAsync(user);
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        NormalizeExpiredSuspension(user);
        EnsureUserCanAuthenticate(user, normalizedEmail);

        user.FailedLoginAttempts = 0;
        user.LockoutEnd = null;
        user.LastLoginAt = DateTime.UtcNow;
        user.LastLoginIp = ipAddress;
        user.UpdatedAt = DateTime.UtcNow;

        var permissions = ResolvePermissions(user.Role, null);
        var accessToken = _jwtService.GenerateAccessToken(user.UserId, user.Email ?? normalizedEmail, user.Role, permissions);
        var refreshToken = _jwtService.GenerateRefreshToken();
        _db.RefreshTokens.Add(CreateRefreshTokenEntity(user.UserId, user.Role, refreshToken, ipAddress));

        await _db.SaveChangesAsync();

        _logger.LogInformation("User {UserId} logged in successfully from {IP}", user.UserId, ipAddress ?? "unknown");

        return new UserLoginResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = GetAccessTokenExpiryMinutes() * 60,
            Role = user.Role,
            UserId = user.UserId
        };
    }

    private RefreshToken CreateRefreshTokenEntity(Guid userId, string role, string rawToken, string? createdByIp = null)
    {
        return new RefreshToken
        {
            Token = HashSecret(rawToken),
            UserId = userId,
            Role = role,
            CreatedByIp = createdByIp,
            ExpiresAt = DateTime.UtcNow.AddDays(GetRefreshTokenExpiryDays())
        };
    }

    private async Task<(string Email, string Role, List<string> Permissions)> ResolveTokenSubjectAsync(Guid userId, string role)
    {
        var admin = await _db.AdminAccounts.AsNoTracking().FirstOrDefaultAsync(a => a.AdminId == userId);
        if (admin != null)
        {
            if (!admin.IsActive)
            {
                throw new UnauthorizedAccessException("Token subject is inactive.");
            }

            return (admin.Email, admin.Role, ResolvePermissions(admin.Role, admin.Permissions));
        }

        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId)
            ?? throw new UnauthorizedAccessException("Token subject could not be resolved.");

        if (!IsUserActive(user))
        {
            throw new UnauthorizedAccessException("Token subject is inactive.");
        }

        return (user.Email ?? userId.ToString(), user.Role, ResolvePermissions(user.Role, null));
    }

    private async Task<bool> AccountExistsAsync(string normalizedEmail)
    {
        return await _db.AdminAccounts.AnyAsync(a => EF.Functions.ILike(a.Email, normalizedEmail)) ||
               await _db.Users.AnyAsync(u => u.Email != null && EF.Functions.ILike(u.Email, normalizedEmail));
    }

    private async Task<(string AccountType, Guid AccountId)?> ResolveAccountAsync(string normalizedEmail)
    {
        var admin = await _db.AdminAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(account => EF.Functions.ILike(account.Email, normalizedEmail));

        if (admin != null)
        {
            return (AccountTypeAdmin, admin.AdminId);
        }

        var user = await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(account => account.Email != null && EF.Functions.ILike(account.Email, normalizedEmail));

        return user == null ? null : (AccountTypeUser, user.UserId);
    }

    private async Task ExpireOpenChallengesAsync(string normalizedEmail, string accountType)
    {
        var openChallenges = await _db.AuthChallenges
            .Where(item =>
                item.Email == normalizedEmail &&
                item.AccountType == accountType &&
                item.ConsumedAt == null)
            .ToListAsync();

        foreach (var challenge in openChallenges)
        {
            challenge.ConsumedAt = DateTime.UtcNow;
        }
    }

    private async Task RegisterFailedUserLoginAsync(User user)
    {
        user.FailedLoginAttempts += 1;
        user.UpdatedAt = DateTime.UtcNow;

        if (user.FailedLoginAttempts >= MaxFailedLoginAttempts)
        {
            user.LockoutEnd = DateTime.UtcNow.Add(LockoutDuration);
            user.FailedLoginAttempts = 0;
        }

        await _db.SaveChangesAsync();
    }

    private async Task RevokeActiveTokensAsync(Guid userId)
    {
        var tokens = await _db.RefreshTokens
            .Where(t => t.UserId == userId && !t.IsUsed && !t.IsRevoked)
            .ToListAsync();

        foreach (var token in tokens)
        {
            token.IsRevoked = true;
        }
    }

    private static bool IsUserActive(User user)
    {
        return user.IsActive && user.Status == UserStatus.Active;
    }

    private static void NormalizeExpiredSuspension(User user)
    {
        if (user.Status == UserStatus.Suspended &&
            user.SuspendedUntil.HasValue &&
            user.SuspendedUntil.Value <= DateTime.UtcNow)
        {
            user.Status = UserStatus.Active;
            user.IsActive = true;
            user.StatusReason = null;
            user.SuspendedUntil = null;
            user.StatusChangedAt = DateTime.UtcNow;
        }
    }

    private void EnsureUserCanAuthenticate(User user, string normalizedEmail)
    {
        if (IsUserActive(user))
        {
            return;
        }

        _logger.LogWarning("Login attempt for inactive user: {Email}", normalizedEmail);

        throw user.Status switch
        {
            UserStatus.Banned => new UnauthorizedAccessException("Account is banned."),
            UserStatus.Suspended when user.SuspendedUntil.HasValue =>
                new UnauthorizedAccessException($"Account is suspended until {user.SuspendedUntil.Value:yyyy-MM-dd HH:mm:ss} UTC."),
            UserStatus.Suspended => new UnauthorizedAccessException("Account is suspended."),
            UserStatus.PendingVerification => new UnauthorizedAccessException("Account is pending verification."),
            _ => new UnauthorizedAccessException("Account is inactive.")
        };
    }

    private static List<string> ResolvePermissions(string role, IEnumerable<string>? permissions)
    {
        return permissions?.Any() == true
            ? permissions.Distinct(StringComparer.OrdinalIgnoreCase).ToList()
            : AppPermissions.RoleDefaults.GetValueOrDefault(role, new List<string>()).ToList();
    }

    private int GetAccessTokenExpiryMinutes()
    {
        return int.TryParse(_configuration["JwtSettings:AccessTokenExpiryMinutes"], out var minutes) && minutes > 0
            ? minutes
            : 30;
    }

    private int GetRefreshTokenExpiryDays()
    {
        return int.TryParse(_configuration["JwtSettings:RefreshTokenExpiryDays"], out var days) && days > 0
            ? days
            : 7;
    }

    private static string HashSecret(string value)
    {
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
    }
}
