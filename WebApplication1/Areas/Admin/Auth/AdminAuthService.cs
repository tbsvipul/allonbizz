using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Constants;
using routent.AdminAPI.Data;
using routent.AdminAPI.DTOs.Admin;
using routent.AdminAPI.DTOs.Auth;
using routent.AdminAPI.Helpers;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Services.Interfaces;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace routent.AdminAPI.Services;

public class AdminAuthService : IAdminAuthService
{
    private const string AccountTypeAdmin = "admin";
    private const string ChallengeTypeOtp = "otp";
    private const string ChallengeTypePasswordReset = "password_reset";
    private const int MaxFailedLoginAttempts = 5;
    private static readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);

    private readonly AppDbContext _db;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AdminAuthService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;
    private readonly IAuditService _auditService;

    public AdminAuthService(
        AppDbContext db,
        IJwtService jwtService,
        ILogger<AdminAuthService> logger,
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

    public async Task<LoginResponseDto> LoginAsync(LoginRequestDto dto, string? ipAddress = null)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(dto.Email);
        var safeIdentifier = AdminAccountHelper.ToSafeLogIdentifier(normalizedEmail);
        var admin = await _db.AdminAccounts.FirstOrDefaultAsync(a => a.Email == normalizedEmail);

        if (admin == null)
        {
            _logger.LogWarning("Admin login attempt for unknown account {AdminIdentifier}", safeIdentifier);
            await _auditService.LogAsync(Guid.Empty, "ADMIN_LOGIN_FAILED_UNKNOWN", "Auth", normalizedEmail, ipAddress, "N/A");
            throw new UnauthorizedAccessException("Invalid email or password.");
        }

        if (!admin.IsActive)
        {
            _logger.LogWarning("Admin login attempt for inactive account {AdminIdentifier}", safeIdentifier);
            throw new UnauthorizedAccessException("Account is disabled. Please contact system administrator.");
        }

        if (admin.LockoutEnd.HasValue && admin.LockoutEnd.Value > DateTime.UtcNow)
        {
            _logger.LogWarning("Admin login attempt for locked account {AdminIdentifier}", safeIdentifier);
            throw new UnauthorizedAccessException($"Account is locked until {admin.LockoutEnd.Value:HH:mm:ss UTC}.");
        }

        if (!PasswordHelper.VerifyPassword(dto.Password, admin.PasswordHash))
        {
            await HandleFailedLoginAsync(admin);
            await _auditService.LogAsync(admin.AdminId, "ADMIN_LOGIN_FAILED_PASSWORD", "Auth", admin.Email, ipAddress, "N/A");
            throw new UnauthorizedAccessException("Invalid email or password.");
        }

        if (await Is2FaGloballyRequiredAsync() && !admin.Is2FAEnabled)
        {
            throw new UnauthorizedAccessException("Two-factor authentication setup is required for this admin account.");
        }

        if (admin.Is2FAEnabled)
        {
            if (string.IsNullOrWhiteSpace(dto.Totp))
            {
                throw new UnauthorizedAccessException("2FA_REQUIRED");
            }

            if (string.IsNullOrEmpty(admin.TotpSecret) || !TotpHelper.ValidateTotp(admin.TotpSecret, dto.Totp))
            {
                await HandleFailedLoginAsync(admin);
                throw new UnauthorizedAccessException("Invalid 2FA code.");
            }
        }

        admin.FailedLoginAttempts = 0;
        admin.LockoutEnd = null;
        admin.LastLoginAt = DateTime.UtcNow;
        admin.LastLoginIp = ipAddress;
        admin.UpdatedAt = DateTime.UtcNow;

        var permissions = ResolvePermissions(admin.Role, admin.Permissions);
        var accessToken = _jwtService.GenerateAccessToken(admin.AdminId, admin.Email, admin.Role, permissions);
        var refreshToken = _jwtService.GenerateRefreshToken();

        _db.RefreshTokens.Add(CreateRefreshTokenEntity(admin.AdminId, admin.Role, refreshToken, ipAddress));

        await _db.SaveChangesAsync();
        await _auditService.LogAsync(admin.AdminId, "ADMIN_LOGIN_SUCCESS", "Auth", admin.AdminId.ToString(), ipAddress, "N/A");

        return new LoginResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = GetAccessTokenExpiryMinutes() * 60,
            Admin = new AdminProfileDto
            {
                AdminId = admin.AdminId,
                Email = admin.Email,
                FirstName = admin.FirstName,
                LastName = admin.LastName,
                Role = admin.Role,
                Permissions = permissions,
                Is2FAEnabled = admin.Is2FAEnabled,
                LastLoginAt = admin.LastLoginAt
            }
        };
    }

    public async Task<TokenResponseDto> RefreshTokenAsync(string refreshToken)
    {
        var hashedToken = HashSecret(refreshToken);
        var storedToken = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.Token == hashedToken && !t.IsUsed && !t.IsRevoked && t.ExpiresAt > DateTime.UtcNow);

        if (storedToken == null)
        {
            throw new UnauthorizedAccessException("Invalid or expired refresh token.");
        }

        var admin = await _db.AdminAccounts.FindAsync(storedToken.UserId);
        if (admin == null || !admin.IsActive)
        {
            throw new UnauthorizedAccessException("User no longer exists or is inactive.");
        }

        var newRefreshToken = _jwtService.GenerateRefreshToken();
        storedToken.IsUsed = true;
        storedToken.ReplacedByToken = HashSecret(newRefreshToken);
        _db.RefreshTokens.Add(CreateRefreshTokenEntity(admin.AdminId, admin.Role, newRefreshToken));

        var permissions = ResolvePermissions(admin.Role, admin.Permissions);
        var accessToken = _jwtService.GenerateAccessToken(admin.AdminId, admin.Email, admin.Role, permissions);

        await _db.SaveChangesAsync();

        return new TokenResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = newRefreshToken,
            ExpiresIn = GetAccessTokenExpiryMinutes() * 60
        };
    }

    public async Task LogoutAsync(ClaimsPrincipal user)
    {
        var adminId = user.GetUserId();
        await RevokeActiveTokensAsync(adminId);
        await _db.SaveChangesAsync();
        await _auditService.LogAsync(adminId, "ADMIN_LOGOUT", "Auth", adminId.ToString(), null, "N/A");
    }

    public async Task<AdminProfileDto> GetCurrentUserAsync(ClaimsPrincipal user)
    {
        var adminId = user.GetUserId();
        var admin = await _db.AdminAccounts.AsNoTracking().FirstOrDefaultAsync(a => a.AdminId == adminId)
            ?? throw new KeyNotFoundException("Admin account not found.");

        return new AdminProfileDto
        {
            AdminId = admin.AdminId,
            Email = admin.Email,
            FirstName = admin.FirstName,
            LastName = admin.LastName,
            Role = admin.Role,
            Permissions = ResolvePermissions(admin.Role, admin.Permissions),
            Is2FAEnabled = admin.Is2FAEnabled,
            LastLoginAt = admin.LastLoginAt
        };
    }

    public async Task UpdateProfileAsync(ClaimsPrincipal user, UpdateAdminProfileDto dto)
    {
        var adminId = user.GetUserId();
        var admin = await _db.AdminAccounts.FindAsync(adminId)
            ?? throw new KeyNotFoundException("Admin account not found.");

        admin.FirstName = dto.FirstName ?? admin.FirstName;
        admin.LastName = dto.LastName ?? admin.LastName;

        if (!string.IsNullOrWhiteSpace(dto.Email))
        {
            var normalizedEmail = AdminAccountHelper.NormalizeEmail(dto.Email);
            if (admin.Email != normalizedEmail)
            {
                if (await _db.AdminAccounts.AnyAsync(a => a.Email == normalizedEmail))
                {
                    throw new InvalidOperationException("Email is already in use by another admin.");
                }

                admin.Email = normalizedEmail;
            }
        }

        admin.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await _auditService.LogAsync(adminId, "ADMIN_PROFILE_UPDATE", "Auth", adminId.ToString(), null, "N/A");
    }

    public async Task ChangePasswordAsync(ClaimsPrincipal user, ChangePasswordRequestDto dto)
    {
        var adminId = user.GetUserId();
        var admin = await _db.AdminAccounts.FindAsync(adminId)
            ?? throw new KeyNotFoundException("Admin account not found.");

        if (!PasswordHelper.VerifyPassword(dto.CurrentPassword, admin.PasswordHash))
        {
            throw new ArgumentException("Current password is incorrect.");
        }

        AdminAccountHelper.ValidatePassword(dto.NewPassword);
        admin.PasswordHash = PasswordHelper.HashPassword(dto.NewPassword);
        admin.UpdatedAt = DateTime.UtcNow;
        await RevokeActiveTokensAsync(adminId);

        await _db.SaveChangesAsync();
        await _auditService.LogAsync(adminId, "ADMIN_PASSWORD_CHANGE", "Auth", adminId.ToString(), null, "N/A");
    }

    public async Task<Setup2FAResponseDto> Setup2FAAsync(ClaimsPrincipal user)
    {
        var adminId = user.GetUserId();
        var admin = await _db.AdminAccounts.FindAsync(adminId)
            ?? throw new KeyNotFoundException("Admin account not found.");

        var secret = TotpHelper.GenerateSecret();
        admin.TotpSecret = secret;
        admin.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var qrUri = TotpHelper.GenerateQrUri(secret, admin.Email);
        return new Setup2FAResponseDto
        {
            Secret = secret,
            QrUri = qrUri
        };
    }

    public async Task Enable2FAAsync(ClaimsPrincipal user, string totp)
    {
        var adminId = user.GetUserId();
        var admin = await _db.AdminAccounts.FindAsync(adminId)
            ?? throw new KeyNotFoundException("Admin account not found.");

        if (string.IsNullOrEmpty(admin.TotpSecret))
        {
            throw new InvalidOperationException("2FA setup not initiated.");
        }

        if (!TotpHelper.ValidateTotp(admin.TotpSecret, totp))
        {
            throw new ArgumentException("Invalid 2FA code.");
        }

        admin.Is2FAEnabled = true;
        admin.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await _auditService.LogAsync(adminId, "ADMIN_2FA_ENABLED", "Auth", adminId.ToString(), null, "N/A");
    }

    public async Task Disable2FAAsync(ClaimsPrincipal user, string totp)
    {
        var adminId = user.GetUserId();
        var admin = await _db.AdminAccounts.FindAsync(adminId)
            ?? throw new KeyNotFoundException("Admin account not found.");

        if (!admin.Is2FAEnabled)
        {
            throw new InvalidOperationException("2FA is not enabled.");
        }

        if (string.IsNullOrEmpty(admin.TotpSecret) || !TotpHelper.ValidateTotp(admin.TotpSecret, totp))
        {
            throw new ArgumentException("Invalid 2FA code.");
        }

        admin.Is2FAEnabled = false;
        admin.TotpSecret = null;
        admin.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await _auditService.LogAsync(adminId, "ADMIN_2FA_DISABLED", "Auth", adminId.ToString(), null, "N/A");
    }

    public async Task ForgotPasswordAsync(string email)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(email);
        var admin = await _db.AdminAccounts.FirstOrDefaultAsync(a => a.Email == normalizedEmail);

        if (admin == null)
        {
            return;
        }

        await ExpireOpenChallengesAsync(normalizedEmail, AccountTypeAdmin);

        var otp = RandomNumberGenerator.GetInt32(100000, 999999).ToString();
        _db.AuthChallenges.Add(new AuthChallenge
        {
            AccountType = AccountTypeAdmin,
            AccountId = admin.AdminId,
            Email = normalizedEmail,
            ChallengeType = ChallengeTypeOtp,
            SecretHash = HashSecret(otp),
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            CreatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
        await _emailService.SendOtpEmailAsync(normalizedEmail, otp);
        _logger.LogInformation(
            "Password reset OTP sent to admin {AdminIdentifier}",
            AdminAccountHelper.ToSafeLogIdentifier(normalizedEmail));
    }

    public async Task<string?> ValidateOtpAsync(string email, string otp)
    {
        var normalizedEmail = AdminAccountHelper.NormalizeEmail(email);
        var challenge = await _db.AuthChallenges
            .Where(item =>
                item.AccountType == AccountTypeAdmin &&
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

    public async Task ResetPasswordAsync(string token, string newPassword)
    {
        var challenge = await _db.AuthChallenges
            .Where(item =>
                item.AccountType == AccountTypeAdmin &&
                item.ChallengeType == ChallengeTypePasswordReset &&
                item.ConsumedAt == null &&
                item.ExpiresAt > DateTime.UtcNow &&
                item.SecretHash == HashSecret(token))
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync();

        if (challenge == null)
        {
            throw new UnauthorizedAccessException("Invalid or expired reset token.");
        }

        var admin = await _db.AdminAccounts.FirstOrDefaultAsync(a => a.Email == challenge.Email)
            ?? throw new KeyNotFoundException("Admin account no longer exists.");

        AdminAccountHelper.ValidatePassword(newPassword);
        admin.PasswordHash = PasswordHelper.HashPassword(newPassword);
        admin.UpdatedAt = DateTime.UtcNow;
        challenge.ConsumedAt = DateTime.UtcNow;
        await RevokeActiveTokensAsync(admin.AdminId);

        await _db.SaveChangesAsync();
        await _auditService.LogAsync(admin.AdminId, "ADMIN_PASSWORD_RESET", "Auth", admin.AdminId.ToString(), null, "N/A");
    }

    private async Task HandleFailedLoginAsync(AdminAccount admin)
    {
        admin.FailedLoginAttempts++;
        if (admin.FailedLoginAttempts >= MaxFailedLoginAttempts)
        {
            admin.LockoutEnd = DateTime.UtcNow.Add(LockoutDuration);
            admin.FailedLoginAttempts = 0;
            _logger.LogWarning(
                "Admin account {AdminIdentifier} locked due to multiple failed attempts",
                AdminAccountHelper.ToSafeLogIdentifier(admin.Email));
        }

        admin.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
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

    private async Task<bool> Is2FaGloballyRequiredAsync()
    {
        var rawValue = await _db.PlatformRules
            .AsNoTracking()
            .Where(rule => rule.Group == "Security" && rule.Key == "Enforce2FA")
            .Select(rule => rule.Value)
            .FirstOrDefaultAsync();

        return bool.TryParse(rawValue, out var required) && required;
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

    private static List<string> ResolvePermissions(string role, List<string>? customPermissions)
    {
        return AdminAccountHelper.ResolvePermissions(role, customPermissions);
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
