using System.Security.Claims;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Auth;

namespace allonbiz.AdminAPI.Services.Interfaces;

public interface IAdminAuthService
{
    Task<LoginResponseDto> LoginAsync(LoginRequestDto dto, string? ipAddress = null);
    Task<TokenResponseDto> RefreshTokenAsync(string refreshToken);
    Task LogoutAsync(ClaimsPrincipal user);
    Task<AdminProfileDto> GetCurrentUserAsync(ClaimsPrincipal user);
    Task UpdateProfileAsync(ClaimsPrincipal user, UpdateAdminProfileDto dto);
    Task ChangePasswordAsync(ClaimsPrincipal user, ChangePasswordRequestDto dto);
    
    // 2FA
    Task<Setup2FAResponseDto> Setup2FAAsync(ClaimsPrincipal user);
    Task Enable2FAAsync(ClaimsPrincipal user, string totp);
    Task Disable2FAAsync(ClaimsPrincipal user, string totp);

    // Password Reset
    Task ForgotPasswordAsync(string email);
    Task<string?> ValidateOtpAsync(string email, string otp);
    Task ResetPasswordAsync(string token, string newPassword);
}
