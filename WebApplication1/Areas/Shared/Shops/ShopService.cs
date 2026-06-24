using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Data;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Shops;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.Helpers;
using routent.AdminAPI.Models.Enums;

namespace routent.AdminAPI.Services;

public class ShopService : IShopService
{
    private readonly AppDbContext _context;
    private readonly ILogger<ShopService> _logger;

    public ShopService(AppDbContext context, ILogger<ShopService> logger)
    {
        _context = context;
        _logger = logger;
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

        if (!string.IsNullOrWhiteSpace(query.VerifyStatus))
        {
            dbQuery = dbQuery.Where(s => s.VerifyStatus == query.VerifyStatus);
        }

        if (query.IsActive.HasValue)
        {
            dbQuery = dbQuery.Where(s => s.IsActive == query.IsActive.Value);
        }

        var totalCount = await dbQuery.CountAsync(ct);
        
        var shopsList = await dbQuery
            .OrderByDescending(s => s.CreatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(ct);

        var shops = shopsList.Select(s => new ShopSummaryDto
        {
            Id = s.ShopId,
            Name = s.Name,
            BusinessName = s.Keeper != null ? s.Keeper.BusinessName : "N/A",
            Location = s.Address ?? "Unknown",
            Category = s.Category != null ? s.Category.Name : "Uncategorized",
            Status = s.IsActive ? "Active" : "Inactive",
            IsVerified = s.IsVerified,
            VerifyStatus = s.VerifyStatus,
            IsOpen = s.IsOpen,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(s.ImageUrl),
            RejectionReason = s.RejectionReason,
            DeactivateReason = s.DeactivateReason
        }).ToList();

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

    public async Task<ShopDetailDto?> GetShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var s = await _context.Shops
            .AsNoTracking()
            .Include(s => s.Keeper)
                .ThenInclude(k => k!.User)
            .Include(s => s.Category)
            .FirstOrDefaultAsync(s => s.ShopId == shopId, ct);

        if (s == null)
        {
            return null;
        }

        var shop = new ShopDetailDto
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
            KeeperUserId = s.Keeper != null ? s.Keeper.UserId : Guid.Empty,
            KeeperBusinessName = s.Keeper != null ? s.Keeper.BusinessName : null,
            KeeperName = s.Keeper != null && s.Keeper.User != null ? $"{s.Keeper.User.FirstName} {s.Keeper.User.LastName}".Trim() : null,
            IsActive = s.IsActive,
            IsVerified = s.IsVerified,
            VerifyStatus = s.VerifyStatus,
            RejectionReason = s.RejectionReason,
            DeactivateReason = s.DeactivateReason,
            IsOpen = s.IsOpen,
            NotificationRadius = s.NotificationRadius,
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(s.ImageUrl),
            ShopImages = s.ShopImages?
                .Select(img => ImageConversionHelper.ToBase64DataUrl(img))
                .OfType<string>()
                .ToList() ?? new List<string>(),
            Tags = s.Tags ?? new List<string>(),
            Amenities = s.Amenities ?? new List<string>(),
            CreatedAt = s.CreatedAt
        };

        shop.RecentOffers = await _context.Offers
            .AsNoTracking()
            .Where(o => o.ShopId == shopId && o.IsActive)
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .Select(o => new ShopOfferSummaryDto
            {
                OfferId = o.OfferId,
                Title = o.Title,
                Status = o.Status.ToString(),
                EndDate = o.EndDate,
                Description = o.Description,
                ImageUrl = ImageConversionHelper.ToBase64DataUrl(o.ImageData, "image/jpeg"),
                Tags = o.Tags ?? new List<string>()
            })
            .ToListAsync(ct);

        return shop;
    }

    public async Task<ShopDetailDto> CreateShopAsync(CreateShopRequestDto dto, CancellationToken ct = default)
    {
        await EnsureCategoryExistsAsync(dto.CategoryId, ct);
        
        var tagsList = NormalizeStringList(dto.Tags);
        await EnsureTagsExistAsync(tagsList, ct);

        var maxRadiusRule = await _context.PlatformRules
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Group == "General" && r.Key == "MaxAllowedRadiusKm", ct);
        var maxRadius = maxRadiusRule != null && double.TryParse(maxRadiusRule.Value, out var parsedMax) ? parsedMax : 25.0;

        var radius = dto.NotificationRadius ?? 10.0;
        if (radius <= 0)
        {
            throw new ArgumentException("Notification radius must be greater than zero.");
        }
        if (radius > maxRadius)
        {
            throw new ArgumentException($"Notification radius cannot exceed the maximum allowed limit of {maxRadius} km.");
        }

        var shop = new Shop
        {
            ShopId = Guid.NewGuid(),
            Name = NormalizeRequired(dto.Name, nameof(dto.Name)),
            Description = NormalizeOptional(dto.Description),
            Address = NormalizeOptional(dto.Address),
            PhoneNumber = NormalizeOptional(dto.PhoneNumber),
            Email = NormalizeOptional(dto.Email),
            KeeperId = dto.KeeperId,
            CategoryId = dto.CategoryId,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            ImageUrl = ImageConversionHelper.ParseBase64Image(dto.ShopProfileImage),
            ShopImages = dto.ShopImages?
                .Select(ImageConversionHelper.ParseBase64Image)
                .OfType<byte[]>()
                .ToList() ?? new List<byte[]>(),
            IsOpen = dto.IsOpen,
            NotificationRadius = radius,
            Amenities = NormalizeStringList(dto.Amenities),
            Tags = tagsList,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Shops.Add(shop);
        await _context.SaveChangesAsync(ct);

        return await GetShopAsync(shop.ShopId, ct)
            ?? throw new KeyNotFoundException($"Shop {shop.ShopId} not found after creation.");
    }

    public async Task UpdateShopAsync(Guid shopId, UpdateShopRequestDto dto, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");
        await EnsureCategoryExistsAsync(dto.CategoryId, ct);
        
        var tagsList = NormalizeStringList(dto.Tags);
        await EnsureTagsExistAsync(tagsList, ct);

        var maxRadiusRule = await _context.PlatformRules
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Group == "General" && r.Key == "MaxAllowedRadiusKm", ct);
        var maxRadius = maxRadiusRule != null && double.TryParse(maxRadiusRule.Value, out var parsedMax) ? parsedMax : 25.0;

        var radius = dto.NotificationRadius ?? 10.0;
        if (radius <= 0)
        {
            throw new ArgumentException("Notification radius must be greater than zero.");
        }
        if (radius > maxRadius)
        {
            throw new ArgumentException($"Notification radius cannot exceed the maximum allowed limit of {maxRadius} km.");
        }

        shop.Name = NormalizeRequired(dto.Name, nameof(dto.Name));
        shop.Description = NormalizeOptional(dto.Description);
        shop.Address = NormalizeOptional(dto.Address);
        shop.PhoneNumber = NormalizeOptional(dto.PhoneNumber);
        shop.Email = NormalizeOptional(dto.Email);
        shop.ImageUrl = ImageConversionHelper.ParseBase64Image(dto.ShopProfileImage);
        shop.ShopImages = dto.ShopImages?
            .Select(ImageConversionHelper.ParseBase64Image)
            .OfType<byte[]>()
            .ToList() ?? new List<byte[]>();
        shop.CategoryId = dto.CategoryId;
        shop.Latitude = dto.Latitude;
        shop.Longitude = dto.Longitude;
        shop.IsOpen = dto.IsOpen;
        shop.NotificationRadius = radius;
        shop.Amenities = NormalizeStringList(dto.Amenities);
        shop.Tags = tagsList;
        shop.UpdatedAt = DateTime.UtcNow;

        if (shop.VerifyStatus == "Rejected")
        {
            shop.RejectionReason = null;
        }

        _context.Shops.Update(shop);
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
        var shop = await _context.Shops.FirstOrDefaultAsync(s => s.ShopId == shopId, ct)
            ?? throw new KeyNotFoundException($"Shop {shopId} not found.");

        try
        {
            shop.IsActive = dto.IsActive ?? false;
            
            if (shop.IsActive)
            {
                if (!string.IsNullOrWhiteSpace(dto.Reason))
                {
                    shop.AdminNotes = string.IsNullOrWhiteSpace(shop.AdminNotes) 
                        ? $"Activation Note: {dto.Reason}" 
                        : $"{shop.AdminNotes}\nActivation Note: {dto.Reason}";
                }
                shop.DeactivateReason = null;
            }
            else
            {
                if (string.IsNullOrWhiteSpace(dto.Reason))
                {
                    throw new ArgumentException("Reason is required when deactivating a shop.");
                }
                shop.DeactivateReason = dto.Reason.Trim();
                shop.IsVerified = false;
                shop.VerifyStatus = "Deactivated";
            }
            shop.UpdatedAt = DateTime.UtcNow;

            _context.Shops.Update(shop);
            await _context.SaveChangesAsync(ct);
            
            if (!shop.IsActive)
            {
                await NotifyKeeperAsync(shop.KeeperId, "Shop Deactivated", $"Your shop '{shop.Name}' has been deactivated. Reason: {shop.DeactivateReason}", ct);
            }
            else
            {
                await NotifyKeeperAsync(shop.KeeperId, "Shop Activated", $"Your shop '{shop.Name}' has been activated by an administrator.", ct);
            }

            _logger.LogInformation("Shop {ShopId} status updated to {IsActive}. Reason: {Reason}", 
                shopId, dto.IsActive, dto.Reason ?? "N/A");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update shop status for {ShopId}", shopId);
            throw; // Re-throw to be caught by middleware
        }
    }

    public async Task VerifyShopAsync(Guid shopId, VerifyShopRequestDto dto, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        shop.IsVerified = true;
        shop.VerifyStatus = "Verified";
        shop.RejectionReason = null;
        if (!string.IsNullOrWhiteSpace(dto.Reason))
        {
            shop.AdminNotes = string.IsNullOrWhiteSpace(shop.AdminNotes) 
                ? $"Verification Note: {dto.Reason}" 
                : $"{shop.AdminNotes}\nVerification Note: {dto.Reason}";
        }
        shop.UpdatedAt = DateTime.UtcNow;

        _context.Shops.Update(shop);
        await _context.SaveChangesAsync(ct);
        await NotifyKeeperAsync(shop.KeeperId, "Shop Verified", $"Your shop '{shop.Name}' has been successfully verified.", ct);
    }

    public async Task UnverifyShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var updated = await _context.Shops
            .Where(shop => shop.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(shop => shop.IsVerified, false)
                .SetProperty(shop => shop.VerifyStatus, "Pending")
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
        var shop = await _context.Shops.FirstOrDefaultAsync(s => s.ShopId == shopId, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        var updated = await _context.Shops
            .Where(s => s.ShopId == shopId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(s => s.IsActive, false)
                .SetProperty(s => s.IsVerified, false)
                .SetProperty(s => s.VerifyStatus, "Rejected")
                .SetProperty(s => s.RejectionReason, dto.Reason.Trim())
                .SetProperty(s => s.UpdatedAt, DateTime.UtcNow), ct);

        if (updated > 0)
        {
            await NotifyKeeperAsync(shop.KeeperId, "Shop Rejected", $"Your shop '{shop.Name}' has been rejected. Reason: {dto.Reason.Trim()}", ct);
        }
    }
    
    public async Task ReapplyShopAsync(Guid shopId, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        if (shop.VerifyStatus != "Rejected" && shop.VerifyStatus != "Deactivated" && (shop.IsActive || string.IsNullOrEmpty(shop.DeactivateReason)))
        {
            throw new InvalidOperationException("Only rejected or deactivated shops can be reapplied.");
        }

        shop.IsVerified = false;
        shop.VerifyStatus = "Pending";
        shop.RejectionReason = null;
        shop.DeactivateReason = null;
        shop.UpdatedAt = DateTime.UtcNow;

        _context.Shops.Update(shop);
        await _context.SaveChangesAsync(ct);
        await NotifyAdminsAsync("Shop Reapplied", $"The shop '{shop.Name}' has been reapplied for verification by its keeper.", ct);
    }

    public async Task<List<ShopSummaryDto>> GetShopsByKeeperAsync(Guid keeperId, CancellationToken ct = default)
    {
        var shopsList = await _context.Shops
            .AsNoTracking()
            .Include(s => s.Category)
            .Where(s => s.KeeperId == keeperId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync(ct);

        return shopsList.Select(s => new ShopSummaryDto
        {
            Id = s.ShopId,
            Name = s.Name,
            BusinessName = "N/A", // Not needed for keeper-specific list
            Location = s.Address ?? "Unknown",
            Category = s.Category != null ? s.Category.Name : "Uncategorized",
            Status = s.IsActive ? "Active" : "Inactive",
            IsVerified = s.IsVerified,
            VerifyStatus = s.VerifyStatus,
            IsOpen = s.IsOpen,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(s.ImageUrl),
            RejectionReason = s.RejectionReason,
            DeactivateReason = s.DeactivateReason
        }).ToList();
    }

    public async Task AssignTagsAsync(Guid shopId, AssignTagsDto dto, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        shop.Tags = NormalizeStringList(dto.Tags);
        shop.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);
    }

    public async Task<bool> ToggleShopOpenAsync(Guid shopId, CancellationToken ct = default)
    {
        var shop = await _context.Shops.FindAsync(new object[] { shopId }, ct);
        if (shop == null) throw new KeyNotFoundException($"Shop {shopId} not found.");

        shop.IsOpen = !shop.IsOpen;
        shop.UpdatedAt = DateTime.UtcNow;

        _context.Shops.Update(shop);
        await _context.SaveChangesAsync(ct);

        return shop.IsOpen;
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
            VerifyStatus = shop.VerifyStatus,
            RejectionReason = shop.RejectionReason,
            DeactivateReason = shop.DeactivateReason,
            IsOpen = shop.IsOpen,
            NotificationRadius = shop.NotificationRadius,
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(shop.ImageUrl),
            ShopImages = shop.ShopImages?
                .Select(img => ImageConversionHelper.ToBase64DataUrl(img))
                .OfType<string>()
                .ToList() ?? new List<string>(),
            Tags = shop.Tags ?? new List<string>(),
            Amenities = shop.Amenities ?? new List<string>(),
            CreatedAt = shop.CreatedAt,
            RecentOffers = shop.Offers?.Where(o => o.IsActive).Select(o => new ShopOfferSummaryDto
            {
                OfferId = o.OfferId,
                Title = o.Title,
                Status = o.Status.ToString(),
                EndDate = o.EndDate,
                Description = o.Description,
                ImageUrl = ImageConversionHelper.ToBase64DataUrl(o.ImageData, "image/jpeg"),
                Tags = o.Tags ?? new List<string>()
            }).ToList() ?? new List<ShopOfferSummaryDto>()
        };
    }

    private async Task EnsureCategoryExistsAsync(Guid? categoryId, CancellationToken ct)
    {
        if (!categoryId.HasValue)
        {
            return;
        }

        var exists = await _context.Categories
            .AsNoTracking()
            .AnyAsync(category => category.CategoryId == categoryId.Value, ct);

        if (!exists)
        {
            throw new ArgumentException($"Category {categoryId.Value} was not found.");
        }
    }

    private static List<string> NormalizeStringList(List<string>? list)
    {
        if (list == null || list.Count == 0)
        {
            return new List<string>();
        }

        var normalized = list.Where(item => !string.IsNullOrWhiteSpace(item))
            .Select(item => item.Trim())
            .Distinct()
            .ToList();

        return normalized.Count > 0 ? normalized : new List<string>();
    }

    private async Task EnsureTagsExistAsync(List<string>? tags, CancellationToken ct)
    {
        if (tags == null || tags.Count == 0) return;

        var existingTags = await _context.Tags
            .Select(t => t.Name.ToLower())
            .ToListAsync(ct);

        foreach (var tag in tags)
        {
            if (!string.IsNullOrWhiteSpace(tag) && !existingTags.Contains(tag.ToLower()))
            {
                _context.Tags.Add(new Tag
                {
                    TagId = Guid.NewGuid(),
                    Name = tag.Trim(),
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });
                existingTags.Add(tag.ToLower());
            }
        }
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static string NormalizeRequired(string? value, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"{fieldName} is required.");
        }

        return value.Trim();
    }

    // Task-based overrides for interface compatibility if needed
    Task IShopService.UpdateShopStatusAsync(Guid shopId, UpdateShopStatusDto dto, CancellationToken ct) 
        => UpdateShopStatusAsync(shopId, dto, ct);
    
    Task IShopService.VerifyShopAsync(Guid shopId, VerifyShopRequestDto dto, CancellationToken ct) 
        => VerifyShopAsync(shopId, dto, ct);

    Task IShopService.UnverifyShopAsync(Guid shopId, CancellationToken ct)
        => UnverifyShopAsync(shopId, ct);

    Task IShopService.ApproveShopAsync(Guid shopId, CancellationToken ct)
        => ApproveShopAsync(shopId, ct);

    Task IShopService.RejectShopAsync(Guid shopId, RejectShopRequestDto dto, CancellationToken ct)
        => RejectShopAsync(shopId, dto, ct);
    private async Task NotifyKeeperAsync(Guid keeperId, string title, string message, CancellationToken ct)
    {
        var keeperUser = await _context.Keepers.FirstOrDefaultAsync(k => k.KeeperId == keeperId, ct);
        if (keeperUser == null) return;

        var notification = new Notification
        {
            NotificationId = Guid.NewGuid(),
            Title = title,
            Message = message,
            Type = NotificationType.SystemMessage,
            Priority = NotificationPriority.Normal,
            TargetAudience = keeperUser.UserId.ToString(),
            Status = NotificationStatus.Sent,
            ScheduledAt = DateTime.UtcNow,
            SentAt = DateTime.UtcNow,
            SentById = Guid.Empty,
            SenderType = "System",
            RecipientCount = 1,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _context.Notifications.Add(notification);

        _context.UserNotifications.Add(new UserNotification
        {
            UserId = keeperUser.UserId,
            NotificationId = notification.NotificationId,
            IsRead = false,
            IsDeleted = false,
            DeliveryStatus = "Delivered",
            SentAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync(ct);
    }

    private async Task NotifyAdminsAsync(string title, string message, CancellationToken ct)
    {
        var adminIds = await _context.Users.Where(u => u.Role == "admin" && u.IsActive).Select(u => u.UserId).ToListAsync(ct);
        if (!adminIds.Any()) return;

        var notification = new Notification
        {
            NotificationId = Guid.NewGuid(),
            Title = title,
            Message = message,
            Type = NotificationType.SystemMessage,
            Priority = NotificationPriority.Normal,
            TargetAudience = "admins",
            Status = NotificationStatus.Sent,
            ScheduledAt = DateTime.UtcNow,
            SentAt = DateTime.UtcNow,
            SentById = Guid.Empty,
            SenderType = "System",
            RecipientCount = adminIds.Count,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _context.Notifications.Add(notification);

        var userNotifications = adminIds.Select(id => new UserNotification
        {
            UserId = id,
            NotificationId = notification.NotificationId,
            IsRead = false,
            IsDeleted = false,
            DeliveryStatus = "Delivered",
            SentAt = DateTime.UtcNow
        });
        await _context.UserNotifications.AddRangeAsync(userNotifications, ct);
        await _context.SaveChangesAsync(ct);
    }
}
