using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class UserProfileService : IUserProfileService
{
    private readonly AppDbContext _db;
    public UserProfileService(AppDbContext db) => _db = db;

    public async Task<UserProfileDto> GetProfileAsync(Guid userId)
    {
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId);
        if (user == null) return null!;
        return new UserProfileDto 
        { 
            UserId = user.UserId, 
            FirstName = user.FirstName, 
            LastName = user.LastName, 
            Email = user.Email ?? "",
            ProfilePhotoUrl = user.ProfilePhotoUrl
        };
    }

    public async Task UpdateProfileAsync(Guid userId, UpdateUserProfileDto dto)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user != null)
        {
            user.FirstName = dto.FirstName ?? user.FirstName;
            user.LastName = dto.LastName ?? user.LastName;
            user.PhoneNumber = dto.PhoneNumber ?? user.PhoneNumber;
            user.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }
    }

    public async Task<string> UploadPhotoAsync(Guid userId, Stream photoStream, string fileName)
    {
        var photoUrl = $"/uploads/profiles/{userId}_{fileName}";
        var user = await _db.Users.FindAsync(userId);
        if (user != null)
        {
            user.ProfilePhotoUrl = photoUrl;
            await _db.SaveChangesAsync();
        }
        return photoUrl;
    }

    public async Task UpdateFcmTokenAsync(Guid userId, string token)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user != null)
        {
            user.FcmToken = token;
            await _db.SaveChangesAsync();
        }
    }

    public async Task<UserHomeDto> GetHomeDataAsync(double? lat, double? lng)
    {
        var trending = await _db.Offers
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Shop != null)
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .Select(o => new OfferSummaryDto
            {
                OfferId = o.OfferId,
                Title = o.Title,
                Description = o.Description,
                ShopName = o.Shop!.Name,
                Category = o.Category != null
                    ? o.Category.Name
                    : o.Shop.Category != null
                        ? o.Shop.Category.Name
                        : "General",
                Address = o.Shop.Address,
                Latitude = o.Shop.Latitude,
                Longitude = o.Shop.Longitude,
                ImageUrl = o.ImageUrl ?? o.Shop.ImageUrl,
                DiscountPercentage = o.DiscountPercentage,
                EndDate = o.EndDate,
            })
            .ToListAsync();

        var nearby = await _db.Shops
            .Include(s => s.Category)
            .Where(s => s.IsActive)
            .Take(5)
            .ToListAsync();

        var categories = await _db.Categories
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.Name)
            .Take(8)
            .Select(c => new CategorySummaryDto
            {
                CategoryId = c.CategoryId,
                Name = c.Name,
                Icon = c.Icon,
            })
            .ToListAsync();

        return new UserHomeDto 
        { 
            RecommendedOffers = trending,
            NearbyShops = nearby.Select(s => new NearbyShopDto { 
                ShopId = s.ShopId, 
                Name = s.Name, 
                Address = s.Address, 
                Latitude = s.Latitude, 
                Longitude = s.Longitude,
                DistanceKm = lat.HasValue && lng.HasValue && s.Latitude.HasValue && s.Longitude.HasValue
                    ? Math.Round(GeoHelper.CalculateDistanceKm(lat.Value, lng.Value, s.Latitude.Value, s.Longitude.Value), 2)
                    : 0,
                ImageUrl = s.ImageUrl,
            }).ToList(),
            Categories = categories,
        };
    }
}

public class RouteService : IRouteService
{
    private readonly AppDbContext _db;
    public RouteService(AppDbContext db) => _db = db;

    public async Task<RouteResponseDto> CalculateRouteAsync(Guid userId, RouteCalculateRequestDto dto)
    {
        var route = new RouteRecord
        {
            UserId = userId,
            StartLatitude = dto.OriginLat,
            StartLongitude = dto.OriginLng,
            EndLatitude = dto.DestinationLat,
            EndLongitude = dto.DestinationLng,
            Status = Models.Enums.RouteStatus.Active
        };
        _db.Routes.Add(route);
        await _db.SaveChangesAsync();
        return new RouteResponseDto { RouteId = route.RouteId };
    }

    public async Task<List<OfferSummaryDto>> GetOffersAlongRouteAsync(Guid routeId)
    {
        return await _db.Offers
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Shop != null)
            .Take(100)
            .Select(o => new OfferSummaryDto
            {
                OfferId = o.OfferId,
                ShopId = o.ShopId,
                Title = o.Title,
                Description = o.Description,
                ShopName = o.Shop!.Name,
                Category = o.Category != null
                    ? o.Category.Name
                    : o.Shop.Category != null
                        ? o.Shop.Category.Name
                        : "General",
                Address = o.Shop.Address,
                Latitude = o.Shop.Latitude,
                Longitude = o.Shop.Longitude,
                ImageUrl = o.ImageUrl ?? o.Shop.ImageUrl,
                DiscountPercentage = o.DiscountPercentage,
                EndDate = o.EndDate,
            })
            .ToListAsync();
    }

    public async Task<RouteResponseDto> OptimizeRouteAsync(Guid routeId)
    {
        var route = await _db.Routes.FindAsync(routeId);
        return new RouteResponseDto { RouteId = route?.RouteId ?? routeId };
    }

    public async Task<RouteResponseDto?> GetActiveRouteAsync(Guid userId)
    {
        var route = await _db.Routes.OrderByDescending(r => r.CreatedAt)
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Status == Models.Enums.RouteStatus.Active);
        
        if (route == null) return null;
        return new RouteResponseDto { RouteId = route.RouteId };
    }

    public async Task<List<RouteResponseDto>> GetRouteHistoryAsync(Guid userId)
    {
        return await _db.Routes.Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new RouteResponseDto { RouteId = r.RouteId })
            .ToListAsync();
    }
}

public class UserOfferService : IOfferService
{
    private readonly AppDbContext _db;
    public UserOfferService(AppDbContext db) => _db = db;

    public async Task<List<OfferSummaryDto>> GetNearbyOffersAsync(double lat, double lng)
    {
        return await _db.Offers
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive &&
                   o.Shop != null &&
                   o.Shop.Latitude >= lat - 0.2 && o.Shop.Latitude <= lat + 0.2 &&
                   o.Shop.Longitude >= lng - 0.2 && o.Shop.Longitude <= lng + 0.2)
            .OrderBy(o => (o.Shop!.Latitude - lat) * (o.Shop.Latitude - lat) + (o.Shop.Longitude - lng) * (o.Shop.Longitude - lng))
            .Take(50)
            .Select(o => new OfferSummaryDto
            {
                OfferId = o.OfferId,
                ShopId = o.ShopId,
                Title = o.Title,
                Description = o.Description,
                ShopName = o.Shop!.Name,
                Category = o.Category != null
                    ? o.Category.Name
                    : o.Shop.Category != null
                        ? o.Shop.Category.Name
                        : "General",
                Address = o.Shop.Address,
                Latitude = o.Shop.Latitude,
                Longitude = o.Shop.Longitude,
                ImageUrl = o.ImageUrl ?? o.Shop.ImageUrl,
                DiscountPercentage = o.DiscountPercentage,
                EndDate = o.EndDate,
            })
            .ToListAsync();
    }

    public async Task<OfferDetailDto> GetOfferDetailAsync(Guid offerId, Guid userId)
    {
        var offer = await _db.Offers
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .FirstOrDefaultAsync(o => o.OfferId == offerId);
        if (offer == null) throw new KeyNotFoundException($"Offer {offerId} not found.");
        return new OfferDetailDto
        {
            OfferId = offer.OfferId,
            Title = offer.Title,
            Description = offer.Description ?? string.Empty,
            ShopName = offer.Shop?.Name ?? "Unknown Shop",
            Category = offer.Category?.Name ?? offer.Shop?.Category?.Name ?? "General",
            ShopAddress = offer.Shop?.Address,
            Latitude = offer.Shop?.Latitude,
            Longitude = offer.Shop?.Longitude,
            ImageUrl = offer.ImageUrl ?? offer.Shop?.ImageUrl,
            TermsAndConditions = offer.TermsAndConditions,
            DiscountPercentage = offer.DiscountPercentage,
            EndDate = offer.EndDate,
        };
    }

    public async Task<Guid> RedeemOfferAsync(Guid offerId, Guid userId)
    {
        var offer = await _db.Offers.FindAsync(offerId)
            ?? throw new KeyNotFoundException($"Offer {offerId} not found.");
        var redemption = new Redemption 
        { 
            UserId = userId, 
            OfferId = offerId, 
            ShopId = offer.ShopId,
            RedeemedAt = DateTime.UtcNow,
            Status = Models.Enums.RedemptionStatus.Redeemed
        };
        _db.Redemptions.Add(redemption);
        await _db.SaveChangesAsync();
        return redemption.RedemptionId;
    }

    public async Task SaveOfferAsync(Guid offerId, Guid userId)
    {
        var fav = new Favourite { UserId = userId, OfferId = offerId, Type = "offer" };
        _db.Favourites.Add(fav);
        await _db.SaveChangesAsync();
    }

    public async Task RateOfferAsync(Guid offerId, Guid userId, int rating, string? comment)
    {
        var review = new Review
        {
            UserId = userId,
            OfferId = offerId,
            Rating = rating,
            Comment = comment,
            Status = Models.Enums.ReviewStatus.Published
        };
        _db.Reviews.Add(review);
        await _db.SaveChangesAsync();
    }
}

public class UserHistoryService : IUserHistoryService
{
    private readonly AppDbContext _db;
    public UserHistoryService(AppDbContext db) => _db = db;

    public async Task<List<RedemptionHistoryDto>> GetRedemptionHistoryAsync(Guid userId)
    {
        return await _db.Redemptions.Include(r => r.Offer)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.RedeemedAt)
            .Select(r => new RedemptionHistoryDto { RedemptionId = r.RedemptionId, OfferTitle = r.Offer != null ? r.Offer.Title : "Unknown Offer" })
            .ToListAsync();
    }

    public async Task<LoyaltySummaryDto> GetLoyaltyWalletAsync(Guid userId)
    {
        var wallet = await _db.LoyaltyWallets.FirstOrDefaultAsync(w => w.UserId == userId);
        var tier = wallet?.Tier ?? "Bronze";
        var currentPoints = wallet?.CurrentPoints ?? 0;
        var nextTierThreshold = tier switch
        {
            "Bronze" => 100,
            "Silver" => 250,
            "Gold" => 500,
            _ => currentPoints
        };

        return new LoyaltySummaryDto
        {
            CurrentPoints = currentPoints,
            Tier = tier,
            PointsToNextTier = Math.Max(0, nextTierThreshold - currentPoints)
        };
    }

    public async Task<UserSavingsSummaryDto> GetSavingsSummaryAsync(Guid userId)
    {
        var userRedemptions = _db.Redemptions.Include(r => r.Offer)
            .Where(r => r.UserId == userId && r.Offer != null);

        return new UserSavingsSummaryDto
        {
            TotalSaved = await userRedemptions.SumAsync(r => r.SavedAmount ?? r.Offer!.DiscountAmount ?? 0),
            TotalRedemptions = await userRedemptions.CountAsync()
        };
    }
}

public class FavouriteService : IFavouriteService
{
    private readonly AppDbContext _db;
    public FavouriteService(AppDbContext db) => _db = db;

    public async Task<List<object>> GetFavouritesAsync(Guid userId)
    {
        return await _db.Favourites.Where(f => f.UserId == userId).ToListAsync<object>();
    }

    public async Task ToggleFavouriteAsync(Guid userId, ToggleFavouriteDto dto)
    {
        var fav = await _db.Favourites.FirstOrDefaultAsync(f => f.UserId == userId && (f.ShopId == dto.ShopId || f.OfferId == dto.OfferId));
        if (fav != null) _db.Favourites.Remove(fav);
        else _db.Favourites.Add(new Favourite { UserId = userId, ShopId = dto.ShopId, OfferId = dto.OfferId, Type = dto.ShopId.HasValue ? "shop" : "offer" });
        await _db.SaveChangesAsync();
    }
}

public class ChatService : IChatService
{
    private readonly AppDbContext _db;

    public ChatService(AppDbContext db) => _db = db;

    public async Task<ChatThreadDto> StartChatAsync(Guid userId, Guid keeperId)
    {
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(item => item.UserId == userId)
            ?? throw new KeyNotFoundException($"User {userId} not found.");
        var keeper = await _db.Keepers.AsNoTracking().FirstOrDefaultAsync(item => item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        var thread = await _db.ChatThreads
            .Include(item => item.Messages)
            .FirstOrDefaultAsync(item => item.UserId == user.UserId && item.KeeperId == keeper.KeeperId);

        if (thread == null)
        {
            thread = new ChatThread
            {
                UserId = user.UserId,
                KeeperId = keeper.KeeperId,
                Status = "active",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                LastMessageAt = DateTime.UtcNow
            };

            _db.ChatThreads.Add(thread);
            _db.ChatMessages.Add(new ChatMessage
            {
                Thread = thread,
                SenderType = "system",
                Message = "Chat thread created.",
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();
            thread = await _db.ChatThreads.Include(item => item.Messages)
                .FirstAsync(item => item.ThreadId == thread.ThreadId);
        }

        return new ChatThreadDto
        {
            ThreadId = thread.ThreadId,
            UserId = thread.UserId,
            KeeperId = thread.KeeperId,
            Status = thread.Status,
            CreatedAt = thread.CreatedAt,
            UpdatedAt = thread.UpdatedAt,
            LastMessageAt = thread.LastMessageAt,
            MessageCount = thread.Messages.Count
        };
    }
}
