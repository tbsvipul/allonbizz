using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserHomeController : ControllerBase
{
    private readonly IUserProfileService _profileService;

    public UserHomeController(IUserProfileService profileService) => _profileService = profileService;

    /// <summary>GET /api/v1/user/home — Home screen data (nearby + recommendations).</summary>
    [HttpGet("home")]
    public async Task<IActionResult> GetHome([FromQuery] double? lat, [FromQuery] double? lng)
        => Ok(ApiResponse<UserHomeDto>.Ok(await _profileService.GetHomeDataAsync(lat, lng)));

    /// <summary>GET /api/v1/user/nearby — Shops, restaurants, tourist places near me.</summary>
    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearby([FromQuery] double? lat, [FromQuery] double? lng)
    {
        if (lat == null || lng == null)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Latitude and longitude are required."));
        return Ok(ApiResponse<UserHomeDto>.Ok(await _profileService.GetHomeDataAsync(lat, lng)));
    }

    /// <summary>GET /api/v1/user/recommended — AI recommendations.</summary>
    [HttpGet("recommended")]
    public async Task<IActionResult> GetRecommended([FromQuery] double? lat, [FromQuery] double? lng)
        => Ok(ApiResponse<UserHomeDto>.Ok(await _profileService.GetHomeDataAsync(lat, lng)));
}
