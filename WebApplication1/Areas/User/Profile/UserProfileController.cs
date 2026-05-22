using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserProfileController : ControllerBase
{
    private readonly IUserProfileService _profileService;

    public UserProfileController(IUserProfileService profileService) => _profileService = profileService;

    /// <summary>GET /api/v1/user/profile — Get current user's profile.</summary>
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.GetUserId();
        var result = await _profileService.GetProfileAsync(userId);
        return Ok(ApiResponse<UserProfileDto>.Ok(result));
    }

    /// <summary>PUT /api/v1/user/profile — Update user profile.</summary>
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserProfileDto dto)
    {
        var userId = User.GetUserId();
        await _profileService.UpdateProfileAsync(userId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Profile updated successfully"));
    }

    /// <summary>POST /api/v1/user/profile/photo — Upload profile photo.</summary>
    [HttpPost("profile/photo")]
    public async Task<IActionResult> UploadPhoto(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return this.ValidationProblemResponse("File is required.", nameof(file));

        if (file.Length > 5 * 1024 * 1024) // 5MB limit
            return this.ValidationProblemResponse("File size must be under 5MB.", nameof(file));

        var allowedMimeTypes = new[] { "image/jpeg", "image/png", "image/webp" };
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

        if (!allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()) || !allowedExtensions.Contains(extension))
            return this.ValidationProblemResponse("Invalid file type. Only JPG, PNG, and WEBP images are allowed.", nameof(file));

        var userId = User.GetUserId();
        using var stream = file.OpenReadStream();
        var url = await _profileService.UploadPhotoAsync(userId, stream, file.ContentType);
        return Ok(ApiResponse<object>.Ok(new { photoUrl = url }));
    }

    /// <summary>POST /api/v1/user/fcm-token — Update FCM device token.</summary>
    [HttpPost("fcm-token")]
    public async Task<IActionResult> UpdateFcmToken([FromBody] UpdateFcmTokenDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Token))
            return this.ValidationProblemResponse("Token is required.", nameof(dto.Token));

        var userId = User.GetUserId();
        await _profileService.UpdateFcmTokenAsync(userId, dto.Token);
        return Ok(ApiResponse<object?>.Ok(null, "FCM token updated"));
    }
}
