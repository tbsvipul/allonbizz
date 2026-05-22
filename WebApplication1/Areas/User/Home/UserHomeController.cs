using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserHomeController : ControllerBase
{
    private readonly IUserProfileService _profileService;

    public UserHomeController(IUserProfileService profileService) => _profileService = profileService;

    [HttpGet("home")]
    public async Task<IActionResult> GetHome([FromQuery] double? lat, [FromQuery] double? lng)
        => Ok(ApiResponse<UserHomeDto>.Ok(await _profileService.GetHomeDataAsync(User.GetUserId(), lat, lng)));

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearby([FromQuery] double? lat, [FromQuery] double? lng)
    {
        if (lat == null || lng == null)
        {
            return this.ValidationProblemResponse("Latitude and longitude are required.");
        }

        return Ok(ApiResponse<UserHomeDto>.Ok(await _profileService.GetHomeDataAsync(User.GetUserId(), lat, lng)));
    }

    [HttpGet("recommended")]
    public async Task<IActionResult> GetRecommended([FromQuery] double? lat, [FromQuery] double? lng)
        => Ok(ApiResponse<UserHomeDto>.Ok(await _profileService.GetHomeDataAsync(User.GetUserId(), lat, lng)));
}
