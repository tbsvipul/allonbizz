using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Helpers;

public static class AdminAccountHelper
{
    private static readonly HashSet<string> AllowedAdminRoles = new(StringComparer.OrdinalIgnoreCase)
    {
        AdminRoles.SuperAdmin,
        AdminRoles.Admin,
        AdminRoles.Moderator,
        AdminRoles.Analyst
    };

    public static string NormalizeEmail(string email)
    {
        var normalized = email?.Trim().ToLowerInvariant() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException("Email is required.");
        }

        return normalized;
    }

    public static string NormalizeAdminRole(string role)
    {
        var normalized = role?.Trim().ToLowerInvariant() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException("Role is required.");
        }

        if (!AllowedAdminRoles.Contains(normalized))
        {
            throw new ArgumentException("Invalid admin role.");
        }

        return normalized;
    }

    public static string RequireValue(string value, string fieldName)
    {
        var normalized = value?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException($"{fieldName} is required.");
        }

        return normalized;
    }

    public static void ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            throw new ArgumentException("Password is required.");
        }

        if (password.Length < 8)
        {
            throw new ArgumentException("Password must be at least 8 characters.");
        }

        // Relaxing character checks for development/testing ease. 
        // In production, uncomment the complexity checks below.
        /*
        if (!password.Any(char.IsUpper) || !password.Any(char.IsLower) || !password.Any(char.IsDigit))
        {
            throw new ArgumentException("Password must include upper-case, lower-case, and numeric characters.");
        }
        */
    }

    public static List<string> ResolvePermissions(string role, IEnumerable<string>? permissions)
    {
        var normalizedRole = role?.Trim().ToLowerInvariant() ?? string.Empty;
        var defaultPermissions = AppPermissions.RoleDefaults
            .GetValueOrDefault(normalizedRole, new List<string>())
            .Where(permission => !string.IsNullOrWhiteSpace(permission))
            .Select(permission => permission.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (normalizedRole.Equals(Roles.SuperAdmin, StringComparison.OrdinalIgnoreCase))
        {
            return defaultPermissions;
        }

        var normalizedPermissions = permissions?
            .Where(permission => !string.IsNullOrWhiteSpace(permission))
            .Select(permission => permission.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (normalizedPermissions is { Count: > 0 })
        {
            return normalizedPermissions;
        }

        return defaultPermissions;
    }
}
