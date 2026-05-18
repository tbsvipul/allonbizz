using Microsoft.IdentityModel.Tokens;
using allonbiz.AdminAPI.Services.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace allonbiz.AdminAPI.Services;

public class JwtService : IJwtService
{
    private readonly IConfiguration _config;

    public JwtService(IConfiguration config) => _config = config;

    public string GenerateAccessToken(Guid adminId, string email, string role, List<string> permissions)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, adminId.ToString()),
            new(ClaimTypes.Email, email),
            new(ClaimTypes.Role, role)
        };
        claims.AddRange(
            permissions
                .Where(permission => !string.IsNullOrWhiteSpace(permission))
                .Select(permission => permission.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Select(permission => new Claim("permission", permission)));

        var creds = new SigningCredentials(GetSigningKey(), SecurityAlgorithms.HmacSha256);
        var expiry = DateTime.UtcNow.AddMinutes(GetAccessTokenExpiryMinutes());

        var token = new JwtSecurityToken(
            issuer: _config["JwtSettings:Issuer"],
            audience: _config["JwtSettings:Audience"],
            claims: claims,
            expires: expiry,
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var bytes = new byte[64];
        RandomNumberGenerator.Fill(bytes);
        return Convert.ToBase64String(bytes);
    }

    public ClaimsPrincipal? ValidateToken(string token)
    {
        try
        {
            var handler = new JwtSecurityTokenHandler();

            return handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = _config["JwtSettings:Issuer"],
                ValidAudience = _config["JwtSettings:Audience"],
                IssuerSigningKey = GetSigningKey(),
                ClockSkew = TimeSpan.Zero
            }, out _);
        }
        catch
        {
            return null;
        }
    }

    public Guid? GetAdminIdFromToken(ClaimsPrincipal principal)
    {
        var idClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(idClaim, out var id) ? id : null;
    }

    private SymmetricSecurityKey GetSigningKey()
    {
        var secret = _config["JwtSettings:SecretKey"]
            ?? throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");

        if (secret.Length < 32)
        {
            throw new InvalidOperationException("JwtSettings:SecretKey must be at least 32 characters long.");
        }

        if (IsPlaceholderSecret(secret))
        {
            throw new InvalidOperationException("JwtSettings:SecretKey must be replaced with a real secret.");
        }

        return new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
    }

    private double GetAccessTokenExpiryMinutes()
    {
        if (double.TryParse(_config["JwtSettings:AccessTokenExpiryMinutes"], out var minutes) && minutes > 0)
        {
            return minutes;
        }

        return 30;
    }

    private static bool IsPlaceholderSecret(string value)
    {
        var normalized = value.Trim();
        return normalized.Contains("REPLACE_WITH", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("YOUR_", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("CHANGE_ME", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("CHANGE-THIS", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("PLACEHOLDER", StringComparison.OrdinalIgnoreCase);
    }
}
