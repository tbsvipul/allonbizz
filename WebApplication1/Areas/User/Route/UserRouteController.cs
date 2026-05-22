using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user/route")]
[Authorize]
public class UserRouteController : ControllerBase
{
    private readonly IRouteService _routeService;

    public UserRouteController(IRouteService routeService) => _routeService = routeService;

    /// <summary>POST /api/v1/user/route/calculate — Calculate route (current → destination).</summary>
    [HttpPost("calculate")]
    public async Task<IActionResult> CalculateRoute([FromBody] RouteCalculateRequestDto dto)
    {
        var userId = User.GetUserId();
        var result = await _routeService.CalculateRouteAsync(userId, dto);
        return Ok(ApiResponse<RouteResponseDto>.Ok(result));
    }

    /// <summary>POST /api/v1/user/route/offers — Get all offers along the selected route.</summary>
    [HttpPost("offers")]
    public async Task<IActionResult> GetRouteOffers([FromQuery] Guid routeId)
    {
        if (routeId == Guid.Empty)
            return this.ValidationProblemResponse("Valid routeId is required.", nameof(routeId));
        var result = await _routeService.GetOffersAlongRouteAsync(routeId);
        return Ok(ApiResponse<List<OfferSummaryDto>>.Ok(result));
    }

    /// <summary>POST /api/v1/user/route/optimize — AI route optimizer (suggest detours with deals).</summary>
    [HttpPost("optimize")]
    public async Task<IActionResult> OptimizeRoute([FromQuery] Guid routeId)
    {
        if (routeId == Guid.Empty)
            return this.ValidationProblemResponse("Valid routeId is required.", nameof(routeId));
        var result = await _routeService.OptimizeRouteAsync(routeId);
        return Ok(ApiResponse<RouteResponseDto>.Ok(result));
    }

    /// <summary>GET /api/v1/user/route/active — Get currently active route (if any).</summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActiveRoute()
    {
        var userId = User.GetUserId();
        var result = await _routeService.GetActiveRouteAsync(userId);
        if (result == null)
            return this.NotFoundProblemResponse("No active route found.");
        return Ok(ApiResponse<RouteResponseDto>.Ok(result));
    }

    /// <summary>GET /api/v1/user/route/history — Past routes history.</summary>
    [HttpGet("history")]
    public async Task<IActionResult> GetRouteHistory()
    {
        var userId = User.GetUserId();
        var result = await _routeService.GetRouteHistoryAsync(userId);
        return Ok(ApiResponse<List<RouteResponseDto>>.Ok(result));
    }
}
