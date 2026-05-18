using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/keeper")]
[Authorize]
public class KeeperProfileController : ControllerBase
{
    private readonly IKeeperProfileService _profileService;
    private readonly IShopService _shopService;
    private readonly IKeeperContextService _keeperContextService;

    public KeeperProfileController(
        IKeeperProfileService profileService,
        IShopService shopService,
        IKeeperContextService keeperContextService)
    {
        _profileService = profileService;
        _shopService = shopService;
        _keeperContextService = keeperContextService;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _profileService.GetProfileAsync(keeper.KeeperId);
        return Ok(ApiResponse<KeeperProfileDto>.Ok(result));
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateKeeperProfileDto dto)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        await _profileService.UpdateProfileAsync(keeper.KeeperId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Profile updated"));
    }

    [HttpPost("document")]
    public async Task<IActionResult> CreateDocument([FromBody] UpsertKeeperDocumentDto dto)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var documentId = await _profileService.CreateDocumentAsync(keeper.KeeperId, dto);
        return Created($"/api/v1/keeper/document/{documentId}", ApiResponse<object>.Ok(new { documentId }, "Document attached"));
    }

    [HttpPut("document/{documentId:guid}")]
    public async Task<IActionResult> UpdateDocument(Guid documentId, [FromBody] UpsertKeeperDocumentDto dto)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        await _profileService.UpdateDocumentAsync(keeper.KeeperId, documentId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Document updated"));
    }

    [HttpDelete("document/{documentId:guid}")]
    public async Task<IActionResult> DeleteDocument(Guid documentId)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        await _profileService.DeleteDocumentAsync(keeper.KeeperId, documentId);
        return Ok(ApiResponse<object?>.Ok(null, "Document removed"));
    }

    [HttpPost("profile/messages/read")]
    public async Task<IActionResult> MarkReviewMessagesRead()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var updatedCount = await _profileService.MarkReviewMessagesReadAsync(keeper.KeeperId);
        return Ok(ApiResponse<MarkKeeperReviewMessagesReadResultDto>.Ok(
            new MarkKeeperReviewMessagesReadResultDto { UpdatedCount = updatedCount },
            "Review messages marked as read"));
    }

    [HttpPost("shop")]
    public async Task<IActionResult> RegisterShop([FromBody] RegisterShopDto dto)
    {
        var validationError = ValidateShopRequest(dto.Name, dto.Address, dto.Latitude, dto.Longitude, dto.NotificationRadius);
        if (validationError != null)
        {
            return validationError;
        }

        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var shopId = await _profileService.RegisterShopAsync(keeper.KeeperId, dto);
        return Created($"/api/v1/keeper/shop/{shopId}", ApiResponse<object>.Ok(new { shopId }, "Shop registered successfully"));
    }

    [HttpGet("shops")]
    public async Task<IActionResult> GetMyShops()
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _profileService.GetMyShopsAsync(keeper.KeeperId);
        return Ok(ApiResponse<List<ShopSummaryDto>>.Ok(result));
    }

    [HttpGet("shop/{shopId:guid}")]
    public async Task<IActionResult> GetShop(Guid shopId)
    {
        var keeper = await _keeperContextService.GetRequiredKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var result = await _shopService.GetShopAsync(shopId, HttpContext.RequestAborted);
        if (result == null)
        {
            return NotFound(ApiResponse<object>.Fail("NOT_FOUND", "Shop not found."));
        }

        if (result.KeeperId != keeper.KeeperId)
        {
            return Forbid();
        }

        return Ok(ApiResponse<ShopDetailDto>.Ok(result));
    }

    [HttpPut("shop/{shopId:guid}")]
    public async Task<IActionResult> UpdateShop(Guid shopId, [FromBody] UpdateShopRequestDto dto)
    {
        var validationError = ValidateShopRequest(dto.Name, dto.Address, dto.Latitude, dto.Longitude, dto.NotificationRadius);
        if (validationError != null)
        {
            return validationError;
        }

        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var existingShop = await _shopService.GetShopAsync(shopId, HttpContext.RequestAborted);
        if (existingShop == null)
        {
            return NotFound(ApiResponse<object>.Fail("NOT_FOUND", "Shop not found."));
        }

        if (existingShop.KeeperId != keeper.KeeperId)
        {
            return Forbid();
        }

        await _shopService.UpdateShopAsync(shopId, dto, HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "Shop updated"));
    }

    [HttpPost("shop/{shopId:guid}/google-sync")]
    public async Task<IActionResult> GoogleSync(Guid shopId)
    {
        var keeper = await _keeperContextService.GetRequiredActiveKeeperAsync(User.GetUserId(), HttpContext.RequestAborted);
        var existingShop = await _shopService.GetShopAsync(shopId, HttpContext.RequestAborted);
        if (existingShop == null)
        {
            return NotFound(ApiResponse<object>.Fail("NOT_FOUND", "Shop not found."));
        }

        if (existingShop.KeeperId != keeper.KeeperId)
        {
            return Forbid();
        }

        await _profileService.SyncWithGoogleBusinessAsync(shopId);
        return Ok(ApiResponse<object?>.Ok(null, "Synced with Google Business Profile"));
    }

    private IActionResult? ValidateShopRequest(
        string? name,
        string? address,
        double? latitude,
        double? longitude,
        double? notificationRadius)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Shop name is required."));
        }

        if (string.IsNullOrWhiteSpace(address))
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Shop address is required."));
        }

        if (latitude.HasValue != longitude.HasValue)
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Latitude and longitude must both be provided together."));
        }

        if (latitude is < -90 or > 90)
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Latitude must be between -90 and 90."));
        }

        if (longitude is < -180 or > 180)
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Longitude must be between -180 and 180."));
        }

        if (notificationRadius.HasValue && notificationRadius.Value <= 0)
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Notification radius must be greater than zero."));
        }

        return null;
    }
}
