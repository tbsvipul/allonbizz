using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Auth;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/auth")]
public class AdminAuthController : ControllerBase
{
    private readonly IAdminAuthService _adminAuthService;

    public AdminAuthController(IAdminAuthService adminAuthService)
    {
        _adminAuthService = adminAuthService;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto dto)
    {
        try
        {
            var result = await _adminAuthService.LoginAsync(dto, HttpContext.Connection.RemoteIpAddress?.ToString());
            return Ok(ApiResponse<LoginResponseDto>.Ok(result));
        }
        catch (UnauthorizedAccessException ex) when (ex.Message == "2FA_REQUIRED")
        {
            return Unauthorized(ApiResponse<object>.Fail("AUTH_2FA_REQUIRED", "Two-factor authentication is required."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail("AUTH_UNAUTHORIZED", ex.Message));
        }
    }

    [HttpPost("refresh-token")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto dto)
    {
        try
        {
            var result = await _adminAuthService.RefreshTokenAsync(dto.RefreshToken);
            return Ok(ApiResponse<TokenResponseDto>.Ok(result));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail("AUTH_INVALID_TOKEN", ex.Message));
        }
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout()
    {
        await _adminAuthService.LogoutAsync(User);
        return Ok(ApiResponse<object?>.Ok(null, "Logged out successfully."));
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetMe()
    {
        var profile = await _adminAuthService.GetCurrentUserAsync(User);
        return Ok(ApiResponse<AdminProfileDto>.Ok(profile));
    }

    [HttpPut("profile")]
    [Authorize]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateAdminProfileDto dto)
    {
        await _adminAuthService.UpdateProfileAsync(User, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Profile updated successfully."));
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto dto)
    {
        await _adminAuthService.ChangePasswordAsync(User, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Password changed successfully."));
    }

    [HttpPost("2fa/setup")]
    [Authorize]
    public async Task<IActionResult> Setup2FA()
    {
        var result = await _adminAuthService.Setup2FAAsync(User);
        return Ok(ApiResponse<Setup2FAResponseDto>.Ok(result));
    }

    [HttpPost("2fa/enable")]
    [Authorize]
    public async Task<IActionResult> Enable2FA([FromBody] Verify2FARequestDto dto)
    {
        await _adminAuthService.Enable2FAAsync(User, dto.Totp);
        return Ok(ApiResponse<object?>.Ok(null, "2FA enabled successfully."));
    }

    [HttpPost("2fa/disable")]
    [Authorize]
    public async Task<IActionResult> Disable2FA([FromBody] Verify2FARequestDto dto)
    {
        await _adminAuthService.Disable2FAAsync(User, dto.Totp);
        return Ok(ApiResponse<object?>.Ok(null, "2FA disabled successfully."));
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto dto)
    {
        await _adminAuthService.ForgotPasswordAsync(dto.Email);
        return Ok(ApiResponse<object?>.Ok(null, "If an account exists with this email, an OTP has been sent."));
    }

    [HttpPost("verify-otp")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto dto)
    {
        var resetToken = await _adminAuthService.ValidateOtpAsync(dto.Email, dto.Otp);
        if (resetToken == null)
            return BadRequest(ApiResponse<object>.Fail("AUTH_INVALID_OTP", "Invalid or expired OTP."));

        return Ok(ApiResponse<OtpValidationResponseDto>.Ok(new OtpValidationResponseDto { ResetToken = resetToken }));
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto dto)
    {
        await _adminAuthService.ResetPasswordAsync(dto.Token, dto.NewPassword);
        return Ok(ApiResponse<object?>.Ok(null, "Password has been reset successfully."));
    }
}
