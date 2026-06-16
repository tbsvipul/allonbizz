using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Filters;
using routent.AdminAPI.Constants;
using routent.AdminAPI.DTOs.Admin;
using routent.AdminAPI.DTOs.Users;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/reviews")]
[Authorize]
public class AdminReviewsController : ControllerBase
{
    private readonly IAdminReviewService _reviewService;
    private readonly IReviewService _platformReviewService;
    public AdminReviewsController(IAdminReviewService reviewService, IReviewService platformReviewService)
    {
        _reviewService = reviewService;
        _platformReviewService = platformReviewService;
    }

    [HttpGet]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetAllReviews([FromQuery] AdminReviewListQueryDto query)
    {
        var result = await _reviewService.GetReviewsAsync(query);
        return Ok(ApiResponse<PagedResponse<AdminReviewSummaryDto>>.Ok(result));
    }

    [HttpGet("stats")]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetReviewStats([FromQuery] Guid? shopId)
    {
        var result = await _platformReviewService.GetReviewStatsAsync(shopId);
        return Ok(ApiResponse<ReviewStatsDto>.Ok(result));
    }

    [HttpGet("shops-stats")]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetShopsReviewStats()
    {
        var result = await _platformReviewService.GetShopsReviewStatsAsync();
        return Ok(ApiResponse<List<ShopStatsDto>>.Ok(result));
    }

    [HttpPut("{reviewId:guid}/status")]
    [RequirePermission(Permissions.ModerationEdit)]
    public async Task<IActionResult> UpdateStatus(Guid reviewId, [FromBody] UpdateReviewStatusDto dto)
    {
        await _reviewService.UpdateStatusAsync(reviewId, dto);
        return NoContent();
    }
}
