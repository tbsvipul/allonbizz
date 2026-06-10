using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

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

    [HttpGet("offers/nearby")]
    public async Task<IActionResult> GetNearbyOffers(
        [FromQuery] double? lat,
        [FromQuery] double? lng,
        [FromQuery] double? radiusKm,
        [FromQuery] string? category,
        [FromQuery] List<string>? tags)
    {
        var result = await _offerService.GetNearbyOffersAsync(lat, lng, radiusKm, category, tags);
        return Ok(ApiResponse<List<OfferSummaryDto>>.Ok(result));
    }

    [HttpGet("offers/route")]
    public async Task<IActionResult> GetRouteOffers([FromQuery] Guid? routeId)
    {
        if (routeId == null || routeId == Guid.Empty)
        {
            return this.ValidationProblemResponse("Valid routeId is required.", nameof(routeId));
        }

        var result = await _routeService.GetOffersAlongRouteAsync(routeId.Value);
        return Ok(ApiResponse<List<OfferSummaryDto>>.Ok(result));
    }

    [HttpGet("offer/{offerId:guid}")]
    public async Task<IActionResult> GetOfferDetail(Guid offerId)
    {
        var userId = User.GetUserId();
        var result = await _offerService.GetOfferDetailAsync(offerId, userId);
        return Ok(ApiResponse<OfferDetailDto>.Ok(result));
    }


    [HttpPost("offer/{offerId:guid}/save")]
    public async Task<IActionResult> SaveOffer(Guid offerId)
    {
        var userId = User.GetUserId();
        await _offerService.SaveOfferAsync(offerId, userId);
        return Ok(ApiResponse<object?>.Ok(null, "Offer saved"));
    }

    [HttpPost("offer/{offerId:guid}/rate")]
    public async Task<IActionResult> RateOffer(Guid offerId, [FromBody] RateOfferRequestDto dto)
    {
        if (dto.Rating < 1 || dto.Rating > 5)
        {
            return this.ValidationProblemResponse("Rating must be between 1 and 5.", nameof(dto.Rating));
        }

        var userId = User.GetUserId();
        await _offerService.RateOfferAsync(offerId, userId, dto.Rating, dto.Comment);
        return Ok(ApiResponse<object?>.Ok(null, "Offer rated successfully"));
    }
}
