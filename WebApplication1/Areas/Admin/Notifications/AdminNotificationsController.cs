using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/notifications")]
[Authorize]
public class AdminNotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public AdminNotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    [RequirePermission(Permissions.NotificationsView)]
    public async Task<IActionResult> GetNotifications([FromQuery] PaginationParams paging, [FromQuery] string? status)
    {
        var result = await _notificationService.GetNotificationsAsync(paging, status);
        return Ok(ApiResponse<PagedResponse<NotificationSummaryDto>>.Ok(result));
    }

    [HttpGet("stats")]
    [RequirePermission(Permissions.NotificationsView)]
    public async Task<IActionResult> GetStats()
    {
        var result = await _notificationService.GetNotificationStatsAsync();
        return Ok(ApiResponse<NotificationStatsDto>.Ok(result));
    }

    [HttpGet("{id}")]
    [RequirePermission(Permissions.NotificationsView)]
    public async Task<IActionResult> GetNotification(Guid id)
    {
        var result = await _notificationService.GetNotificationByIdAsync(id);
        return Ok(ApiResponse<NotificationDetailDto>.Ok(result));
    }

    [HttpPost]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> CreateNotification([FromBody] CreateNotificationDto dto)
    {
        var result = await _notificationService.CreateNotificationAsync(dto, User.GetUserId());
        var message = result.Status.Equals(NotificationStatus.Draft.ToString(), StringComparison.OrdinalIgnoreCase)
            ? "Notification saved as draft"
            : "Notification queued for delivery";
        return Ok(ApiResponse<NotificationDetailDto>.Ok(result, message));
    }

    [HttpPut("{id}")]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> UpdateNotification(Guid id, [FromBody] UpdateNotificationDto dto)
    {
        await _notificationService.UpdateNotificationAsync(id, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Notification updated successfully"));
    }

    [HttpDelete("{id}")]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> DeleteNotification(Guid id)
    {
        await _notificationService.DeleteNotificationAsync(id);
        return Ok(ApiResponse<object?>.Ok(null, "Notification deleted successfully"));
    }

    [HttpPost("{id}/send")]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> SendNotification(Guid id)
    {
        await _notificationService.SendNotificationAsync(id, User.GetUserId());
        return Ok(ApiResponse<object?>.Ok(null, "Notification queued for delivery"));
    }
}

