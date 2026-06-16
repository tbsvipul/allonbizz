using System.Security.Claims;
using routent.AdminAPI.DTOs.Admin;
using routent.AdminAPI.DTOs.Auth;
using routent.AdminAPI.DTOs.Users;

namespace routent.AdminAPI.Services.Interfaces;

public interface IAuthService
{
    // Common
    Task<TokenResponseDto> RefreshTokenAsync(string refreshToken);
    Task LogoutAsync(ClaimsPrincipal user);
    Task ChangePasswordAsync(ClaimsPrincipal user, ChangePasswordRequestDto dto);
    Task ForgotPasswordAsync(string email);
    Task ResetPasswordAsync(string token, string newPassword);
    Task SendOtpAsync(string email);
    Task<string?> ValidateOtpAsync(string email, string otp);

    // User/Keeper specific
    Task<UserLoginResponseDto> RegisterUserAsync(UserRegisterRequestDto dto, string? ipAddress = null);
    Task<UserLoginResponseDto> RegisterKeeperAsync(KeeperRegisterRequestDto dto, string? ipAddress = null);
    Task<UserLoginResponseDto> UserLoginAsync(UserLoginRequestDto dto, string? ipAddress = null);
}
