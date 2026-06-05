using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Filters;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserHistoryController : ControllerBase
{
    private readonly IUserHistoryService _historyService;
    private readonly IRouteService _routeService;
    public UserHistoryController(
        IUserHistoryService historyService, 
        IRouteService routeService)
    {
        _historyService = historyService;
        _routeService = routeService;
    }


    /// <summary>GET /api/v1/user/history/routes — Route history.</summary>
    [HttpGet("history/routes")]
    public async Task<IActionResult> GetRouteHistory()
    {
        var userId = User.GetUserId();
        var result = await _routeService.GetRouteHistoryAsync(userId);
        return Ok(ApiResponse<List<RouteResponseDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/user/history/redemptions — Redeemed offers history.</summary>
    [HttpGet("history/redemptions")]
    public async Task<IActionResult> GetRedemptionHistory()
    {
        var userId = User.GetUserId();
        var result = await _historyService.GetRedemptionHistoryAsync(userId);
        return Ok(ApiResponse<List<RedemptionHistoryDto>>.Ok(result));
    }



    /// <summary>GET /api/v1/user/savings — Total savings summary.</summary>
    [HttpGet("savings")]
    public async Task<IActionResult> GetSavings()
    {
        var userId = User.GetUserId();
        var result = await _historyService.GetSavingsSummaryAsync(userId);
        return Ok(ApiResponse<UserSavingsSummaryDto>.Ok(result));
    }
}
