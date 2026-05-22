using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/keeper")]
[Authorize]
public class KeeperReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly ILoyaltyService _loyaltyService;
    private readonly IKeeperContextService _keeperContextService;

    public KeeperReviewsController(
        IReviewService reviewService,
        ILoyaltyService loyaltyService,
        IKeeperContextService keeperContextService)
    {
        _reviewService = reviewService;
        _loyaltyService = loyaltyService;
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

    /// <summary>GET /api/v1/keeper/loyalty — Loyalty program management.</summary>
    [HttpGet("loyalty")]
    public async Task<IActionResult> GetLoyaltyProgram([FromQuery] Guid? shopId)
    {
        if (shopId == null || shopId == Guid.Empty)
            return this.ValidationProblemResponse("shopId is required.", nameof(shopId));
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _loyaltyService.GetLoyaltyProgramAsync(keeper.KeeperId, shopId.Value);
        return Ok(ApiResponse<LoyaltyProgramDto>.Ok(result));
    }

    [HttpPut("loyalty")]
    public async Task<IActionResult> UpdateLoyaltyProgram([FromBody] UpdateLoyaltyProgramDto dto)
    {
        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _loyaltyService.ManageLoyaltyProgramAsync(keeper.KeeperId, dto);
        return Ok(ApiResponse<LoyaltyProgramDto>.Ok(result, "Loyalty program updated"));
    }
}
