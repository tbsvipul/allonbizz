using System.Security.Claims;

namespace routent.AdminAPI.Services.Interfaces;

public interface IJwtService
{
    string GenerateAccessToken(Guid adminId, string email, string role, List<string> permissions);
    string GenerateRefreshToken();
    ClaimsPrincipal? ValidateToken(string token);
    Guid? GetAdminIdFromToken(ClaimsPrincipal principal);
}
