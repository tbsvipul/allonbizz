using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Data;
using routent.AdminAPI.Data.Interfaces;
using routent.AdminAPI.DTOs.Categories;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Services.Interfaces;

namespace routent.AdminAPI.Services;

public class CategoryService : ICategoryService
{
    private readonly AppDbContext _db;
    private readonly IRepository<Category> _categoryRepo;
    private readonly IFirestoreService _firestore;
    private readonly ILogger<CategoryService> _logger;

    public CategoryService(AppDbContext db, IRepository<Category> categoryRepo, IFirestoreService firestore, ILogger<CategoryService> logger)
    {
        _db = db;
        _categoryRepo = categoryRepo;
        _firestore = firestore;
        _logger = logger;
    }

    public async Task<List<CategoryTreeDto>> GetCategoryTreeAsync(bool includeInactive = false, CancellationToken ct = default)
    {
        var all = await _categoryRepo.Query()
            .AsNoTracking()
            .OrderBy(c => c.DisplayOrder)
            .ToListAsync(ct);

        if (!includeInactive) all = all.Where(c => c.IsActive).ToList();

        var businessCounts = await _db.Shops
            .AsNoTracking()
            .Where(shop => shop.CategoryId.HasValue)
            .GroupBy(shop => shop.CategoryId!.Value)
            .Select(group => new { CategoryId = group.Key, Count = group.Count() })
            .ToDictionaryAsync(item => item.CategoryId, item => item.Count, ct);

        return BuildTree(all, null, businessCounts);
    }

    private List<CategoryTreeDto> BuildTree(List<Category> all, Guid? parentId, IReadOnlyDictionary<Guid, int> businessCounts)
    {
        return all.Where(c => c.ParentCategoryId == parentId)
            .Select(c => new CategoryTreeDto
            {
                CategoryId = c.CategoryId,
                Name = c.Name,
                Icon = c.Icon ?? string.Empty,
                Color = c.Color ?? string.Empty,
                Description = c.Description,
                DisplayOrder = c.DisplayOrder,
                IsActive = c.IsActive,
                ParentCategoryId = c.ParentCategoryId,
                BusinessCount = businessCounts.GetValueOrDefault(c.CategoryId),
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt,
                Children = BuildTree(all, c.CategoryId, businessCounts)
            }).ToList();
    }

    public async Task<CategoryTreeDto> CreateCategoryAsync(CreateCategoryRequestDto dto, CancellationToken ct = default)
    {
        var category = new Category
        {
            CategoryId = Guid.NewGuid(),
            Name = dto.Name,
            Icon = dto.Icon,
            Color = dto.Color,
            Description = dto.Description,
            ParentCategoryId = dto.ParentCategoryId,
            DisplayOrder = dto.DisplayOrder,
            IsActive = dto.IsActive,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _categoryRepo.AddAsync(category, ct);
        await _categoryRepo.SaveChangesAsync(ct);
        await _firestore.SyncCategoryAsync(category, ct);
        
        return await GetCategoryTreeNodeAsync(category.CategoryId, ct);
    }

    public async Task<CategoryTreeDto> UpdateCategoryAsync(Guid categoryId, UpdateCategoryRequestDto dto, CancellationToken ct = default)
    {
        var c = await _categoryRepo.GetByIdAsync(categoryId, ct);
        if (c == null) throw new KeyNotFoundException($"Category {categoryId} not found.");

        c.Name = dto.Name;
        c.Icon = dto.Icon;
        c.Color = dto.Color;
        c.Description = dto.Description;
        c.ParentCategoryId = dto.ParentCategoryId;
        c.DisplayOrder = dto.DisplayOrder;
        c.IsActive = dto.IsActive;
        c.UpdatedAt = DateTime.UtcNow;

        await _categoryRepo.SaveChangesAsync(ct);
        await _firestore.SyncCategoryAsync(c, ct);

        return await GetCategoryTreeNodeAsync(categoryId, ct);
    }

    public async Task DeleteCategoryAsync(Guid categoryId, Guid? reassignToId = null, CancellationToken ct = default)
    {
        var c = await _categoryRepo.GetByIdAsync(categoryId, ct);
        if (c == null)
        {
            return;
        }

        if (reassignToId.HasValue)
        {
            var replacementExists = await _categoryRepo.Query().AnyAsync(x => x.CategoryId == reassignToId.Value, ct);
            if (!replacementExists)
            {
                throw new KeyNotFoundException($"Replacement category {reassignToId} not found.");
            }
        }

        var childCategories = await _categoryRepo.Query()
            .Where(category => category.ParentCategoryId == categoryId)
            .ToListAsync(ct);

        foreach (var child in childCategories)
        {
            child.ParentCategoryId = reassignToId;
            child.UpdatedAt = DateTime.UtcNow;
        }

        var shops = await _db.Shops.Where(shop => shop.CategoryId == categoryId).ToListAsync(ct);
        foreach (var shop in shops)
        {
            shop.CategoryId = reassignToId;
            shop.UpdatedAt = DateTime.UtcNow;
        }

        _categoryRepo.Remove(c);
        await _categoryRepo.SaveChangesAsync(ct);
        await _firestore.DeleteCategoryAsync(categoryId.ToString(), ct);
    }

    public async Task ReorderCategoriesAsync(ReorderCategoriesRequestDto dto, CancellationToken ct = default)
    {
        var categoryIds = dto.Orders.Select(order => order.CategoryId).Distinct().ToList();
        var categories = await _categoryRepo.Query()
            .Where(category => categoryIds.Contains(category.CategoryId))
            .ToListAsync(ct);

        foreach (var order in dto.Orders)
        {
            var category = categories.FirstOrDefault(item => item.CategoryId == order.CategoryId);
            if (category == null)
            {
                continue;
            }

            category.DisplayOrder = order.DisplayOrder;
            category.UpdatedAt = DateTime.UtcNow;
        }

        await _categoryRepo.SaveChangesAsync(ct);
    }

    public async Task<object> GetCategoryAnalyticsAsync(Guid categoryId, CancellationToken ct = default)
    {
        var category = await _categoryRepo.Query()
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.CategoryId == categoryId, ct)
            ?? throw new KeyNotFoundException($"Category {categoryId} not found.");

        var shopsQuery = _db.Shops.AsNoTracking().Where(shop => shop.CategoryId == categoryId);
        var totalShops = await shopsQuery.CountAsync(ct);
        var activeShops = await shopsQuery.CountAsync(shop => shop.IsActive, ct);
        var verifiedShops = await shopsQuery.CountAsync(shop => shop.IsVerified, ct);

        return new
        {
            categoryId = category.CategoryId,
            categoryName = category.Name,
            totalShops,
            activeShops,
            verifiedShops,
            lastUpdatedAt = category.UpdatedAt
        };
    }

    public async Task<int> SyncAllToFirestoreAsync(CancellationToken ct = default)
    {
        var categories = await _categoryRepo.GetAllAsync(ct);
        return await _firestore.SyncAllCategoriesAsync(categories, ct);
    }

    private async Task<CategoryTreeDto> GetCategoryTreeNodeAsync(Guid categoryId, CancellationToken ct)
    {
        var tree = await GetCategoryTreeAsync(true, ct);
        var match = Flatten(tree).FirstOrDefault(category => category.CategoryId == categoryId);
        if (match == null)
        {
            throw new KeyNotFoundException($"Category {categoryId} not found.");
        }

        return match;
    }

    private static IEnumerable<CategoryTreeDto> Flatten(IEnumerable<CategoryTreeDto> nodes)
    {
        foreach (var node in nodes)
        {
            yield return node;
            foreach (var child in Flatten(node.Children))
            {
                yield return child;
            }
        }
    }
}
