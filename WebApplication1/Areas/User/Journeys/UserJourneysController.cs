using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user/journeys")]
[Authorize]
public class UserJourneysController : ControllerBase
{
    private readonly IJourneyService _journeyService;

    public UserJourneysController(IJourneyService journeyService) => _journeyService = journeyService;

    [HttpPost("start")]
    public async Task<IActionResult> StartJourney([FromBody] StartJourneyDto dto)
    {
        var userId = User.GetUserId();
        var journeyId = await _journeyService.StartJourneyAsync(userId, dto);
        return Ok(ApiResponse<object>.Ok(new { journeyId }, "Journey started successfully"));
    }

    [HttpGet]
    public async Task<IActionResult> GetJourneys()
    {
        var userId = User.GetUserId();
        var journeys = await _journeyService.GetUserJourneysAsync(userId);
        return Ok(ApiResponse<List<JourneyHistoryDto>>.Ok(journeys));
    }

    [HttpGet("{journeyId:guid}")]
    public async Task<IActionResult> GetJourneyDetail(Guid journeyId)
    {
        var result = await _journeyService.GetJourneyDetailAsync(journeyId, User.GetUserId());
        if (result == null)
        {
            return NotFound(ApiResponse<object?>.Fail("NOT_FOUND", "Journey not found"));
        }

        return Ok(ApiResponse<JourneyDetailDto>.Ok(result));
    }

    [HttpGet("{journeyId:guid}/near")]
    public async Task<IActionResult> GetNearbyShops(Guid journeyId, [FromQuery] double lat, [FromQuery] double lng, [FromQuery] double radius = 5)
    {
        var recommendations = await _journeyService.GetNearByShopsAsync(journeyId, lat, lng, radius);
        return Ok(ApiResponse<List<JourneyRecommendationResponse>>.Ok(recommendations));
    }

    [HttpPost("{journeyId:guid}/progress")]
    public async Task<IActionResult> UpdateProgress(Guid journeyId, [FromBody] UpdateJourneyProgressDto dto)
    {
        var success = await _journeyService.UpdateJourneyProgressAsync(journeyId, dto);
        if (!success)
        {
            return NotFound(ApiResponse<object?>.Fail("NOT_FOUND", "Journey not found or inactive"));
        }

        return Ok(ApiResponse<object?>.Ok(null, "Progress updated"));
    }

    [HttpPost("{journeyId:guid}/end")]
    public async Task<IActionResult> EndJourney(Guid journeyId, [FromBody] EndJourneyDto dto)
    {
        var success = await _journeyService.EndJourneyAsync(journeyId, dto);
        if (!success)
        {
            return NotFound(ApiResponse<object?>.Fail("NOT_FOUND", "Journey not found"));
        }

        return Ok(ApiResponse<object?>.Ok(null, "Journey completed successfully"));
    }
}
