using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text.Json;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Settings;
using allonbiz.AdminAPI.DTOs.System;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class SettingsService : ISettingsService
{
    private readonly AppDbContext _db;
    private readonly IRepository<AdminAccount> _adminRepo;
    private readonly IRepository<PlatformRule> _ruleRepo;
    private readonly IAdminAuthService _adminAuthService;
    private readonly IAuditService _auditService;

    public SettingsService(
        AppDbContext db,
        IRepository<AdminAccount> adminRepo,
        IRepository<PlatformRule> ruleRepo,
        IAdminAuthService adminAuthService,
        IAuditService auditService)
    {
        _db = db;
        _adminRepo = adminRepo;
        _ruleRepo = ruleRepo;
        _adminAuthService = adminAuthService;
        _auditService = auditService;
    }

    public async Task<SystemConfigDto> GetSettingsAsync(CancellationToken ct = default)
    {
        var rules = await _ruleRepo.Query().Where(r => r.Group == "General").ToListAsync(ct);
        var settings = rules.ToDictionary(rule => rule.Key, rule => rule.Value, StringComparer.OrdinalIgnoreCase);

        return new SystemConfigDto
        {
            BaseUrl = GetRuleValue(settings, nameof(SystemConfigDto.BaseUrl)),
            FirebaseProjectId = GetRuleValue(settings, nameof(SystemConfigDto.FirebaseProjectId)),
            ApiVersion = GetRuleValue(settings, nameof(SystemConfigDto.ApiVersion), "v1"),
            Environment = GetRuleValue(settings, nameof(SystemConfigDto.Environment), "Production"),
            ExternalServices = DeserializeExternalServices(GetRuleValue(settings, nameof(SystemConfigDto.ExternalServices), "{}"))
        };
    }

    public async Task UpdateSettingsAsync(UpdateSettingsDto dto, CancellationToken ct = default)
    {
        var settings = dto.Config ?? throw new ArgumentException("Config payload is required.");

        await UpsertRuleAsync("General", nameof(SystemConfigDto.BaseUrl), settings.BaseUrl, "Base URL", ct);
        await UpsertRuleAsync("General", nameof(SystemConfigDto.FirebaseProjectId), settings.FirebaseProjectId, "Firebase project ID", ct);
        await UpsertRuleAsync("General", nameof(SystemConfigDto.ApiVersion), settings.ApiVersion, "API version", ct);
        await UpsertRuleAsync("General", nameof(SystemConfigDto.Environment), settings.Environment, "Application environment", ct);
        await UpsertRuleAsync(
            "General",
            nameof(SystemConfigDto.ExternalServices),
            JsonSerializer.Serialize(settings.ExternalServices ?? new Dictionary<string, string>()),
            "External service settings",
            ct);

        await _ruleRepo.SaveChangesAsync(ct);
    }

    public async Task<SecuritySettingsDto> GetSecuritySettingsAsync(CancellationToken ct = default)
    {
        var rules = await _ruleRepo.Query().Where(r => r.Group == "Security").ToListAsync(ct);
        var settings = rules.ToDictionary(rule => rule.Key, rule => rule.Value, StringComparer.OrdinalIgnoreCase);

        return new SecuritySettingsDto
        {
            Enforce2FA = bool.TryParse(GetRuleValue(settings, nameof(UpdateSecurityDto.Enforce2FA), "false"), out var enforce2Fa) && enforce2Fa,
            PasswordExpirationDays = int.TryParse(GetRuleValue(settings, nameof(UpdateSecurityDto.PasswordExpirationDays), "90"), out var passwordDays) ? passwordDays : 90
        };
    }

    public async Task UpdateSecuritySettingsAsync(UpdateSecurityDto dto, CancellationToken ct = default)
    {
        await UpsertRuleAsync("Security", nameof(UpdateSecurityDto.Enforce2FA), dto.Enforce2FA.ToString(), "Require 2FA for admins", ct);
        await UpsertRuleAsync("Security", nameof(UpdateSecurityDto.PasswordExpirationDays), dto.PasswordExpirationDays.ToString(), "Admin password expiration", ct);
        await _ruleRepo.SaveChangesAsync(ct);
    }

    public async Task<PagedResponse<AdminListItemDto>> GetAdminsAsync(AdminListQueryDto query, CancellationToken ct = default)
    {
        var adminsQuery = _adminRepo.Query().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            adminsQuery = adminsQuery.Where(a =>
                a.Email.ToLower().Contains(search) ||
                a.FirstName.ToLower().Contains(search) ||
                a.LastName.ToLower().Contains(search));
        }

        if (!string.IsNullOrWhiteSpace(query.Role))
        {
            adminsQuery = adminsQuery.Where(a => a.Role == query.Role.ToLower());
        }

        if (query.IsActive.HasValue)
        {
            adminsQuery = adminsQuery.Where(a => a.IsActive == query.IsActive.Value);
        }

        var totalCount = await adminsQuery.CountAsync(ct);
        var admins = await adminsQuery
            .OrderBy(a => a.FirstName)
            .ThenBy(a => a.LastName)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(a => new AdminListItemDto
            {
                AdminId = a.AdminId,
                Email = a.Email,
                FirstName = a.FirstName,
                LastName = a.LastName,
                Role = a.Role,
                IsActive = a.IsActive,
                Is2FAEnabled = a.Is2FAEnabled,
                LastLoginAt = a.LastLoginAt
            })
            .ToListAsync(ct);

        return new PagedResponse<AdminListItemDto>
        {
            Data = admins,
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<AdminDetailDto> CreateAdminAsync(CreateAdminRequestDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        _ = await GetRequiredAdminAsync(actorAdminId, ct);
        var email = AdminAccountHelper.NormalizeEmail(dto.Email);
        if (await _adminRepo.Query().AnyAsync(admin => admin.Email == email, ct))
        {
            throw new InvalidOperationException("Email is already in use by another admin.");
        }

        var role = AdminAccountHelper.NormalizeAdminRole(dto.Role);
        EnsureActorCanAssignRole(role);
        var temporaryPassword = GenerateTemporaryPassword();
        var admin = new AdminAccount
        {
            Email = email,
            PasswordHash = PasswordHelper.HashPassword(temporaryPassword),
            FirstName = AdminAccountHelper.RequireValue(dto.FirstName, "First name"),
            LastName = AdminAccountHelper.RequireValue(dto.LastName, "Last name"),
            Role = role,
            IsActive = dto.IsActive,
            Permissions = AdminAccountHelper.ResolvePermissions(role, dto.Permissions),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _adminRepo.AddAsync(admin, ct);

        try
        {
            await _adminRepo.SaveChangesAsync(ct);
            await _adminAuthService.ForgotPasswordAsync(admin.Email);
            await _auditService.LogAsync(actorAdminId, "ADMIN_CREATE", nameof(AdminAccount), admin.AdminId.ToString(), null, "N/A");
            return await GetAdminAsync(admin.AdminId, ct);
        }
        catch
        {
            _adminRepo.Remove(admin);
            await _adminRepo.SaveChangesAsync(ct);
            throw;
        }
    }

    public async Task<AdminDetailDto> GetAdminAsync(Guid adminId, CancellationToken ct = default)
    {
        var a = await _adminRepo.GetByIdAsync(adminId, ct);
        if (a == null) throw new KeyNotFoundException($"Admin {adminId} not found.");
        return new AdminDetailDto
        {
            AdminId = a.AdminId,
            Email = a.Email,
            Role = a.Role,
            FirstName = a.FirstName,
            LastName = a.LastName,
            IsActive = a.IsActive,
            Is2FAEnabled = a.Is2FAEnabled,
            LastLoginAt = a.LastLoginAt,
            Permissions = AdminAccountHelper.ResolvePermissions(a.Role, a.Permissions),
            FailedLoginAttempts = a.FailedLoginAttempts,
            LockoutEnd = a.LockoutEnd
        };
    }

    public async Task UpdateAdminAsync(Guid adminId, UpdateAdminRequestDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var actor = await GetRequiredAdminAsync(actorAdminId, ct);
        var a = await _adminRepo.GetByIdAsync(adminId, ct);
        if (a == null) throw new KeyNotFoundException($"Admin {adminId} not found.");

        var email = AdminAccountHelper.NormalizeEmail(dto.Email);
        if (!email.Equals(a.Email, StringComparison.OrdinalIgnoreCase) &&
            await _adminRepo.Query().AnyAsync(admin => admin.Email == email && admin.AdminId != adminId, ct))
        {
            throw new InvalidOperationException("Email is already in use by another admin.");
        }

        var role = AdminAccountHelper.NormalizeAdminRole(dto.Role);
        EnsureActorCanManageTarget(actor, a, role);
        EnsureSelfAdminUpdateRules(actor, a, role, dto.IsActive);
        a.Email = email;
        a.FirstName = AdminAccountHelper.RequireValue(dto.FirstName, "First name");
        a.LastName = AdminAccountHelper.RequireValue(dto.LastName, "Last name");
        a.Role = role;
        a.IsActive = dto.IsActive;
        a.Permissions = AdminAccountHelper.ResolvePermissions(role, dto.Permissions);
        a.UpdatedAt = DateTime.UtcNow;

        _adminRepo.Update(a);

        if (!a.IsActive)
        {
            await RevokeActiveTokensAsync(adminId, ct);
        }

        await _adminRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "ADMIN_UPDATE", nameof(AdminAccount), adminId.ToString(), null, "N/A");
    }

    public async Task DeleteAdminAsync(Guid adminId, Guid actorAdminId, CancellationToken ct = default)
    {
        EnsureActorIsNotTarget(actorAdminId, adminId, "delete your own administrator account");

        var a = await _adminRepo.GetByIdAsync(adminId, ct);
        if (a != null)
        {
            await RevokeActiveTokensAsync(adminId, ct);
            _adminRepo.Remove(a);
            await _adminRepo.SaveChangesAsync(ct);
            await _auditService.LogAsync(actorAdminId, "ADMIN_DELETE", nameof(AdminAccount), adminId.ToString(), null, "N/A");
        }
    }

    public async Task ResetAdminPasswordAsync(Guid adminId, Guid actorAdminId, CancellationToken ct = default)
    {
        EnsureActorIsNotTarget(actorAdminId, adminId, "trigger a password reset for your own administrator account");

        var admin = await _adminRepo.GetByIdAsync(adminId, ct)
            ?? throw new KeyNotFoundException($"Admin {adminId} not found.");

        await RevokeActiveTokensAsync(adminId, ct);
        await _adminRepo.SaveChangesAsync(ct);
        await _adminAuthService.ForgotPasswordAsync(admin.Email);
        await _auditService.LogAsync(actorAdminId, "ADMIN_RESET_PASSWORD", nameof(AdminAccount), adminId.ToString(), null, "N/A");
    }

    public async Task TerminateAdminSessionsAsync(Guid adminId, Guid actorAdminId, CancellationToken ct = default)
    {
        EnsureActorIsNotTarget(actorAdminId, adminId, "terminate your own administrator sessions from this endpoint");

        _ = await _adminRepo.GetByIdAsync(adminId, ct)
            ?? throw new KeyNotFoundException($"Admin {adminId} not found.");

        await RevokeActiveTokensAsync(adminId, ct);
        await _adminRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "ADMIN_TERMINATE_SESSIONS", nameof(AdminAccount), adminId.ToString(), null, "N/A");
    }

    private async Task UpsertRuleAsync(string group, string key, string? value, string description, CancellationToken ct)
    {
        var rule = await _ruleRepo.Query()
            .FirstOrDefaultAsync(item => item.Group == group && item.Key == key, ct);

        if (rule == null)
        {
            rule = new PlatformRule
            {
                Group = group,
                Key = key,
                Value = value ?? string.Empty,
                Description = description,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _ruleRepo.AddAsync(rule, ct);
            return;
        }

        rule.Value = value ?? string.Empty;
        rule.Description = description;
        rule.IsActive = true;
        rule.UpdatedAt = DateTime.UtcNow;
        _ruleRepo.Update(rule);
    }

    private async Task RevokeActiveTokensAsync(Guid adminId, CancellationToken ct)
    {
        var tokens = await _db.RefreshTokens
            .Where(token => token.UserId == adminId && !token.IsUsed && !token.IsRevoked)
            .ToListAsync(ct);

        foreach (var token in tokens)
        {
            token.IsRevoked = true;
        }
    }

    private static string GetRuleValue(IReadOnlyDictionary<string, string> rules, string key, string defaultValue = "")
    {
        return rules.TryGetValue(key, out var value) ? value : defaultValue;
    }

    private static Dictionary<string, string> DeserializeExternalServices(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return new Dictionary<string, string>();
        }

        return JsonSerializer.Deserialize<Dictionary<string, string>>(value) ?? new Dictionary<string, string>();
    }

    private async Task<AdminAccount> GetRequiredAdminAsync(Guid adminId, CancellationToken ct)
    {
        return await _adminRepo.GetByIdAsync(adminId, ct)
            ?? throw new KeyNotFoundException($"Admin {adminId} not found.");
    }

    private static void EnsureActorIsNotTarget(Guid actorAdminId, Guid targetAdminId, string action)
    {
        if (actorAdminId == targetAdminId)
        {
            throw new InvalidOperationException($"You cannot {action}.");
        }
    }

    private static void EnsureActorCanAssignRole(string targetRole)
    {
        if (IsSuperAdmin(targetRole))
        {
            throw new InvalidOperationException("Only one super admin account is allowed. Creating another super admin is disabled.");
        }
    }

    private static void EnsureActorCanManageTarget(AdminAccount actor, AdminAccount target, string nextRole)
    {
        if (IsSuperAdmin(nextRole) && !IsSuperAdmin(target.Role))
        {
            throw new InvalidOperationException("Only one super admin account is allowed. Promoting another admin to super admin is disabled.");
        }

        if (!IsSuperAdmin(actor.Role) && IsSuperAdmin(target.Role))
        {
            throw new InvalidOperationException("Only the existing super admin can manage the super admin account.");
        }
    }

    private static void EnsureSelfAdminUpdateRules(AdminAccount actor, AdminAccount target, string nextRole, bool isActive)
    {
        if (actor.AdminId != target.AdminId)
        {
            return;
        }

        if (!IsSuperAdmin(target.Role))
        {
            return;
        }

        if (!IsSuperAdmin(nextRole))
        {
            throw new InvalidOperationException("Super admins cannot remove their own super admin role.");
        }

        if (!isActive)
        {
            throw new InvalidOperationException("Super admins cannot deactivate their own account.");
        }
    }

    private static bool IsSuperAdmin(string role)
    {
        return role.Equals(Roles.SuperAdmin, StringComparison.OrdinalIgnoreCase);
    }

    private static string GenerateTemporaryPassword()
    {
        const string upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
        const string lower = "abcdefghijkmnopqrstuvwxyz";
        const string digits = "23456789";
        const string symbols = "!@$%&*?";
        var allChars = $"{upper}{lower}{digits}{symbols}";

        Span<char> buffer = stackalloc char[20];
        buffer[0] = upper[RandomNumberGenerator.GetInt32(upper.Length)];
        buffer[1] = lower[RandomNumberGenerator.GetInt32(lower.Length)];
        buffer[2] = digits[RandomNumberGenerator.GetInt32(digits.Length)];
        buffer[3] = symbols[RandomNumberGenerator.GetInt32(symbols.Length)];

        for (var i = 4; i < buffer.Length; i++)
        {
            buffer[i] = allChars[RandomNumberGenerator.GetInt32(allChars.Length)];
        }

        for (var i = buffer.Length - 1; i > 0; i--)
        {
            var swapIndex = RandomNumberGenerator.GetInt32(i + 1);
            (buffer[i], buffer[swapIndex]) = (buffer[swapIndex], buffer[i]);
        }

        return new string(buffer);
    }
}
