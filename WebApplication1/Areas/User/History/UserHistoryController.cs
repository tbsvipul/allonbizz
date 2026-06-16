using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Users;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Helpers;
using routent.AdminAPI.Constants;
using routent.AdminAPI.Filters;

namespace routent.AdminAPI.Controllers;

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




    /// <summary>GET /api/v1/user/savings — Total savings summary.</summary>
    [HttpGet("savings")]
    public async Task<IActionResult> GetSavings()
    {
        var userId = User.GetUserId();
        var result = await _historyService.GetSavingsSummaryAsync(userId);
        return Ok(ApiResponse<UserSavingsSummaryDto>.Ok(result));
    }
}
