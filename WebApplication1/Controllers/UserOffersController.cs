using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserOffersController : ControllerBase
{
    private readonly IOfferService _offerService;
    private readonly IRouteService _routeService;

    public UserOffersController(IOfferService offerService, IRouteService routeService)
    {
        _offerService = offerService;
        _routeService = routeService;
    }

    /// <summary>GET /api/v1/user/offers/nearby — Offers near current location.</summary>
    [HttpGet("offers/nearby")]
    public async Task<IActionResult> GetNearbyOffers([FromQuery] double? lat, [FromQuery] double? lng)
    {
        if (lat == null || lng == null)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Latitude and longitude are required."));
        var result = await _offerService.GetNearbyOffersAsync(lat.Value, lng.Value);
        return Ok(ApiResponse<List<OfferSummaryDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/user/offers/route — Offers on current route.</summary>
    [HttpGet("offers/route")]
    public async Task<IActionResult> GetRouteOffers([FromQuery] Guid? routeId)
    {
        if (routeId == null || routeId == Guid.Empty)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Valid routeId is required."));
        var result = await _routeService.GetOffersAlongRouteAsync(routeId.Value);
        return Ok(ApiResponse<List<OfferSummaryDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/user/offer/{offerId} — Get full offer details.</summary>
    [HttpGet("offer/{offerId:guid}")]
    public async Task<IActionResult> GetOfferDetail(Guid offerId)
    {
        var userId = User.GetUserId();
        var result = await _offerService.GetOfferDetailAsync(offerId, userId);
        return Ok(ApiResponse<OfferDetailDto>.Ok(result));
    }

    /// <summary>POST /api/v1/user/offer/{offerId}/redeem — Redeem an offer.</summary>
    [HttpPost("offer/{offerId:guid}/redeem")]
    public async Task<IActionResult> RedeemOffer(Guid offerId)
    {
        var userId = User.GetUserId();
        var redemptionId = await _offerService.RedeemOfferAsync(offerId, userId);
        return Ok(ApiResponse<object>.Ok(new { redemptionId }, "Offer redeemed successfully"));
    }

    /// <summary>POST /api/v1/user/offer/{offerId}/save — Save offer for later.</summary>
    [HttpPost("offer/{offerId:guid}/save")]
    public async Task<IActionResult> SaveOffer(Guid offerId)
    {
        var userId = User.GetUserId();
        await _offerService.SaveOfferAsync(offerId, userId);
        return Ok(ApiResponse<object?>.Ok(null, "Offer saved"));
    }

    /// <summary>POST /api/v1/user/offer/{offerId}/rate — Rate an offer after redemption.</summary>
    [HttpPost("offer/{offerId:guid}/rate")]
    public async Task<IActionResult> RateOffer(Guid offerId, [FromBody] RateOfferRequestDto dto)
    {
        if (dto.Rating < 1 || dto.Rating > 5)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Rating must be between 1 and 5."));
        var userId = User.GetUserId();
        await _offerService.RateOfferAsync(offerId, userId, dto.Rating, dto.Comment);
        return Ok(ApiResponse<object?>.Ok(null, "Offer rated successfully"));
    }
}
