using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/keeper")]
[Authorize]
public class KeeperProfileController : ControllerBase
{
    private readonly IKeeperProfileService _profileService;
    private readonly IShopService _shopService;

    public KeeperProfileController(IKeeperProfileService profileService, IShopService shopService)
    {
        _profileService = profileService;
        _shopService = shopService;
    }

    /// <summary>GET /api/v1/keeper/profile — Get keeper profile.</summary>
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var keeperId = User.GetUserId();
        var result = await _profileService.GetProfileAsync(keeperId);
        return Ok(ApiResponse<KeeperProfileDto>.Ok(result));
    }

    /// <summary>PUT /api/v1/keeper/profile — Update keeper profile.</summary>
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateKeeperProfileDto dto)
    {
        var keeperId = User.GetUserId();
        await _profileService.UpdateProfileAsync(keeperId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Profile updated"));
    }

    /// <summary>POST /api/v1/keeper/shop — Register new shop.</summary>
    [HttpPost("shop")]
    public async Task<IActionResult> RegisterShop([FromBody] RegisterShopDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Shop name is required."));
        var keeperId = User.GetUserId();
        var shopId = await _profileService.RegisterShopAsync(keeperId, dto);
        return Created($"/api/v1/keeper/shop/{shopId}", ApiResponse<object>.Ok(new { shopId }, "Shop registered successfully"));
    }

    /// <summary>GET /api/v1/keeper/shops — List all my shops.</summary>
    [HttpGet("shops")]
    public async Task<IActionResult> GetMyShops()
    {
        var keeperId = User.GetUserId();
        var result = await _profileService.GetMyShopsAsync(keeperId);
        return Ok(ApiResponse<List<ShopSummaryDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/keeper/shop/{shopId} — Get shop details.</summary>
    [HttpGet("shop/{shopId:guid}")]
    public async Task<IActionResult> GetShop(Guid shopId)
    {
        var keeperId = User.GetUserId();
        var result = await _shopService.GetShopAsync(shopId);
        if (result.KeeperId != keeperId) return Forbid();
        return Ok(ApiResponse<ShopDetailDto>.Ok(result));
    }

    /// <summary>PUT /api/v1/keeper/shop/{shopId} — Update shop details.</summary>
    [HttpPut("shop/{shopId:guid}")]
    public async Task<IActionResult> UpdateShop(Guid shopId, [FromBody] UpdateShopRequestDto dto)
    {
        var keeperId = User.GetUserId();
        var existingShop = await _shopService.GetShopAsync(shopId);
        if (existingShop.KeeperId != keeperId) return Forbid();

        await _shopService.UpdateShopAsync(shopId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Shop updated"));
    }

    /// <summary>POST /api/v1/keeper/shop/{shopId}/google-sync — Sync with Google Business Profile.</summary>
    [HttpPost("shop/{shopId:guid}/google-sync")]
    public async Task<IActionResult> GoogleSync(Guid shopId)
    {
        var keeperId = User.GetUserId();
        var existingShop = await _shopService.GetShopAsync(shopId);
        if (existingShop.KeeperId != keeperId) return Forbid();

        await _profileService.SyncWithGoogleBusinessAsync(shopId);
        return Ok(ApiResponse<object?>.Ok(null, "Synced with Google Business Profile"));
    }
}
