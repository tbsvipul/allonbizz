using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using allonbiz.AdminAPI.Constants;

namespace allonbiz.AdminAPI.Helpers;

/// <summary>
/// Extension methods for extracting user identity from JWT claims safely.
/// </summary>
public static class ClaimsPrincipalExtensions
{
    /// <summary>
    /// Safely extracts the user ID (Guid) from ClaimsPrincipal.
    /// Throws UnauthorizedAccessException if the claim is missing or invalid.
    /// </summary>
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var idClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(idClaim) || !Guid.TryParse(idClaim, out var userId))
            throw new UnauthorizedAccessException("Invalid or missing authentication token.");
        return userId;
    }

    public static bool HasPermission(this ClaimsPrincipal user, string permission)
    {
        if (user.IsInRole(Roles.SuperAdmin))
        {
            return true;
        }

        return user.FindAll("permission")
            .Select(claim => claim.Value)
            .Concat(
                user.FindFirst("permissions")?.Value?
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                ?? Array.Empty<string>())
            .Contains(permission, StringComparer.OrdinalIgnoreCase);
    }
}
