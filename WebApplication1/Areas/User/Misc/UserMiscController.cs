using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

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

    [HttpPost("chat/{keeperId:guid}")]
    public async Task<IActionResult> StartChat(Guid keeperId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.StartChatAsync(userId, keeperId);
        return Ok(ApiResponse<ChatThreadDto>.Ok(result, "Chat thread ready"));
    }

    [HttpGet("notifications")]
    public async Task<IActionResult> GetNotifications([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 50)
    {
        var userId = User.GetUserId();
        var role = User.FindFirst("role")?.Value ?? User.FindFirst(ClaimTypes.Role)?.Value ?? "customer";
        var paging = new PaginationParams { PageNumber = pageNumber, PageSize = Math.Clamp(pageSize, 1, 100) };
        var result = await _notificationService.GetUserNotificationsAsync(userId, role, paging);
        return Ok(ApiResponse<PagedResponse<UserNotificationDto>>.Ok(result));
    }

    [HttpPost("notifications/{notificationId:guid}/read")]
    public async Task<IActionResult> MarkNotificationRead(Guid notificationId)
    {
        await _notificationService.MarkUserNotificationReadAsync(User.GetUserId(), notificationId);
        return Ok(ApiResponse<object?>.Ok(null, "Notification marked as read"));
    }

    [HttpPost("review")]
    public async Task<IActionResult> SubmitReview([FromBody] SubmitReviewDto dto)
    {
        if (dto.Rating < 1 || dto.Rating > 5)
        {
            return this.ValidationProblemResponse("Rating must be between 1 and 5.", nameof(dto.Rating));
        }

        if (!dto.ShopId.HasValue && !dto.OfferId.HasValue)
        {
            return this.ValidationProblemResponse("Either ShopId or OfferId is required.");
        }

        var userId = User.GetUserId();
        await _reviewService.SubmitReviewAsync(userId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Review submitted successfully"));
    }
}
