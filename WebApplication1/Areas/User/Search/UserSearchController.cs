using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Public;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserSearchController : ControllerBase
{
    private readonly IPlacesService _placesService;
    private readonly IFavouriteService _favouriteService;
    private readonly IShopService _shopService;

    public UserSearchController(IPlacesService placesService, IFavouriteService favouriteService, IShopService shopService)
    {
        _placesService = placesService;
        _favouriteService = favouriteService;
        _shopService = shopService;
    }

    [HttpGet("search/places")]
    [AllowAnonymous]
    public async Task<IActionResult> SearchPlaces([FromQuery] string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Search query is required."));
        }

        return Ok(ApiResponse<List<PlaceSearchResponseDto>>.Ok(await _placesService.SearchPlacesAsync(query)));
    }

    [HttpGet("favourites")]
    public async Task<IActionResult> GetFavourites()
    {
        var userId = User.GetUserId();
        var result = await _favouriteService.GetFavouritesAsync(userId);
        return Ok(ApiResponse<List<SavedItemDto>>.Ok(result));
    }

    [HttpPost("favourites")]
    public async Task<IActionResult> ToggleFavourite([FromBody] ToggleFavouriteDto dto)
    {
        var userId = User.GetUserId();
        if (dto.ShopId == null && dto.OfferId == null)
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Either ShopId or OfferId is required."));
        }

        await _favouriteService.ToggleFavouriteAsync(userId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Favourite toggled"));
    }

    [HttpGet("shops/{shopId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetShop(Guid shopId)
    {
        var shop = await _shopService.GetShopAsync(shopId, HttpContext.RequestAborted);
        if (shop == null)
        {
            return NotFound(ApiResponse<object>.Fail("NOT_FOUND", "Shop not found."));
        }

        return Ok(ApiResponse<ShopDetailDto>.Ok(shop));
    }
}
