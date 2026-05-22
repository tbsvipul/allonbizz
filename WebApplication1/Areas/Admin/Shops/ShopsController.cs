using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/shops")]
[Authorize]
public class ShopsController : ControllerBase
{
    private readonly IShopService _shopService;

    public ShopsController(IShopService shopService)
    {
        _shopService = shopService;
    }

    [HttpGet]
    [RequirePermission(Permissions.ShopsView)]
    public async Task<IActionResult> GetShops([FromQuery] ShopListQueryDto query)
    {
        var result = await _shopService.GetShopsAsync(query, HttpContext.RequestAborted);
        return Ok(ApiResponse<PagedResponse<ShopSummaryDto>>.Ok(result));
    }

    [HttpGet("{shopId:guid}")]
    [RequirePermission(Permissions.ShopsView)]
    public async Task<IActionResult> GetShop(Guid shopId)
    {
        var shop = await _shopService.GetShopAsync(shopId, HttpContext.RequestAborted);
        if (shop == null)
        {
            return this.NotFoundProblemResponse("Shop not found.");
        }

        return Ok(ApiResponse<ShopDetailDto>.Ok(shop));
    }

    [HttpPut("{shopId:guid}/status")]
    [RequirePermission(Permissions.ShopsApprove)]
    public async Task<IActionResult> UpdateStatus(Guid shopId, [FromBody] UpdateShopStatusDto dto)
    {
        try
        {
            await _shopService.UpdateShopStatusAsync(shopId, dto, HttpContext.RequestAborted);
            return Ok(ApiResponse<object?>.Ok(null, "Shop status updated successfully."));
        }
        catch (KeyNotFoundException)
        {
            return this.NotFoundProblemResponse("Shop not found.");
        }
    }

    [HttpPost("{shopId:guid}/verify")]
    [RequirePermission(Permissions.ShopsApprove)]
    public async Task<IActionResult> VerifyShop(Guid shopId, [FromBody] VerifyShopRequestDto dto)
    {
        try
        {
            await _shopService.VerifyShopAsync(shopId, dto, HttpContext.RequestAborted);
            return Ok(ApiResponse<object?>.Ok(null, "Shop verified successfully."));
        }
        catch (KeyNotFoundException)
        {
            return this.NotFoundProblemResponse("Shop not found.");
        }
    }

    [HttpPost("{shopId:guid}/unverify")]
    [RequirePermission(Permissions.ShopsApprove)]
    public async Task<IActionResult> UnverifyShop(Guid shopId)
    {
        try
        {
            await _shopService.UnverifyShopAsync(shopId, HttpContext.RequestAborted);
            return Ok(ApiResponse<object?>.Ok(null, "Shop verification removed successfully."));
        }
        catch (KeyNotFoundException)
        {
            return this.NotFoundProblemResponse("Shop not found.");
        }
    }

    [HttpPost("{shopId:guid}/approve")]
    [RequirePermission(Permissions.ShopsApprove)]
    public async Task<IActionResult> ApproveShop(Guid shopId)
    {
        try
        {
            await _shopService.ApproveShopAsync(shopId, HttpContext.RequestAborted);
            return Ok(ApiResponse<object?>.Ok(null, "Shop approved successfully."));
        }
        catch (KeyNotFoundException)
        {
            return this.NotFoundProblemResponse("Shop not found.");
        }
    }

    [HttpPost("{shopId:guid}/reject")]
    [RequirePermission(Permissions.ShopsReject)]
    public async Task<IActionResult> RejectShop(Guid shopId, [FromBody] RejectShopRequestDto dto)
    {
        try
        {
            await _shopService.RejectShopAsync(shopId, dto, HttpContext.RequestAborted);
            return Ok(ApiResponse<object?>.Ok(null, "Shop rejected successfully."));
        }
        catch (KeyNotFoundException)
        {
            return this.NotFoundProblemResponse("Shop not found.");
        }
    }
}
