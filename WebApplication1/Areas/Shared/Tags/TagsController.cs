using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Filters;
using routent.AdminAPI.Constants;
using routent.AdminAPI.DTOs.Tags;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/tags")]
[Authorize]
public class TagsController : ControllerBase
{
    private readonly ITagService _tagService;
    public TagsController(ITagService tagService) => _tagService = tagService;

    [HttpGet]
    [RequirePermission(Permissions.TagsView)]
    public async Task<IActionResult> GetTags([FromQuery] string? type = null)
        => Ok(ApiResponse<List<TagDetailDto>>.Ok(await _tagService.GetTagsAsync(type)));

    /// GET /api/v1/admin/tags/{tagId}
    [HttpGet("{tagId:guid}")]
    [RequirePermission(Permissions.TagsView)]
    public async Task<IActionResult> GetTag(Guid tagId)
        => Ok(ApiResponse<TagDetailDto>.Ok(await _tagService.GetTagAsync(tagId)));

    /// POST /api/v1/admin/tags
    [HttpPost]
    [RequirePermission(Permissions.TagsCreate)]
    public async Task<IActionResult> CreateTag([FromBody] CreateTagRequestDto dto)
    {
        var result = await _tagService.CreateTagAsync(dto);
        return CreatedAtAction(nameof(GetTag), new { tagId = result.TagId }, ApiResponse<TagDetailDto>.Ok(result));
    }

    /// PUT /api/v1/admin/tags/{tagId}
    [HttpPut("{tagId:guid}")]
    [RequirePermission(Permissions.TagsEdit)]
    public async Task<IActionResult> UpdateTag(Guid tagId, [FromBody] UpdateTagRequestDto dto)
    {
        await _tagService.UpdateTagAsync(tagId, dto);
        return NoContent();
    }

    /// DELETE /api/v1/admin/tags/{tagId}
    [HttpDelete("{tagId:guid}")]
    [RequirePermission(Permissions.TagsDelete)]
    public async Task<IActionResult> DeleteTag(Guid tagId)
    {
        await _tagService.DeleteTagAsync(tagId);
        return NoContent();
    }
}
