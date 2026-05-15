using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Public;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserSearchController : ControllerBase
{
    private readonly IPlacesService _placesService;
    private readonly IFavouriteService _favouriteService;

    public UserSearchController(IPlacesService placesService, IFavouriteService favouriteService)
    {
        _placesService = placesService;
        _favouriteService = favouriteService;
    }

    /// <summary>GET /api/v1/user/search/places — Search and autocomplete for destinations.</summary>
    [HttpGet("search/places")]
    [AllowAnonymous]
    public async Task<IActionResult> SearchPlaces([FromQuery] string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Search query is required."));
        return Ok(ApiResponse<List<PlaceSearchResponseDto>>.Ok(await _placesService.SearchPlacesAsync(query)));
    }

    /// <summary>GET /api/v1/user/favourites — Get favourite places/shops.</summary>
    [HttpGet("favourites")]
    public async Task<IActionResult> GetFavourites()
    {
        var userId = User.GetUserId();
        var result = await _favouriteService.GetFavouritesAsync(userId);
        return Ok(ApiResponse<List<object>>.Ok(result));
    }

    /// <summary>POST /api/v1/user/favourites — Add or remove favourite.</summary>
    [HttpPost("favourites")]
    public async Task<IActionResult> ToggleFavourite([FromBody] ToggleFavouriteDto dto)
    {
        var userId = User.GetUserId();
        if (dto.ShopId == null && dto.OfferId == null)
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Either ShopId or OfferId is required."));
        await _favouriteService.ToggleFavouriteAsync(userId, dto);
        return Ok(ApiResponse<object?>.Ok(null, "Favourite toggled"));
    }
}
