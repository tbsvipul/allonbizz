using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Security.Claims;

namespace allonbiz.AdminAPI.Areas.User.Controllers;

[ApiController]
[Route("api/v1/user/notifications")]
[Authorize]
public class UserNotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public UserNotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    private Guid GetUserId()
    {
        return Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications([FromQuery] PaginationParams paging)
    {
        var userId = GetUserId();
        var result = await _notificationService.GetUserNotificationsAsync(userId, "customer", paging);
        return Ok(ApiResponse<PagedResponse<UserNotificationDto>>.Ok(result));
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = GetUserId();
        await _notificationService.MarkUserNotificationReadAsync(userId, id);
        return Ok(ApiResponse<object>.Ok(null, "Notification marked as read"));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(Guid id)
    {
        var userId = GetUserId();
        await _notificationService.DeleteUserNotificationAsync(userId, id);
        return Ok(ApiResponse<object>.Ok(null, "Notification deleted"));
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var userId = GetUserId();
        var count = await _notificationService.GetUnreadNotificationCountAsync(userId, "customer");
        return Ok(ApiResponse<int>.Ok(count));
    }
    [HttpGet("test-roles")]
    public async Task<IActionResult> TestRoles()
    {
        var count = await _notificationService.GetUnreadNotificationCountAsync(Guid.Empty, "keeper"); // just to compile, will return 0
        // We actually want to check how many keepers are there. We can just inject the DB context, but we don't have it here.
        // Let's modify the service instead.
        return Ok(ApiResponse<int>.Ok(count));
    }
}
