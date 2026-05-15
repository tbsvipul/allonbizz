using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.Models.Enums;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Services;

public class KeeperProfileService : IKeeperProfileService
{
    private readonly AppDbContext _db;
    public KeeperProfileService(AppDbContext db) => _db = db;

    public async Task<KeeperProfileDto> GetProfileAsync(Guid keeperId)
    {
        var keeper = await _db.Keepers.FindAsync(keeperId);
        if (keeper == null) return null!;
        return new KeeperProfileDto { KeeperId = keeper.KeeperId, BusinessName = keeper.BusinessName, Status = keeper.Status };
    }

    public async Task UpdateProfileAsync(Guid keeperId, UpdateKeeperProfileDto dto)
    {
        var keeper = await _db.Keepers.FindAsync(keeperId);
        if (keeper != null)
        {
            keeper.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }
    }

    public async Task<Guid> RegisterShopAsync(Guid keeperId, RegisterShopDto dto)
    {
        var shop = new Shop 
        { 
            ShopId = Guid.NewGuid(), 
            KeeperId = keeperId, 
            Name = dto.Name ?? "New Shop",
            Address = dto.Address,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            CategoryId = dto.CategoryId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            Tags = new List<string>()
        };
        _db.Shops.Add(shop);
        await _db.SaveChangesAsync();
        return shop.ShopId;
    }

    public async Task<List<ShopSummaryDto>> GetMyShopsAsync(Guid keeperId)
    {
        return await _db.Shops
            .Include(s => s.Category)
            .Where(s => s.KeeperId == keeperId)
            .Select(s => new ShopSummaryDto
            {
                Id = s.ShopId,
                Name = s.Name,
                BusinessName = "N/A",
                Location = s.Address ?? "Unknown",
                Category = s.Category != null ? s.Category.Name : "Uncategorized",
                Status = s.IsActive ? "Active" : "Inactive",
                IsVerified = s.IsVerified
            })
            .ToListAsync();
    }

    public async Task SyncWithGoogleBusinessAsync(Guid shopId) 
    {
        var shop = await _db.Shops.FindAsync(shopId);
        if (shop != null)
        {
            shop.IsVerified = true;
            await _db.SaveChangesAsync();
        }
    }
}

public class KeeperOfferService : IKeeperOfferService
{
    private readonly AppDbContext _db;
    private readonly IFirestoreService _firestore;
    public KeeperOfferService(AppDbContext db, IFirestoreService firestore) 
    { 
        _db = db; 
        _firestore = firestore; 
    }

    public async Task<List<KeeperOfferDetailDto>> GetMyOffersAsync(Guid keeperId)
    {
        var offers = await _db.Offers.Where(o => o.KeeperId == keeperId).ToListAsync();
        return offers.Select(o => new KeeperOfferDetailDto 
        { 
            OfferId = o.OfferId, 
            Title = o.Title,
            Status = o.Status,
            RedemptionCount = o.CurrentRedemptions,
            CreatedAt = o.CreatedAt
        }).ToList();
    }

    public async Task<Guid> CreateOfferAsync(Guid keeperId, CreateOfferDto dto)
    {
        var offerId = Guid.NewGuid();
        var offer = new Offer 
        { 
            OfferId = offerId, 
            KeeperId = keeperId, 
            ShopId = dto.ShopId,
            Title = dto.Title,
            Description = dto.Description,
            DiscountPercentage = dto.DiscountPercentage,
            DiscountAmount = dto.DiscountAmount,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            TermsAndConditions = dto.TermsAndConditions,
            Status = OfferStatus.Active
        };
        _db.Offers.Add(offer);
        await _db.SaveChangesAsync();
        await _firestore.SyncOfferAsync(offer);
        return offerId;
    }

    public async Task<KeeperOfferDetailDto> GetOfferDetailAsync(Guid keeperId, Guid offerId)
    {
        var o = await _db.Offers.FindAsync(offerId);
        if (o == null) return null!;
        if (o.KeeperId != keeperId) throw new UnauthorizedAccessException("Offer straight up doesn't belong to you.");
        return new KeeperOfferDetailDto 
        { 
            OfferId = o.OfferId, 
            Title = o.Title,
            Status = o.Status,
            RedemptionCount = o.CurrentRedemptions,
            CreatedAt = o.CreatedAt
        };
    }

    public async Task UpdateOfferAsync(Guid keeperId, Guid offerId, CreateOfferDto dto)
    {
        var offer = await _db.Offers.FindAsync(offerId);
        if (offer != null)
        {
            if (offer.KeeperId != keeperId) throw new UnauthorizedAccessException("Cannot update other keeper's offer.");
            offer.Title = dto.Title;
            offer.Description = dto.Description;
            offer.DiscountPercentage = dto.DiscountPercentage;
            offer.DiscountAmount = dto.DiscountAmount;
            offer.StartDate = dto.StartDate;
            offer.EndDate = dto.EndDate;
            offer.TermsAndConditions = dto.TermsAndConditions;
            offer.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            await _firestore.SyncOfferAsync(offer);
        }
    }

    public async Task DeleteOfferAsync(Guid keeperId, Guid offerId)
    {
        var offer = await _db.Offers.FindAsync(offerId);
        if (offer != null)
        {
            if (offer.KeeperId != keeperId) throw new UnauthorizedAccessException("Cannot delete other keeper's offer.");
            _db.Offers.Remove(offer);
            await _db.SaveChangesAsync();
            await _firestore.DeleteOfferAsync(offerId.ToString());
        }
    }

    public async Task BulkUploadOffersAsync(Guid keeperId, Stream csvStream)
    {
        using var reader = new StreamReader(csvStream);
        var csv = await reader.ReadToEndAsync();
        var lines = csv.Split('\n').Skip(1); // Skip header

        foreach (var line in lines)
        {
            if (string.IsNullOrWhiteSpace(line)) continue;
            var parts = line.Split(',');
            if (parts.Length < 7) continue;

            try
            {
                var offer = new Offer
                {
                    OfferId = Guid.NewGuid(),
                    KeeperId = keeperId,
                    ShopId = Guid.Parse(parts[6].Trim()),
                    Title = parts[0].Trim(),
                    Description = parts[1].Trim(),
                    DiscountPercentage = decimal.TryParse(parts[2].Trim(), out var dp) ? dp : null,
                    DiscountAmount = decimal.TryParse(parts[3].Trim(), out var da) ? da : null,
                    StartDate = DateTime.TryParse(parts[4].Trim(), out var sd) ? sd : DateTime.UtcNow,
                    EndDate = DateTime.TryParse(parts[5].Trim(), out var ed) ? ed : DateTime.UtcNow.AddMonths(1),
                    Status = OfferStatus.Active
                };
                _db.Offers.Add(offer);
                await _firestore.SyncOfferAsync(offer);
            }
            catch { /* skip invalid lines */ }
        }
        await _db.SaveChangesAsync();
    }
}

public class KeeperDashboardService : IKeeperDashboardService
{
    private readonly AppDbContext _db;
    public KeeperDashboardService(AppDbContext db) => _db = db;

    public async Task<KeeperDashboardDto> GetDashboardAsync(Guid keeperId)
    {
        var activeOffersCount = await _db.Offers.CountAsync(o => o.KeeperId == keeperId && o.Status == OfferStatus.Active);
        var totalRedemptions = await _db.Redemptions.CountAsync(r => _db.Offers.Any(o => o.OfferId == r.OfferId && o.KeeperId == keeperId));
        var totalSalesValue = await _db.Redemptions
            .Include(r => r.Offer)
            .Where(r => _db.Offers.Any(o => o.OfferId == r.OfferId && o.KeeperId == keeperId))
            .SumAsync(r => r.SavedAmount ?? r.Offer!.DiscountAmount ?? 0);
        var trendStart = DateTime.UtcNow.Date.AddDays(-6);
        var trend = await _db.Redemptions
            .Where(r => r.RedeemedAt >= trendStart && _db.Offers.Any(o => o.OfferId == r.OfferId && o.KeeperId == keeperId))
            .GroupBy(r => r.RedeemedAt.Date)
            .Select(group => new RedemptionTrendDto
            {
                Date = group.Key,
                Count = group.Count()
            })
            .ToListAsync();
        
        return new KeeperDashboardDto 
        { 
            ActiveOffersCount = activeOffersCount,
            TotalRedemptions = totalRedemptions,
            TotalSalesValue = totalSalesValue,
            RedemptionTrend = trend.OrderBy(item => item.Date).ToList()
        };
    }

    public async Task<KeeperTrafficDto> GetTrafficAnalyticsAsync(Guid shopId)
    {
        var shop = await _db.Shops.AsNoTracking().FirstOrDefaultAsync(item => item.ShopId == shopId)
            ?? throw new KeyNotFoundException($"Shop {shopId} not found.");
        if (!shop.Latitude.HasValue || !shop.Longitude.HasValue)
        {
            return new KeeperTrafficDto();
        }

        var radiusKm = shop.NotificationRadius.GetValueOrDefault(2);
        var oneHourAgo = DateTime.UtcNow.AddHours(-1);
        var currentViewers = await _db.Users
            .AsNoTracking()
            .Where(user => user.IsActive &&
                           user.LastLatitude.HasValue &&
                           user.LastLongitude.HasValue &&
                           user.LastLoginAt.HasValue &&
                           user.LastLoginAt.Value >= oneHourAgo)
            .ToListAsync();

        var nearbyViewerCount = currentViewers.Count(user =>
            GeoHelper.CalculateDistanceKm(
                shop.Latitude.Value,
                shop.Longitude.Value,
                user.LastLatitude!.Value,
                user.LastLongitude!.Value) <= radiusKm);

        var since = DateTime.UtcNow.AddDays(-14);
        var journeys = await _db.Journeys
            .AsNoTracking()
            .Where(journey => journey.StartTime >= since &&
                              journey.EndLat.HasValue &&
                              journey.EndLng.HasValue)
            .ToListAsync();

        var predictedTraffic = journeys
            .Where(journey => GeoHelper.CalculateDistanceKm(
                shop.Latitude.Value,
                shop.Longitude.Value,
                journey.EndLat!.Value,
                journey.EndLng!.Value) <= radiusKm)
            .GroupBy(journey => journey.StartTime.Hour)
            .Select(group => new HourlyTrafficDto
            {
                Hour = group.Key,
                PredictedCount = group.Count()
            })
            .OrderBy(item => item.Hour)
            .ToList();

        return new KeeperTrafficDto
        {
            CurrentViewersNearShop = nearbyViewerCount,
            PredictedTraffic = predictedTraffic
        };
    }

    public async Task<KeeperAnalyticsDto> GetAnalyticsAsync(Guid keeperId)
    {
        var shopIds = await _db.Shops
            .Where(shop => shop.KeeperId == keeperId)
            .Select(shop => new { shop.ShopId, shop.Name, shop.IsActive })
            .ToListAsync();
        var shopIdSet = shopIds.Select(item => item.ShopId).ToHashSet();

        var offers = await _db.Offers
            .Where(offer => offer.KeeperId == keeperId)
            .Select(offer => new { offer.OfferId, offer.ShopId, offer.Status })
            .ToListAsync();
        var offerIdSet = offers.Select(item => item.OfferId).ToHashSet();

        var redemptions = await _db.Redemptions
            .Where(redemption => offerIdSet.Contains(redemption.OfferId))
            .Select(redemption => new { redemption.OfferId, redemption.ShopId, redemption.SavedAmount, redemption.RedeemedAt })
            .ToListAsync();

        var trendStart = DateTime.UtcNow.Date.AddDays(-29);
        var trend = redemptions
            .Where(item => item.RedeemedAt.Date >= trendStart)
            .GroupBy(item => item.RedeemedAt.Date)
            .Select(group => new RedemptionTrendDto
            {
                Date = group.Key,
                Count = group.Count()
            })
            .OrderBy(item => item.Date)
            .ToList();

        var shopAnalytics = shopIds.Select(shop => new KeeperShopAnalyticsDto
        {
            ShopId = shop.ShopId,
            ShopName = shop.Name,
            OfferCount = offers.Count(offer => offer.ShopId == shop.ShopId),
            RedemptionCount = redemptions.Count(redemption => redemption.ShopId == shop.ShopId),
            Savings = redemptions.Where(redemption => redemption.ShopId == shop.ShopId).Sum(redemption => redemption.SavedAmount ?? 0)
        }).ToList();

        return new KeeperAnalyticsDto
        {
            TotalShops = shopIds.Count,
            ActiveShops = shopIds.Count(item => item.IsActive),
            TotalOffers = offers.Count,
            ActiveOffers = offers.Count(item => item.Status == OfferStatus.Active),
            TotalRedemptions = redemptions.Count,
            TotalSavings = redemptions.Sum(item => item.SavedAmount ?? 0),
            RedemptionTrend = trend,
            Shops = shopAnalytics
        };
    }
}
