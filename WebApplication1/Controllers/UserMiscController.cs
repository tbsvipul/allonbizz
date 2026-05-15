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
public class UserMiscController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly IReviewService _reviewService;
    private readonly IChatService _chatService;

    public UserMiscController(INotificationService notificationService, IReviewService reviewService, IChatService chatService)
    {
        _notificationService = notificationService;
        _reviewService = reviewService;
        _chatService = chatService;
    }

    /// <summary>POST /api/v1/user/chat/{keeperId} — Start chat with keeper.</summary>
    [HttpPost("chat/{keeperId:guid}")]
    public async Task<IActionResult> StartChat(Guid keeperId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.StartChatAsync(userId, keeperId);
        return Ok(ApiResponse<ChatThreadDto>.Ok(result, "Chat thread ready"));
    }

    /// <summary>GET /api/v1/user/notifications — Get notifications.</summary>
    [HttpGet("notifications")]
    public async Task<IActionResult> GetNotifications()
    {
        var result = await _notificationService.GetNotificationsAsync(new PaginationParams { PageNumber = 1, PageSize = 50 });
        return Ok(ApiResponse<object>.Ok(result));
    }

    /// <summary>POST /api/v1/user/review — Submit review.</summary>
    [HttpPost("review")]
    public async Task<IActionResult> SubmitReview([FromBody] SubmitReviewDto dto)
    {
        if (dto.Rating < 1 || dto.Rating > 5)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Rating must be between 1 and 5."));
        if (!dto.ShopId.HasValue && !dto.OfferId.HasValue)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Either ShopId or OfferId is required."));
        var userId = User.GetUserId();
        await _reviewService.SubmitReviewAsync(userId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Review submitted successfully"));
    }
}
