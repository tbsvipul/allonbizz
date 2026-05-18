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
public class KeeperOffersController : ControllerBase
{
    private readonly IKeeperOfferService _offerService;
    private readonly IKeeperContextService _keeperContextService;

    public KeeperOffersController(IKeeperOfferService offerService, IKeeperContextService keeperContextService)
    {
        _offerService = offerService;
        _keeperContextService = keeperContextService;
    }

    /// <summary>GET /api/v1/keeper/offers — List all offers.</summary>
    [HttpGet("offers")]
    public async Task<IActionResult> GetMyOffers()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _offerService.GetMyOffersAsync(keeper.KeeperId);
        return Ok(ApiResponse<List<KeeperOfferDetailDto>>.Ok(result));
    }

    /// <summary>POST /api/v1/keeper/offer — Create new offer.</summary>
    [HttpPost("offer")]
    public async Task<IActionResult> CreateOffer([FromBody] CreateOfferDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title))
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Offer title is required."));
        if (dto.ShopId == Guid.Empty)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Create a shop first and then select it before creating an offer."));
        if (dto.EndDate <= dto.StartDate)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "End date must be after start date."));

        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var offerId = await _offerService.CreateOfferAsync(keeper.KeeperId, dto);
        return Created($"/api/v1/keeper/offer/{offerId}", ApiResponse<object>.Ok(new { offerId }, "Offer created"));
    }

    /// <summary>GET /api/v1/keeper/offer/{offerId} — Get offer details.</summary>
    [HttpGet("offer/{offerId:guid}")]
    public async Task<IActionResult> GetOffer(Guid offerId)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var offer = await _offerService.GetOfferDetailAsync(keeper.KeeperId, offerId);
        if (offer == null)
            return NotFound(ApiResponse<object>.Fail("NOT_FOUND", $"Offer {offerId} not found."));
        return Ok(ApiResponse<KeeperOfferDetailDto>.Ok(offer));
    }

    /// <summary>PUT /api/v1/keeper/offer/{offerId} — Update offer.</summary>
    [HttpPut("offer/{offerId:guid}")]
    public async Task<IActionResult> UpdateOffer(Guid offerId, [FromBody] CreateOfferDto dto)
    {
        if (dto.ShopId == Guid.Empty)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Select a valid shop before updating the offer."));
        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        await _offerService.UpdateOfferAsync(keeper.KeeperId, offerId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Offer updated"));
    }

    /// <summary>DELETE /api/v1/keeper/offer/{offerId} — Delete offer.</summary>
    [HttpDelete("offer/{offerId:guid}")]
    public async Task<IActionResult> DeleteOffer(Guid offerId)
    {
        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        await _offerService.DeleteOfferAsync(keeper.KeeperId, offerId);
        return Ok(ApiResponse<object?>.Ok(null, "Offer deleted"));
    }

    /// <summary>POST /api/v1/keeper/offer/bulk — Bulk upload offers (CSV).</summary>
    [HttpPost("offer/bulk")]
    public async Task<IActionResult> BulkUploadOffers(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "CSV file is required."));

        var allowedMimeTypes = new[] { "text/csv", "application/csv", "application/vnd.ms-excel" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

        if (!allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()) || extension != ".csv")
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Invalid file type. Only CSV files are allowed."));

        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        using var stream = file.OpenReadStream();
        var result = await _offerService.BulkUploadOffersAsync(keeper.KeeperId, stream);
        return Ok(ApiResponse<BulkOfferUploadResultDto>.Ok(result, "Bulk upload completed"));
    }
}
