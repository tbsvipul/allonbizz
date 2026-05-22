using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Auth;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService) => _authService = authService;


    // BootstrapAdmin removed for security. Initial admins should be created via SQL or secure management tools.

    [HttpPost("register-user")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterUser([FromBody] UserRegisterRequestDto dto)
        => Ok(ApiResponse<UserLoginResponseDto>.Ok(await _authService.RegisterUserAsync(dto, Request.HttpContext.Connection.RemoteIpAddress?.ToString())));

    [HttpPost("register-keeper")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterKeeper([FromForm] KeeperRegisterRequestDto dto)
        => Ok(ApiResponse<UserLoginResponseDto>.Ok(await _authService.RegisterKeeperAsync(dto, Request.HttpContext.Connection.RemoteIpAddress?.ToString())));

    [HttpPost("user-login")]
    [AllowAnonymous]
    public async Task<IActionResult> UserLogin([FromBody] UserLoginRequestDto dto)
        => Ok(ApiResponse<UserLoginResponseDto>.Ok(await _authService.UserLoginAsync(dto, Request.HttpContext.Connection.RemoteIpAddress?.ToString())));

    [HttpPost("refresh-token")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto dto)
        => Ok(ApiResponse<TokenResponseDto>.Ok(await _authService.RefreshTokenAsync(dto.RefreshToken)));

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout()
    {
        await _authService.LogoutAsync(User);
        return NoContent();
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto dto)
    {
        await _authService.ChangePasswordAsync(User, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Password changed successfully."));
    }

    [HttpPost("send-otp")]
    [AllowAnonymous]
    public async Task<IActionResult> SendOtp([FromBody] ForgotPasswordRequestDto dto)
    {
        await _authService.SendOtpAsync(dto.Email);
        return Ok(ApiResponse<object?>.Ok(null, "OTP sent successfully"));
    }


    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto dto)
    {
        await _authService.ForgotPasswordAsync(dto.Email);
        return Ok(ApiResponse<object?>.Ok(null, "Recovery instructions sent if the account exists"));
    }

    [HttpPost("verify-otp")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto dto)
    {
        var resetToken = await _authService.ValidateOtpAsync(dto.Email, dto.Otp);
        return resetToken is not null
            ? Ok(ApiResponse<OtpValidationResponseDto>.Ok(new OtpValidationResponseDto { ResetToken = resetToken }, "OTP verified"))
            : this.ValidationProblemResponse("Invalid or expired OTP.", nameof(dto.Otp));
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto dto)
    {
        await _authService.ResetPasswordAsync(dto.Token, dto.NewPassword);
        return Ok(ApiResponse<object?>.Ok(null, "Password reset successfully"));
    }


}
