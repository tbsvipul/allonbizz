using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Tags;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class TagService : ITagService
{
    private readonly IRepository<Tag> _tagRepo;

    public TagService(IRepository<Tag> tagRepo)
    {
        _tagRepo = tagRepo;
    }

    public async Task<List<TagDetailDto>> GetTagsAsync(string? type = null, CancellationToken ct = default)
    {
        var q = _tagRepo.Query().AsNoTracking();
        if (!string.IsNullOrEmpty(type)) q = q.Where(t => t.Type == type);

        return await q.Select(t => new TagDetailDto
        {
            TagId = t.TagId,
            Name = t.Name,
            Type = t.Type,
            Color = t.Color,
            IconData = t.IconData,
            IsActive = t.IsActive,
            CreatedAt = t.CreatedAt,
            UpdatedAt = t.UpdatedAt
        }).ToListAsync(ct);
    }

    public async Task<TagDetailDto> GetTagAsync(Guid tagId, CancellationToken ct = default)
    {
        var t = await _tagRepo.GetByIdAsync(tagId, ct);
        if (t == null) throw new KeyNotFoundException($"Tag {tagId} not found.");

        return new TagDetailDto
        {
            TagId = t.TagId,
            Name = t.Name,
            Type = t.Type,
            Color = t.Color,
            IconData = t.IconData,
            IsActive = t.IsActive,
            CreatedAt = t.CreatedAt,
            UpdatedAt = t.UpdatedAt
        };
    }

    public async Task<TagDetailDto> CreateTagAsync(CreateTagRequestDto dto, CancellationToken ct = default)
    {
        var tag = new Tag
        {
            TagId = Guid.NewGuid(),
            Name = dto.Name,
            Type = dto.Type,
            Color = dto.Color,
            IconData = dto.IconData,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        await _tagRepo.AddAsync(tag, ct);
        await _tagRepo.SaveChangesAsync(ct);
        return await GetTagAsync(tag.TagId, ct);
    }

    public async Task UpdateTagAsync(Guid tagId, UpdateTagRequestDto dto, CancellationToken ct = default)
    {
        var t = await _tagRepo.GetByIdAsync(tagId, ct);
        if (t == null) throw new KeyNotFoundException($"Tag {tagId} not found.");

        t.Name = dto.Name;
        t.Type = dto.Type;
        t.Color = dto.Color;
        t.IconData = dto.IconData;
        t.IsActive = dto.IsActive;
        t.UpdatedAt = DateTime.UtcNow;

        await _tagRepo.SaveChangesAsync(ct);
    }

    public async Task DeleteTagAsync(Guid tagId, CancellationToken ct = default)
    {
        var t = await _tagRepo.GetByIdAsync(tagId, ct);
        if (t != null)
        {
            _tagRepo.Remove(t);
            await _tagRepo.SaveChangesAsync(ct);
        }
    }
}
