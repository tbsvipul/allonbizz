using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.DTOs.Public;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Services;

public class PlatformFeatureService : IReviewService, ILoyaltyService, IAdminPanelService, IRuleService, IPlacesService
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

    public async Task<LoyaltyProgramDto> GetLoyaltyProgramAsync(Guid keeperId, Guid shopId)
    {
        _ = await _db.Shops
            .AsNoTracking()
            .FirstOrDefaultAsync(shop => shop.ShopId == shopId && shop.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Shop {shopId} not found.");

        var program = await _db.ShopLoyaltyPrograms.AsNoTracking()
            .FirstOrDefaultAsync(item => item.ShopId == shopId);

        return new LoyaltyProgramDto
        {
            ShopId = shopId,
            Configured = program != null,
            IsEnabled = program?.IsEnabled ?? false,
            ProgramName = program?.ProgramName,
            PointsPerRedemption = program?.PointsPerRedemption ?? 0,
            MinimumPointsToRedeem = program?.MinimumPointsToRedeem ?? 0,
            RewardDescription = program?.RewardDescription,
            TermsAndConditions = program?.TermsAndConditions,
            UpdatedAt = program?.UpdatedAt
        };
    }

    public async Task<LoyaltyProgramDto> ManageLoyaltyProgramAsync(Guid keeperId, UpdateLoyaltyProgramDto dto)
    {
        _ = await _db.Shops
            .AsNoTracking()
            .FirstOrDefaultAsync(shop => shop.ShopId == dto.ShopId && shop.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Shop {dto.ShopId} not found.");

        var program = await _db.ShopLoyaltyPrograms
            .FirstOrDefaultAsync(item => item.ShopId == dto.ShopId);

        if (program == null)
        {
            program = new ShopLoyaltyProgram
            {
                ShopId = dto.ShopId,
                CreatedAt = DateTime.UtcNow
            };

            _db.ShopLoyaltyPrograms.Add(program);
        }

        program.IsEnabled = dto.IsEnabled;
        program.ProgramName = string.IsNullOrWhiteSpace(dto.ProgramName) ? null : dto.ProgramName.Trim();
        program.PointsPerRedemption = dto.PointsPerRedemption;
        program.MinimumPointsToRedeem = dto.MinimumPointsToRedeem;
        program.RewardDescription = string.IsNullOrWhiteSpace(dto.RewardDescription) ? null : dto.RewardDescription.Trim();
        program.TermsAndConditions = string.IsNullOrWhiteSpace(dto.TermsAndConditions) ? null : dto.TermsAndConditions.Trim();
        program.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return await GetLoyaltyProgramAsync(keeperId, dto.ShopId);
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
        var totalSavings = await _db.Redemptions.SumAsync(r => r.SavedAmount ?? 0);
        var totalRedemptions = await _db.Redemptions.CountAsync();

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
                RedemptionsCount = 0,
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
            TotalRedemptions = totalRedemptions,
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
            .Where(s => s.Name.ToLower().Contains(normalizedQuery) || (s.Address != null && s.Address.ToLower().Contains(normalizedQuery)))
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
            .OrderByDescending(o => o.CurrentRedemptions)
            .Select(o => new TrendingOfferDto 
            { 
                OfferId = o.OfferId, 
                Title = o.Title, 
                ShopName = o.Shop != null ? o.Shop.Name : "Unknown",
                PopularityScore = o.CurrentRedemptions
            })
            .Take(10)
            .ToListAsync();
    }
}
