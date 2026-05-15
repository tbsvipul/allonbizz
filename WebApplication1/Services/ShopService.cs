using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class ShopService : IShopService
{
    private readonly AppDbContext _context;

    public ShopService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResponse<ShopSummaryDto>> GetShopsAsync(ShopListQueryDto query, CancellationToken ct = default)
    {
        var dbQuery = _context.Shops
            .Include(s => s.Keeper)
            .Include(s => s.Category)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.ToLower();
            dbQuery = dbQuery.Where(s => s.Name.ToLower().Contains(search) || 
                                        (s.Keeper != null && s.Keeper.BusinessName.ToLower().Contains(search)));
        }

        if (query.CategoryId.HasValue)
        {
            dbQuery = dbQuery.Where(s => s.CategoryId == query.CategoryId.Value);
        }

        if (query.IsVerified.HasValue)
        {
            dbQuery = dbQuery.Where(s => s.IsVerified == query.IsVerified.Value);
        }

        if (query.IsActive.HasValue)
        {
            dbQuery = dbQuery.Where(s => s.IsActive == query.IsActive.Value);
        }

        var totalCount = await dbQuery.CountAsync(ct);
        
        var shops = await dbQuery
            .OrderByDescending(s => s.CreatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(s => new ShopSummaryDto
            {
                Id = s.ShopId,
                Name = s.Name,
                BusinessName = s.Keeper != null ? s.Keeper.BusinessName : "N/A",
                Location = s.Address ?? "Unknown",
                Category = s.Category != null ? s.Category.Name : "Uncategorized",
                Status = s.IsActive ? "Active" : "Inactive",
                IsVerified = s.IsVerified,
                Latitude = s.Latitude,
                Longitude = s.Longitude,
                ImageUrl = s.ImageUrl
            })
            .ToListAsync(ct);

        return new PagedResponse<ShopSummaryDto>
        {
            Data = shops,
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<ShopDetailDto> GetShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var shop = await _context.Shops
            .AsNoTracking()
            .Where(s => s.ShopId == shopId)
            .Select(s => new ShopDetailDto
            {
                ShopId = s.ShopId,
                Name = s.Name,
                Description = s.Description,
                Address = s.Address,
                PhoneNumber = s.PhoneNumber,
                Email = s.Email,
                Latitude = s.Latitude,
                Longitude = s.Longitude,
                CategoryId = s.CategoryId,
                CategoryName = s.Category != null ? s.Category.Name : null,
                KeeperId = s.KeeperId,
                KeeperBusinessName = s.Keeper != null ? s.Keeper.BusinessName : null,
                IsActive = s.IsActive,
                IsVerified = s.IsVerified,
                IsOpen = s.IsOpen,
                ImageUrl = s.ImageUrl,
                Tags = s.Tags,
                Amenities = s.Amenities ?? new List<string>(),
                CreatedAt = s.CreatedAt
            })
            .FirstOrDefaultAsync(ct);

        if (shop == null)
        {
            return null!;
        }

        shop.RecentOffers = await _context.Offers
            .AsNoTracking()
            .Where(o => o.ShopId == shopId)
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .Select(o => new ShopOfferSummaryDto
            {
                OfferId = o.OfferId,
                Title = o.Title,
                Status = o.Status.ToString(),
                EndDate = o.EndDate
            })
            .ToListAsync(ct);

        return shop;
    }

    public async Task<ShopDetailDto> CreateShopAsync(CreateShopRequestDto dto, CancellationToken ct = default)
    {
        var shop = new Shop
        {
            ShopId = Guid.NewGuid(),
            Name = dto.Name,
            Description = dto.Description,
            Address = dto.Address,
            PhoneNumber = dto.PhoneNumber,
            Email = dto.Email,
            KeeperId = dto.KeeperId,
            CategoryId = dto.CategoryId,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            Tags = dto.Tags ?? new List<string>(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Shops.Add(shop);
        await _context.SaveChangesAsync(ct);

        return await GetShopAsync(shop.ShopId, ct);
    }

    public async Task UpdateShopAsync(Guid shopId, UpdateShopRequestDto dto, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        shop.Name = dto.Name;
        shop.Description = dto.Description;
        shop.Address = dto.Address;
        shop.PhoneNumber = dto.PhoneNumber;
        shop.Email = dto.Email;
        shop.CategoryId = dto.CategoryId;
        shop.Latitude = dto.Latitude;
        shop.Longitude = dto.Longitude;
        shop.Tags = dto.Tags ?? new List<string>();
        shop.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);
    }

    public async Task DeleteShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var deleted = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteDeleteAsync(ct);

        if (deleted == 0)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }
    }

    public async Task UpdateShopStatusAsync(Guid shopId, UpdateShopStatusDto dto, CancellationToken ct = default)
    {
        var rejectionReason = dto.IsActive
            ? null
            : string.IsNullOrWhiteSpace(dto.Reason) ? null : dto.Reason.Trim();

        var updated = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(shop => shop.IsActive, dto.IsActive)
                .SetProperty(shop => shop.RejectionReason, rejectionReason)
                .SetProperty(shop => shop.UpdatedAt, DateTime.UtcNow), ct);

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }
    }

    public async Task VerifyShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var updated = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(shop => shop.IsVerified, true)
                .SetProperty(shop => shop.RejectionReason, (string?)null)
                .SetProperty(shop => shop.UpdatedAt, DateTime.UtcNow), ct);

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }
    }

    public async Task UnverifyShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var updated = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(shop => shop.IsVerified, false)
                .SetProperty(shop => shop.UpdatedAt, DateTime.UtcNow), ct);

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }
    }

    public async Task ApproveShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var updated = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(shop => shop.IsActive, true)
                .SetProperty(shop => shop.RejectionReason, (string?)null)
                .SetProperty(shop => shop.UpdatedAt, DateTime.UtcNow), ct);

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }
    }

    public async Task RejectShopAsync(Guid shopId, RejectShopRequestDto dto, CancellationToken ct = default)
    {
        var updated = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(shop => shop.IsActive, false)
                .SetProperty(shop => shop.IsVerified, false)
                .SetProperty(shop => shop.RejectionReason, dto.Reason.Trim())
                .SetProperty(shop => shop.UpdatedAt, DateTime.UtcNow), ct);

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }
    }

    public async Task<List<ShopSummaryDto>> GetShopsByKeeperAsync(Guid keeperId, CancellationToken ct = default)
    {
        return await _context.Shops
            .Include(s => s.Category)
            .Where(s => s.KeeperId == keeperId)
            .Select(s => new ShopSummaryDto
            {
                Id = s.ShopId,
                Name = s.Name,
                BusinessName = "N/A", // Not needed for keeper-specific list
                Location = s.Address ?? "Unknown",
                Category = s.Category != null ? s.Category.Name : "Uncategorized",
                Status = s.IsActive ? "Active" : "Inactive",
                IsVerified = s.IsVerified,
                Latitude = s.Latitude,
                Longitude = s.Longitude
            })
            .ToListAsync(ct);
    }

    public async Task AssignTagsAsync(Guid shopId, AssignTagsDto dto, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        shop.Tags = dto.Tags ?? new List<string>();
        shop.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);
    }

    private ShopDetailDto MapToDetailDto(Shop shop)
    {
        return new ShopDetailDto
        {
            ShopId = shop.ShopId,
            Name = shop.Name,
            Description = shop.Description,
            Address = shop.Address,
            PhoneNumber = shop.PhoneNumber,
            Email = shop.Email,
            Latitude = shop.Latitude,
            Longitude = shop.Longitude,
            CategoryId = shop.CategoryId,
            CategoryName = shop.Category?.Name,
            KeeperId = shop.KeeperId,
            KeeperBusinessName = shop.Keeper?.BusinessName,
            IsActive = shop.IsActive,
            IsVerified = shop.IsVerified,
            IsOpen = shop.IsOpen,
            ImageUrl = shop.ImageUrl,
            Tags = shop.Tags,
            Amenities = shop.Amenities ?? new List<string>(),
            CreatedAt = shop.CreatedAt,
            RecentOffers = shop.Offers?.Select(o => new ShopOfferSummaryDto
            {
                OfferId = o.OfferId,
                Title = o.Title,
                Status = o.Status.ToString(),
                EndDate = o.EndDate
            }).ToList() ?? new List<ShopOfferSummaryDto>()
        };
    }

    // Task-based overrides for interface compatibility if needed
    Task IShopService.UpdateShopStatusAsync(Guid shopId, UpdateShopStatusDto dto, CancellationToken ct) 
        => UpdateShopStatusAsync(shopId, dto, ct);
    
    Task IShopService.VerifyShopAsync(Guid shopId, CancellationToken ct) 
        => VerifyShopAsync(shopId, ct);

    Task IShopService.UnverifyShopAsync(Guid shopId, CancellationToken ct)
        => UnverifyShopAsync(shopId, ct);

    Task IShopService.ApproveShopAsync(Guid shopId, CancellationToken ct)
        => ApproveShopAsync(shopId, ct);

    Task IShopService.RejectShopAsync(Guid shopId, RejectShopRequestDto dto, CancellationToken ct)
        => RejectShopAsync(shopId, dto, ct);
}
