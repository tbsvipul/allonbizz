using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/offers")]
[Authorize]
public class AdminOffersController : ControllerBase
{
    private readonly IAdminOfferService _offerService;
    public AdminOffersController(IAdminOfferService offerService) => _offerService = offerService;

    [HttpGet]
    [RequirePermission(Permissions.OffersView)]
    public async Task<IActionResult> GetAllOffers([FromQuery] AdminOfferListQueryDto query)
    {
        var result = await _offerService.GetOffersAsync(query);
        return Ok(ApiResponse<PagedResponse<AdminOfferListItemDto>>.Ok(result));
    }

    [HttpPut("{offerId:guid}/status")]
    [RequirePermission(Permissions.OffersEdit)]
    public async Task<IActionResult> UpdateStatus(Guid offerId, [FromBody] UpdateOfferStatusDto dto)
    {
        await _offerService.UpdateStatusAsync(offerId, dto);
        return NoContent();
    }

    [HttpDelete("{offerId:guid}")]
    [RequirePermission(Permissions.OffersDelete)]
    public async Task<IActionResult> DeleteOffer(Guid offerId)
    {
        await _offerService.DeleteAsync(offerId);
        return NoContent();
    }
}
