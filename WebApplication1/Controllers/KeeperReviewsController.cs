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

    public KeeperReviewsController(IReviewService reviewService, ILoyaltyService loyaltyService)
    {
        _reviewService = reviewService;
        _loyaltyService = loyaltyService;
    }

    /// <summary>GET /api/v1/keeper/reviews — Get reviews for my shops/offers.</summary>
    [HttpGet("reviews")]
    public async Task<IActionResult> GetMyReviews([FromQuery] Guid? shopId, [FromQuery] PaginationParams paging)
    {
        var result = await _reviewService.GetReviewsAsync(shopId, null, paging);
        return Ok(ApiResponse<PagedResponse<ReviewDto>>.Ok(result));
    }

    /// <summary>POST /api/v1/keeper/review/{reviewId}/reply — Reply to a review.</summary>
    [HttpPost("review/{reviewId:guid}/reply")]
    public async Task<IActionResult> ReplyToReview(Guid reviewId, [FromBody] ReviewReplyDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Reply))
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Reply text is required."));
        await _reviewService.ReplyToReviewAsync(reviewId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Reply submitted"));
    }

    /// <summary>GET /api/v1/keeper/loyalty — Loyalty program management.</summary>
    [HttpGet("loyalty")]
    public async Task<IActionResult> GetLoyaltyProgram([FromQuery] Guid? shopId)
    {
        if (shopId == null || shopId == Guid.Empty)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "shopId is required."));
        var result = await _loyaltyService.GetLoyaltyProgramAsync(shopId.Value);
        return Ok(ApiResponse<LoyaltyProgramDto>.Ok(result));
    }

    [HttpPut("loyalty")]
    public async Task<IActionResult> UpdateLoyaltyProgram([FromBody] UpdateLoyaltyProgramDto dto)
    {
        var result = await _loyaltyService.ManageLoyaltyProgramAsync(dto);
        return Ok(ApiResponse<LoyaltyProgramDto>.Ok(result, "Loyalty program updated"));
    }
}
