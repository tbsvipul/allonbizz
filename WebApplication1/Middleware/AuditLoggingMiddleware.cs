using System.Security.Claims;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Middleware;

public class AuditLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<AuditLoggingMiddleware> _logger;
    private static readonly string[] AuditMethods = { "POST", "PUT", "DELETE", "PATCH" };

    public AuditLoggingMiddleware(
        RequestDelegate next,
        ILogger<AuditLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, IAuditService auditService)
    {
        await _next(context);

        if (AuditMethods.Contains(context.Request.Method) &&
            context.Response.StatusCode is >= 200 and < 300 &&
            context.User.Identity?.IsAuthenticated == true)
        {
            var role = context.User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrWhiteSpace(role) ||
                (!role.Equals("admin", StringComparison.OrdinalIgnoreCase) && 
                 !role.Equals("super_admin", StringComparison.OrdinalIgnoreCase)))
            {
                return;
            }

            var adminIdStr = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (adminIdStr != null && Guid.TryParse(adminIdStr, out var adminId))
            {
                try
                {
                    var endpoint = context.GetEndpoint();
                    var routeData = context.GetRouteData();
                    
                    string entity = "unknown";
                    string targetId = "N/A";

                    if (routeData != null)
                    {
                        // Standard practice: first part after /api/v1/ is the entity
                        var pathParts = context.Request.Path.Value?.Split('/', StringSplitOptions.RemoveEmptyEntries);
                        if (pathParts != null && pathParts.Length >= 3)
                        {
                            entity = pathParts[2]; // e.g., "users" in /api/v1/users/xxx
                        }

                        // Try to find an ID in the route values
                        foreach (var key in routeData.Values.Keys)
                        {
                            if (key.EndsWith("Id", StringComparison.OrdinalIgnoreCase) || key == "id")
                            {
                                targetId = routeData.Values[key]?.ToString() ?? "N/A";
                                break;
                            }
                        }
                    }

                    await auditService.LogAsync(
                        adminId: adminId,
                        action: $"{context.Request.Method} {context.Request.Path}",
                        targetEntity: entity,
                        targetId: targetId,
                        ipAddress: context.Connection.RemoteIpAddress?.ToString(),
                        userAgent: context.Request.Headers.UserAgent.ToString()
                    );
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Audit logging failed for {Method} {Path}", context.Request.Method, context.Request.Path);
                }
            }
        }
    }
}
