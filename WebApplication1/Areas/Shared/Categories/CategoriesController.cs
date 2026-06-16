using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Categories;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Filters;
using routent.AdminAPI.Constants;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/categories")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categoryService;
    public CategoriesController(ICategoryService categoryService) => _categoryService = categoryService;

    [HttpGet]
    [RequirePermission(Permissions.CategoriesView)]
    public async Task<IActionResult> GetTree([FromQuery] bool includeInactive = false)
    {
        var result = await _categoryService.GetCategoryTreeAsync(includeInactive);
        return Ok(ApiResponse<List<CategoryTreeDto>>.Ok(result));
    }

    [HttpPost]
    [RequirePermission(Permissions.CategoriesCreate)]
    public async Task<IActionResult> Create([FromBody] CreateCategoryRequestDto dto)
    {
        var result = await _categoryService.CreateCategoryAsync(dto);
        return Ok(ApiResponse<CategoryTreeDto>.Ok(result));
    }

    [HttpPut("{categoryId:guid}")]
    [RequirePermission(Permissions.CategoriesEdit)]
    public async Task<IActionResult> Update(Guid categoryId, [FromBody] UpdateCategoryRequestDto dto)
    {
        var result = await _categoryService.UpdateCategoryAsync(categoryId, dto);
        return Ok(ApiResponse<CategoryTreeDto>.Ok(result));
    }

    [HttpDelete("{categoryId:guid}")]
    [RequirePermission(Permissions.CategoriesDelete)]
    public async Task<IActionResult> Delete(Guid categoryId, [FromQuery] Guid? reassignTo)
    {
        await _categoryService.DeleteCategoryAsync(categoryId, reassignTo);
        return NoContent();
    }

    [HttpPut("reorder")]
    [RequirePermission(Permissions.CategoriesEdit)]
    public async Task<IActionResult> Reorder([FromBody] ReorderCategoriesRequestDto dto)
    {
        await _categoryService.ReorderCategoriesAsync(dto);
        return NoContent();
    }

    [HttpGet("{categoryId:guid}/analytics")]
    [RequirePermission(Permissions.CategoriesView)]
    public async Task<IActionResult> GetAnalytics(Guid categoryId)
        => Ok(ApiResponse<object>.Ok(await _categoryService.GetCategoryAnalyticsAsync(categoryId)));

    [HttpPost("sync-firestore")]
    [RequirePermission(Permissions.CategoriesEdit)]
    public async Task<IActionResult> SyncFirestore()
    {
        var count = await _categoryService.SyncAllToFirestoreAsync();
        return Ok(ApiResponse<object>.Ok(new { syncedCount = count, syncedAt = DateTime.UtcNow }));
    }
}
