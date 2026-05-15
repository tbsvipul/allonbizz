using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin")]
[Authorize]
public class AdminPanelController : ControllerBase
{
    private readonly IAdminPanelService _adminService;
    private readonly IRuleService _ruleService;
    private readonly INotificationService _notificationService;

    public AdminPanelController(
        IAdminPanelService adminService,
        IRuleService ruleService,
        INotificationService notificationService)
    {
        _adminService = adminService;
        _ruleService = ruleService;
        _notificationService = notificationService;
    }


    [HttpGet("dashboard")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetDashboard()
        => Ok(ApiResponse<AdminDashboardSummaryDto>.Ok(await _adminService.GetDashboardSummaryAsync()));

    [HttpPost("push")]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> SendPush([FromBody] PushNotificationRequestDto dto)
    {
        var notification = await _notificationService.CreateNotificationAsync(
            new CreateNotificationDto
            {
                Title = dto.Title,
                Message = dto.Message,
                TargetAudience = dto.TargetAudience ?? "all",
                SendImmediately = true
            },
            User.GetUserId(),
            HttpContext.RequestAborted);

        return Ok(ApiResponse<NotificationDetailDto>.Ok(notification, "Push notification queued"));
    }

    [HttpGet("rules")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetRules()
        => Ok(ApiResponse<List<PlatformRuleDto>>.Ok(await _ruleService.GetRulesAsync()));

    [HttpPost("rule")]
    [RequirePermission(Permissions.SettingsEdit)]
    public async Task<IActionResult> AddRule([FromBody] CreateRuleDto dto)
    {
        await _ruleService.AddRuleAsync(dto);
        return Ok(ApiResponse<object?>.Ok(null, "Rule added"));
    }
}
