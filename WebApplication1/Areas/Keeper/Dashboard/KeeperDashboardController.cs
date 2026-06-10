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
    private readonly IKeeperContextService _keeperContextService;

    public KeeperDashboardController(IKeeperDashboardService dashboardService, IKeeperContextService keeperContextService)
    {
        _dashboardService = dashboardService;
        _keeperContextService = keeperContextService;
    }

    /// <summary>GET /api/v1/keeper/dashboard — Keeper home dashboard (traffic overview).</summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _dashboardService.GetDashboardAsync(keeper.KeeperId);
        return Ok(ApiResponse<KeeperDashboardDto>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/traffic — Live & predicted traffic near shop.</summary>
    [HttpGet("traffic")]
    public async Task<IActionResult> GetTraffic([FromQuery] Guid? shopId)
    {
        if (shopId == null || shopId == Guid.Empty)
            return this.ValidationProblemResponse("shopId is required.", nameof(shopId));
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _dashboardService.GetTrafficAnalyticsAsync(keeper.KeeperId, shopId.Value);
        return Ok(ApiResponse<KeeperTrafficDto>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/analytics — Shop analytics & reports.</summary>
    [HttpGet("analytics")]
    public async Task<IActionResult> GetAnalytics()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _dashboardService.GetAnalyticsAsync(keeper.KeeperId);
        return Ok(ApiResponse<KeeperAnalyticsDto>.Ok(result));
    }
}
