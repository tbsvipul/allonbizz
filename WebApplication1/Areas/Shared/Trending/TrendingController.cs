using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Data;
using Microsoft.EntityFrameworkCore;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/trending")]
[Authorize]
public class TrendingController : ControllerBase
{
    private readonly AppDbContext _db;
    public TrendingController(AppDbContext db) => _db = db;

    [HttpGet("offers")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetTrendingOffers()
    {
        var offers = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .OrderByDescending(o => o.CurrentRedemptions)
            .Take(10)
            .Select(o => new {
                o.OfferId,
                o.Title,
                o.CurrentRedemptions,
                shopName = o.Shop != null ? o.Shop.Name : "Unknown"
            })
            .ToListAsync();
        return Ok(ApiResponse<object>.Ok(offers));
    }

    [HttpGet("shops")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetTrendingShops()
    {
        // Trending shops based on average rating and review count
        var shops = await _db.Shops
            .AsNoTracking()
            .Include(s => s.Reviews)
            .Select(s => new {
                s.ShopId,
                s.Name,
                ReviewCount = s.Reviews.Count(),
                AvgRating = s.Reviews.Any() ? s.Reviews.Average(r => (int)r.Rating) : 0
            })
            .OrderByDescending(s => s.AvgRating)
            .ThenByDescending(s => s.ReviewCount)
            .Take(10)
            .ToListAsync();
        return Ok(ApiResponse<object>.Ok(shops));
    }

    [HttpGet("journeys")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetTrendingJourneys()
    {
        var journeys = await _db.Journeys
            .AsNoTracking()
            .Select(j => new {
                j.JourneyId,
                Name = j.StartName,
                j.LikesCount,
                j.ViewsCount,
                Score = j.LikesCount * 2 + j.ViewsCount
            })
            .OrderByDescending(j => j.Score)
            .Take(10)
            .ToListAsync();
        return Ok(ApiResponse<object>.Ok(journeys));
    }
}
