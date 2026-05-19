using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Public;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.DTOs.Categories;
using allonbiz.AdminAPI.DTOs.Tags;
using allonbiz.AdminAPI.DTOs.Users;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1")]
[AllowAnonymous]
public class PublicController : ControllerBase
{
    private readonly ICategoryService _categoryService;
    private readonly IPlacesService _placesService;
    private readonly IReviewService _reviewService;
    private readonly ITagService _tagService;

    public PublicController(
        ICategoryService categoryService, 
        IPlacesService placesService, 
        IReviewService reviewService,
        ITagService tagService)
    {
        _categoryService = categoryService;
        _placesService = placesService;
        _reviewService = reviewService;
        _tagService = tagService;
    }

    /// <summary>GET /api/v1/categories — Get all categories (public).</summary>
    [HttpGet("categories")]
    public async Task<IActionResult> GetCategories()
    {
        var result = await _categoryService.GetCategoryTreeAsync();
        return Ok(ApiResponse<List<CategoryTreeDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/public/tags — Get all active tags (public).</summary>
    [HttpGet("public/tags")]
    public async Task<IActionResult> GetPublicTags()
    {
        var allTags = await _tagService.GetTagsAsync(null);
        var activeTags = allTags.Where(t => t.IsActive).ToList();
        return Ok(ApiResponse<List<TagDetailDto>>.Ok(activeTags));
    }

    /// <summary>POST /api/v1/public/tags — Create a new tag (public).</summary>
    [HttpPost("public/tags")]
    public async Task<IActionResult> CreatePublicTag([FromBody] CreateTagRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Tag name is required."));

        dto.Type ??= "public";
        var result = await _tagService.CreateTagAsync(dto);
        return CreatedAtAction(nameof(GetPublicTags), ApiResponse<TagDetailDto>.Ok(result));
    }

    /// <summary>GET /api/v1/reviews — Get reviews.</summary>
    [HttpGet("reviews")]
    public async Task<IActionResult> GetReviews([FromQuery] Guid? shopId, [FromQuery] Guid? offerId, [FromQuery] PaginationParams paging)
    {
        var result = await _reviewService.GetReviewsAsync(shopId, offerId, paging, publishedOnly: true);
        return Ok(ApiResponse<PagedResponse<ReviewDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/places/search — General place search.</summary>
    [HttpGet("places/search")]
    public async Task<IActionResult> SearchPlaces([FromQuery] string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return BadRequest(ApiResponse<object>.Fail("VALIDATION_ERROR", "Search query is required."));
        var result = await _placesService.SearchPlacesAsync(query);
        return Ok(ApiResponse<List<PlaceSearchResponseDto>>.Ok(result));
    }

    /// <summary>GET /api/v1/offers/trending — Trending offers.</summary>
    [HttpGet("offers/trending")]
    public async Task<IActionResult> GetTrendingOffers()
    {
        var result = await _placesService.GetTrendingOffersAsync();
        return Ok(ApiResponse<List<TrendingOfferDto>>.Ok(result));
    }
}
