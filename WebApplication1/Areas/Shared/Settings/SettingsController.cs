using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Admin;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Filters;
using routent.AdminAPI.Constants;
using routent.AdminAPI.DTOs.Settings;
using routent.AdminAPI.DTOs.System;
using routent.AdminAPI.Helpers;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/settings")]
[Authorize]
public class SettingsController : ControllerBase
{
    private readonly ISettingsService _settingsService;
    public SettingsController(ISettingsService settingsService) => _settingsService = settingsService;

    [HttpGet("")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetSettings() =>
        Ok(ApiResponse<SystemConfigDto>.Ok(await _settingsService.GetSettingsAsync(HttpContext.RequestAborted)));

    [HttpPut("")]
    [RequirePermission(Permissions.SettingsEdit)]
    public async Task<IActionResult> UpdateSettings([FromBody] UpdateSettingsDto dto)
    {
        await _settingsService.UpdateSettingsAsync(dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("security")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetSecurity() =>
        Ok(ApiResponse<SecuritySettingsDto>.Ok(await _settingsService.GetSecuritySettingsAsync(HttpContext.RequestAborted)));

    [HttpPut("security")]
    [RequirePermission(Permissions.SettingsEdit)]
    public async Task<IActionResult> UpdateSecurity([FromBody] UpdateSecurityDto dto)
    {
        await _settingsService.UpdateSecuritySettingsAsync(dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("admins")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> GetAdmins([FromQuery] AdminListQueryDto query) =>
        Ok(ApiResponse<PagedResponse<AdminListItemDto>>.Ok(await _settingsService.GetAdminsAsync(query, HttpContext.RequestAborted)));

    [HttpPost("admins")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> CreateAdmin([FromBody] CreateAdminRequestDto dto)
    {
        var result = await _settingsService.CreateAdminAsync(dto, User.GetUserId(), HttpContext.RequestAborted);
        return CreatedAtAction(nameof(GetAdmin), new { adminId = result.AdminId }, ApiResponse<AdminDetailDto>.Ok(result));
    }

    [HttpGet("admins/{adminId:guid}")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> GetAdmin(Guid adminId) =>
        Ok(ApiResponse<AdminDetailDto>.Ok(await _settingsService.GetAdminAsync(adminId, HttpContext.RequestAborted)));

    [HttpPut("admins/{adminId:guid}")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> UpdateAdmin(Guid adminId, [FromBody] UpdateAdminRequestDto dto)
    {
        await _settingsService.UpdateAdminAsync(adminId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpDelete("admins/{adminId:guid}")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> DeleteAdmin(Guid adminId)
    {
        await _settingsService.DeleteAdminAsync(adminId, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("admins/{adminId:guid}/reset-password")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> ResetAdminPassword(Guid adminId)
    {
        await _settingsService.ResetAdminPasswordAsync(adminId, User.GetUserId(), HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "Password reset email sent"));
    }

    [HttpPost("admins/{adminId:guid}/sessions/terminate")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> TerminateAdminSessions(Guid adminId)
    {
        await _settingsService.TerminateAdminSessionsAsync(adminId, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }
}
