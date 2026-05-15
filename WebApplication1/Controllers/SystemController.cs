using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.System;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/system")]
[Authorize]
public class SystemController : ControllerBase
{
    private readonly ISystemService _systemService;
    public SystemController(ISystemService systemService) => _systemService = systemService;

    [HttpGet("/api/v1/config")]
    [AllowAnonymous]
    public async Task<IActionResult> GetConfig()
        => Ok(ApiResponse<allonbiz.AdminAPI.DTOs.System.SystemConfigDto>.Ok(await _systemService.GetConfigAsync()));

    [HttpGet("health")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetHealth()
        => Ok(ApiResponse<SystemHealthDto>.Ok(await _systemService.GetHealthAsync()));

    [HttpGet("errors")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetErrors([FromQuery] PaginationParams paging)
        => Ok(await _systemService.GetErrorLogsAsync(paging));

    [HttpPut("errors/{logId:guid}/resolve")]
    [RequirePermission(Permissions.SystemEdit)]
    public async Task<IActionResult> ResolveError(Guid logId, [FromBody] ResolveErrorDto dto)
    {
        await _systemService.ResolveErrorAsync(logId, dto);
        return NoContent();
    }

    [HttpGet("api-performance")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetApiPerformance([FromQuery] ApiPerformanceQueryDto query)
        => Ok(ApiResponse<ApiPerformanceDto>.Ok(await _systemService.GetApiPerformanceAsync(query)));

    [HttpGet("alerts")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetAlerts()
        => Ok(ApiResponse<SystemAlertsDto>.Ok(await _systemService.GetAlertsAsync()));

    [HttpPost("maintenance-mode")]
    [RequirePermission(Permissions.SystemEdit)]
    public async Task<IActionResult> ToggleMaintenanceMode([FromBody] ToggleMaintenanceModeDto dto)
    {
        var result = await _systemService.ToggleMaintenanceModeAsync(dto);
        return Ok(ApiResponse<MaintenanceModeStatusDto>.Ok(result, "Maintenance mode updated"));
    }

    [HttpGet("audit-logs")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetAuditLogs([FromQuery] PaginationParams paging)
        => Ok(await _systemService.GetAuditLogsAsync(paging));
}
