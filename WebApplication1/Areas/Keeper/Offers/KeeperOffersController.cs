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
            return this.ValidationProblemResponse("Offer title is required.", nameof(dto.Title));
        if (dto.ShopId == Guid.Empty)
            return this.ValidationProblemResponse("Create a shop first and then select it before creating an offer.", nameof(dto.ShopId));
        if (dto.EndDate <= dto.StartDate)
            return this.ValidationProblemResponse("End date must be after start date.", nameof(dto.EndDate));

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
            return this.NotFoundProblemResponse($"Offer {offerId} not found.");
        return Ok(ApiResponse<KeeperOfferDetailDto>.Ok(offer));
    }

    /// <summary>PUT /api/v1/keeper/offer/{offerId} — Update offer.</summary>
    [HttpPut("offer/{offerId:guid}")]
    public async Task<IActionResult> UpdateOffer(Guid offerId, [FromBody] CreateOfferDto dto)
    {
        if (dto.ShopId == Guid.Empty)
            return this.ValidationProblemResponse("Select a valid shop before updating the offer.", nameof(dto.ShopId));
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
            return this.ValidationProblemResponse("CSV file is required.", nameof(file));

        var allowedMimeTypes = new[] { "text/csv", "application/csv", "application/vnd.ms-excel" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

        if (!allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()) || extension != ".csv")
            return this.ValidationProblemResponse("Invalid file type. Only CSV files are allowed.", nameof(file));

        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        using var stream = file.OpenReadStream();
        var result = await _offerService.BulkUploadOffersAsync(keeper.KeeperId, stream);
        return Ok(ApiResponse<BulkOfferUploadResultDto>.Ok(result, "Bulk upload completed"));
    }
}
