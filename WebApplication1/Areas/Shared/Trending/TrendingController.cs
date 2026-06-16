using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Analytics;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Filters;
using routent.AdminAPI.Constants;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/trending")]
[Authorize]
public class TrendingController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;
    public TrendingController(IAnalyticsService analyticsService) => _analyticsService = analyticsService;

    [HttpGet("offers")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetTrendingOffers()
    {
        var offers = await _analyticsService.GetTrendingOffersAsync(HttpContext.RequestAborted);
        return Ok(ApiResponse<List<TrendingAdminOfferDto>>.Ok(offers));
    }

    [HttpGet("shops")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetTrendingShops()
    {
        var shops = await _analyticsService.GetTrendingShopsAsync(HttpContext.RequestAborted);
        return Ok(ApiResponse<List<TrendingAdminShopDto>>.Ok(shops));
    }

    [HttpGet("journeys")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetTrendingJourneys()
    {
        var journeys = await _analyticsService.GetTrendingJourneysAsync(HttpContext.RequestAborted);
        return Ok(ApiResponse<List<TrendingAdminJourneyDto>>.Ok(journeys));
    }
}
