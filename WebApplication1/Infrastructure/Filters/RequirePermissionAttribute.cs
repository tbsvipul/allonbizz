using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Filters;

[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequirePermissionAttribute : Attribute, IAuthorizationFilter
{
    private readonly string _permission;

    public RequirePermissionAttribute(string permission) => _permission = permission;

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;
        if (user.Identity?.IsAuthenticated != true)
        {
            context.Result = ControllerProblemExtensions.CreateProblemResult(
                context.HttpContext,
                StatusCodes.Status401Unauthorized,
                "Unauthorized",
                "Authentication is required to access this resource.");
            return;
        }

        // 1. SuperAdmin Bypass
        if (user.IsInRole(Roles.SuperAdmin))
        {
            return;
        }

        // 2. Permission Check
        var permissions = user.FindAll("permission")
            .Select(claim => claim.Value)
            .Concat(
                user.FindFirst("permissions")?.Value?
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                ?? Array.Empty<string>())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        if (!permissions.Contains(_permission))
        {
            context.Result = ControllerProblemExtensions.CreateProblemResult(
                context.HttpContext,
                StatusCodes.Status403Forbidden,
                "Forbidden",
                $"The authenticated principal does not have the required permission '{_permission}'.");
        }
    }
}
