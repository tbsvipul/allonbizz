using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/keeper")]
[Authorize]
public class KeeperDashboardController : ControllerBase
{
    private readonly IKeeperDashboardService _dashboardService;

    public KeeperDashboardController(IKeeperDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    /// <summary>GET /api/v1/keeper/dashboard — Keeper home dashboard (traffic overview).</summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        var keeperId = User.GetUserId();
        var result = await _dashboardService.GetDashboardAsync(keeperId);
        return Ok(ApiResponse<KeeperDashboardDto>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/traffic — Live & predicted traffic near shop.</summary>
    [HttpGet("traffic")]
    public async Task<IActionResult> GetTraffic([FromQuery] Guid? shopId)
    {
        if (shopId == null || shopId == Guid.Empty)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "shopId is required."));
        var result = await _dashboardService.GetTrafficAnalyticsAsync(shopId.Value);
        return Ok(ApiResponse<KeeperTrafficDto>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/analytics — Redemption analytics & reports.</summary>
    [HttpGet("analytics")]
    public async Task<IActionResult> GetAnalytics()
    {
        var keeperId = User.GetUserId();
        var result = await _dashboardService.GetAnalyticsAsync(keeperId);
        return Ok(ApiResponse<KeeperAnalyticsDto>.Ok(result));
    }
}
