using routent.AdminAPI.Services.Interfaces;
using routent.AdminAPI.DTOs.Public;
using routent.AdminAPI.DTOs.Admin;
using routent.AdminAPI.DTOs.Keepers;
using routent.AdminAPI.DTOs.Users;
using routent.AdminAPI.DTOs.Common;
using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Constants;
using routent.AdminAPI.Data;
using routent.AdminAPI.Helpers;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Models.Enums;

namespace routent.AdminAPI.Services;

public class PlatformFeatureService : IReviewService, IAdminPanelService, IRuleService, IPlacesService
{
    private readonly AppDbContext _db;
    public PlatformFeatureService(AppDbContext db) => _db = db;

    public async Task<PagedResponse<ReviewDto>> GetReviewsAsync(
        Guid? shopId,
        Guid? offerId,
        PaginationParams paging,
        bool publishedOnly = false,
        Guid? keeperId = null)
    {
        var query = _db.Reviews
            .Include(r => r.User)
            .Include(r => r.Shop)
            .Include(r => r.Offer)
            .AsNoTracking();

        if (keeperId.HasValue)
        {
            query = query.Where(review =>
                (review.ShopId.HasValue && review.Shop != null && review.Shop.KeeperId == keeperId.Value) ||
                (review.OfferId.HasValue && review.Offer != null && review.Offer.KeeperId == keeperId.Value));
        }

        if (shopId.HasValue) query = query.Where(r => r.ShopId == shopId.Value);
        if (offerId.HasValue) query = query.Where(r => r.OfferId == offerId.Value);
        if (publishedOnly) query = query.Where(r => r.Status == ReviewStatus.Published);

        var totalCount = await query.CountAsync();
        var reviews = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .Select(r => new ReviewDto
            {
                ReviewId = r.ReviewId,
                UserId = r.UserId,
                UserFullName = r.User != null ? $"{r.User.FirstName} {r.User.LastName}" : "Unknown",
                UserAvatarUrl = r.User != null ? r.User.ProfilePhotoData : null,
                ShopId = r.ShopId,
                ShopName = r.Shop != null ? r.Shop.Name : "Unknown",
                OfferId = r.OfferId,
                OfferTitle = r.Offer != null ? r.Offer.Title : null,
                Rating = r.Rating,
                Comment = r.Comment,
                Reply = r.Reply,
                RepliedAt = r.RepliedAt,
                CreatedAt = r.CreatedAt,
                Status = r.Status.ToString()
            })
            .ToListAsync();

        return new PagedResponse<ReviewDto>
        {
            Data = reviews,
            Pagination = new PaginationMeta { Page = paging.PageNumber, PageSize = paging.PageSize, TotalCount = totalCount }
        };
    }
    public async Task ReplyToReviewAsync(Guid reviewId, ReviewReplyDto dto, Guid? keeperId = null)
    {
        var review = await _db.Reviews
            .Include(item => item.Shop)
            .Include(item => item.Offer)
            .FirstOrDefaultAsync(item => item.ReviewId == reviewId)
            ?? throw new KeyNotFoundException($"Review {reviewId} not found.");

        if (keeperId.HasValue)
        {
            var reviewKeeperId = review.Shop?.KeeperId ?? review.Offer?.KeeperId;
            if (reviewKeeperId != keeperId.Value)
            {
                throw new KeyNotFoundException($"Review {reviewId} not found.");
            }
        }

        review.Reply = dto.Reply.Trim();
        review.RepliedAt = DateTime.UtcNow;
        review.Status = ReviewStatus.Published;
        await _db.SaveChangesAsync();
    }

    public async Task SubmitReviewAsync(Guid userId, SubmitReviewDto dto)
    {
        var review = new Review
        {
            UserId = userId,
            ShopId = dto.ShopId,
            OfferId = dto.OfferId,
            Rating = dto.Rating,
            Comment = dto.Comment,
            Status = ReviewStatus.Published
        };
        _db.Reviews.Add(review);
        await _db.SaveChangesAsync();
    }

    public async Task<ReviewStatsDto> GetReviewStatsAsync(Guid? shopId = null, Guid? keeperId = null)
    {
        var query = _db.Reviews.AsNoTracking().Where(r => r.Status == ReviewStatus.Published);

        if (keeperId.HasValue)
        {
            query = query.Where(review =>
                (review.ShopId.HasValue && review.Shop != null && review.Shop.KeeperId == keeperId.Value) ||
                (review.OfferId.HasValue && review.Offer != null && review.Offer.KeeperId == keeperId.Value));
        }

        if (shopId.HasValue)
        {
            query = query.Where(r => r.ShopId == shopId.Value);
        }

        var totalReviews = await query.CountAsync();
        var averageRating = totalReviews > 0 ? await query.AverageAsync(r => r.Rating) : 0;

        return new ReviewStatsDto
        {
            TotalReviews = totalReviews,
            AverageRating = Math.Round(averageRating, 1)
        };
    }

    public async Task<List<ShopStatsDto>> GetShopsReviewStatsAsync(Guid? keeperId = null)
    {
        var query = _db.Reviews
            .Include(r => r.Shop)
            .AsNoTracking()
            .Where(r => r.Status == ReviewStatus.Published && r.ShopId != null);
            
        if (keeperId.HasValue)
        {
            query = query.Where(r => r.Shop != null && r.Shop.KeeperId == keeperId.Value);
        }

        var stats = await query
            .GroupBy(r => new { ShopId = r.ShopId!.Value, ShopName = r.Shop!.Name })
            .Select(g => new ShopStatsDto
            {
                ShopId = g.Key.ShopId,
                ShopName = g.Key.ShopName,
                AverageRating = Math.Round(g.Average(r => r.Rating), 1),
                TotalReviews = g.Count()
            })
            .ToListAsync();
            
        return stats;
    }



    public async Task<AdminDashboardSummaryDto> GetDashboardSummaryAsync()
    {
        var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);

        // Core counts
        var totalUsers = await _db.Users.CountAsync();
        var activeUsers = await _db.Users.CountAsync(u => u.IsActive);
        var totalKeepers = await _db.Keepers.CountAsync();
        var totalShops = await _db.Shops.CountAsync();
        var activeShops = await _db.Shops.CountAsync(s => s.IsActive);
        var totalOffers = await _db.Offers.CountAsync();
        var activeOffers = await _db.Offers.CountAsync(o => o.IsActive);
        var totalJourneys = await _db.Journeys.CountAsync();
        var totalCategories = await _db.Categories.CountAsync();

        // Pending items
        var pendingKeepers = await _db.Keepers.CountAsync(k => k.Status == KeeperStatus.PendingApproval);
        var pendingShops = await _db.Shops.CountAsync(s => !s.IsVerified);
        var pendingOffers = await _db.Offers.CountAsync(o => o.Status == OfferStatus.Pending);
        var pendingModeration = await _db.ModerationQueueItems.CountAsync(m => m.Status == "pending");

        // Revenue
        var totalSavings = 0m;

        // Growth (last 30 days)
        var newUsersLast30 = await _db.Users.CountAsync(u => u.CreatedAt >= thirtyDaysAgo);
        var newShopsLast30 = await _db.Shops.CountAsync(s => s.CreatedAt >= thirtyDaysAgo);
        var newOffersLast30 = await _db.Offers.CountAsync(o => o.CreatedAt >= thirtyDaysAgo);
        var journeysLast30 = await _db.Journeys.CountAsync(j => j.StartTime >= thirtyDaysAgo);

        // Recent activity feed (last 10 events from multiple sources)
        var recentActivity = new List<RecentActivityDto>();

        var recentUsers = await _db.Users.OrderByDescending(u => u.CreatedAt).Take(3)
            .Select(u => new RecentActivityDto { Type = "user_registered", Description = $"{u.FirstName} {u.LastName} registered", Timestamp = u.CreatedAt }).ToListAsync();
        recentActivity.AddRange(recentUsers);

        var recentShops = await _db.Shops.Include(s => s.Keeper).OrderByDescending(s => s.CreatedAt).Take(3)
            .Select(s => new RecentActivityDto { Type = "shop_created", Description = $"Shop \"{s.Name}\" was created", Timestamp = s.CreatedAt }).ToListAsync();
        recentActivity.AddRange(recentShops);

        var recentKeepers = await _db.Keepers.Include(k => k.User).Where(k => k.Status == KeeperStatus.PendingApproval).OrderByDescending(k => k.CreatedAt).Take(2)
            .Select(k => new RecentActivityDto { Type = "keeper_applied", Description = $"New keeper application: {k.BusinessName}", Timestamp = k.CreatedAt }).ToListAsync();
        recentActivity.AddRange(recentKeepers);

        var recentJourneys = await _db.Journeys.Include(j => j.User).Where(j => j.EndTime != null).OrderByDescending(j => j.EndTime).Take(2)
            .Select(j => new RecentActivityDto { Type = "journey_completed", Description = $"Journey completed by {(j.User != null ? j.User.FirstName : "User")}", Timestamp = j.EndTime ?? j.StartTime }).ToListAsync();
        recentActivity.AddRange(recentJourneys);

        recentActivity = recentActivity.OrderByDescending(a => a.Timestamp).Take(10).ToList();

        // Top shops by offer count
        var topShops = await _db.Shops.Include(s => s.Category).Include(s => s.Offers)
            .OrderByDescending(s => s.Offers.Count)
            .Take(5)
            .Select(s => new TopShopDto
            {
                ShopId = s.ShopId,
                Name = s.Name,
                Category = s.Category != null ? s.Category.Name : "Uncategorized",
                OffersCount = s.Offers.Count,
                IsActive = s.IsActive
            }).ToListAsync();

        return new AdminDashboardSummaryDto
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            TotalKeepers = totalKeepers,
            TotalShops = totalShops,
            ActiveShops = activeShops,
            TotalOffers = totalOffers,
            ActiveOffers = activeOffers,
            TotalJourneys = totalJourneys,
            TotalCategories = totalCategories,
            PendingKeepers = pendingKeepers,
            PendingShops = pendingShops,
            PendingOffers = pendingOffers,
            PendingModeration = pendingModeration,
            TotalPlatformSavings = totalSavings,
            NewUsersLast30Days = newUsersLast30,
            NewShopsLast30Days = newShopsLast30,
            NewOffersLast30Days = newOffersLast30,
            JourneysLast30Days = journeysLast30,
            RecentActivity = recentActivity,
            TopShops = topShops
        };
    }
    public async Task<PagedResponse<JourneyHistoryDto>> GetJourneysAsync(PaginationParams paging)
    {
        var query = _db.Journeys.Include(j => j.User).AsNoTracking();
        var totalCount = await query.CountAsync();
        var journeys = await query
            .OrderByDescending(j => j.StartTime)
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .Select(j => new JourneyHistoryDto
            {
                JourneyId = j.JourneyId,
                UserId = j.UserId,
                UserEmail = j.User != null ? j.User.Email ?? "" : "",
                Type = j.Type,
                StartName = j.StartName,
                StartLat = j.StartLat,
                StartLng = j.StartLng,
                EndName = j.EndName,
                EndLat = j.EndLat,
                EndLng = j.EndLng,
                StartTime = j.StartTime,
                EndTime = j.EndTime,
                Distance = j.Distance,
                Duration = j.Duration,
                Tags = new List<string>(),
                ShopsEncountered = new List<string>()
            })
            .ToListAsync();

        return new PagedResponse<JourneyHistoryDto>
        {
            Data = journeys,
            Pagination = new PaginationMeta { Page = paging.PageNumber, PageSize = paging.PageSize, TotalCount = totalCount }
        };
    }
    public async Task SendPushNotificationAsync(PushNotificationRequestDto dto)
    {
        var targetAudience = NotificationAudienceHelper.Normalize(dto.TargetAudience);
        var recipientCount = targetAudience switch
        {
            "customers" => await _db.Users.CountAsync(user => user.Role == Roles.Customer && user.IsActive),
            "keepers" => await _db.Users.CountAsync(user => user.Role == Roles.Keeper && user.IsActive),
            _ => await _db.Users.CountAsync(user => user.IsActive)
        };

        _db.Notifications.Add(new Notification
        {
            Title = dto.Title,
            Message = dto.Message,
            Type = NotificationType.PromoAnnouncement,
            Priority = NotificationPriority.Normal,
            TargetAudience = targetAudience,
            Status = NotificationStatus.Queued,
            RecipientCount = recipientCount,
            ScheduledAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
    }

    public async Task<List<PlatformRuleDto>> GetRulesAsync()
    {
        return await _db.PlatformRules
            .AsNoTracking()
            .OrderBy(rule => rule.Group)
            .ThenBy(rule => rule.Key)
            .Select(rule => new PlatformRuleDto
            {
                RuleId = rule.RuleId,
                Key = rule.Key,
                Value = rule.Value,
                Group = rule.Group,
                Description = rule.Description,
                IsActive = rule.IsActive,
                CreatedAt = rule.CreatedAt,
                UpdatedAt = rule.UpdatedAt
            })
            .ToListAsync();
    }
    public async Task AddRuleAsync(CreateRuleDto dto)
    {
        _db.PlatformRules.Add(new PlatformRule 
        { 
            Key = dto.Key, 
            Value = dto.Value, 
            Group = dto.Group ?? "General",
            Description = dto.Description 
        });
        await _db.SaveChangesAsync();
    }

    public async Task<List<PlaceSearchResponseDto>> SearchPlacesAsync(string query)
    {
        var normalizedQuery = query.ToLower().Trim();
        return await _db.Shops
            .AsNoTracking()
            .Where(s => s.IsActive && s.IsVerified && (s.Name.ToLower().Contains(normalizedQuery) || (s.Address != null && s.Address.ToLower().Contains(normalizedQuery))))
            .Select(s => new PlaceSearchResponseDto 
            { 
                Name = s.Name, 
                Address = s.Address ?? "", 
                Latitude = s.Latitude ?? 0, 
                Longitude = s.Longitude ?? 0 
            })
            .ToListAsync();
    }

    public async Task<List<TrendingOfferDto>> GetTrendingOffersAsync()
    {
        return await _db.Offers
            .Include(o => o.Shop)
            .AsNoTracking()
            .Where(o => o.IsActive && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new TrendingOfferDto 
            { 
                OfferId = o.OfferId, 
                Title = o.Title, 
                ShopName = o.Shop != null ? o.Shop.Name : "Unknown",
                PopularityScore = 0
            })
            .Take(10)
            .ToListAsync();
    }
}
