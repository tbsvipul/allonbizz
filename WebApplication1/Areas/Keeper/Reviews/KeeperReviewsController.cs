using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Keepers;
using routent.AdminAPI.DTOs.Users;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Helpers;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/keeper")]
[Authorize]
public class KeeperReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly IKeeperContextService _keeperContextService;

    public KeeperReviewsController(
        IReviewService reviewService,
        IKeeperContextService keeperContextService)
    {
        _reviewService = reviewService;
        _keeperContextService = keeperContextService;
    }

    /// <summary>GET /api/v1/keeper/reviews — Get reviews for my shops/offers.</summary>
    [HttpGet("reviews")]
    public async Task<IActionResult> GetMyReviews([FromQuery] Guid? shopId, [FromQuery] PaginationParams paging)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _reviewService.GetReviewsAsync(shopId, null, paging, keeperId: keeper.KeeperId);
        return Ok(ApiResponse<PagedResponse<ReviewDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/reviews/stats — Get average rating for my shops.</summary>
    [HttpGet("reviews/stats")]
    public async Task<IActionResult> GetMyReviewStats([FromQuery] Guid? shopId)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _reviewService.GetReviewStatsAsync(shopId, keeperId: keeper.KeeperId);
        return Ok(ApiResponse<ReviewStatsDto>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/reviews/shops-stats — Get average rating for each of my shops.</summary>
    [HttpGet("reviews/shops-stats")]
    public async Task<IActionResult> GetMyShopsReviewStats()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _reviewService.GetShopsReviewStatsAsync(keeperId: keeper.KeeperId);
        return Ok(ApiResponse<List<ShopStatsDto>>.Ok(result));
    }

    /// <summary>POST /api/v1/keeper/review/{reviewId}/reply — Reply to a review.</summary>
    [HttpPost("review/{reviewId:guid}/reply")]
    public async Task<IActionResult> ReplyToReview(Guid reviewId, [FromBody] ReviewReplyDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Reply))
            return this.ValidationProblemResponse("Reply text is required.", nameof(dto.Reply));
        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        await _reviewService.ReplyToReviewAsync(reviewId, dto, keeper.KeeperId);
        return Ok(ApiResponse<object?>.Ok(null, "Reply submitted"));
    }

}
