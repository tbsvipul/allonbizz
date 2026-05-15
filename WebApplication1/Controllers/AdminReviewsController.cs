using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.Admin;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/reviews")]
[Authorize]
public class AdminReviewsController : ControllerBase
{
    private readonly IAdminReviewService _reviewService;
    public AdminReviewsController(IAdminReviewService reviewService) => _reviewService = reviewService;

    [HttpGet]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetAllReviews([FromQuery] AdminReviewListQueryDto query)
    {
        var result = await _reviewService.GetReviewsAsync(query);
        return Ok(ApiResponse<PagedResponse<AdminReviewSummaryDto>>.Ok(result));
    }

    [HttpPut("{reviewId:guid}/status")]
    [RequirePermission(Permissions.ModerationEdit)]
    public async Task<IActionResult> UpdateStatus(Guid reviewId, [FromBody] UpdateReviewStatusDto dto)
    {
        await _reviewService.UpdateStatusAsync(reviewId, dto);
        return NoContent();
    }
}
