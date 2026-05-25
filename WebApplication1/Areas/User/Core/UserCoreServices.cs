using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Text.Json;

namespace allonbiz.AdminAPI.Services;

public class UserProfileService : IUserProfileService
{
    private readonly AppDbContext _db;
    public UserProfileService(AppDbContext db) => _db = db;

    private sealed class UserSavingsRow
    {
        public decimal? SavedAmount { get; init; }
        public decimal? OfferDiscountAmount { get; init; }
    }

    private static decimal ResolveSavings(decimal? savedAmount, decimal? offerDiscountAmount)
    {
        return savedAmount ?? offerDiscountAmount ?? 0m;
    }

    private IQueryable<UserSavingsRow> BuildUserSavingsQuery(Guid userId)
    {
        return
            from redemption in _db.Redemptions.AsNoTracking()
            join offer in _db.Offers.AsNoTracking()
                on redemption.OfferId equals offer.OfferId into offerGroup
            from offer in offerGroup.DefaultIfEmpty()
            where redemption.UserId == userId
            select new UserSavingsRow
            {
                SavedAmount = redemption.SavedAmount,
                OfferDiscountAmount = offer != null ? offer.DiscountAmount : null
            };
    }

    private async Task<decimal> GetTotalSavedAsync(Guid userId)
    {
        var savingsRows = await BuildUserSavingsQuery(userId).ToListAsync();
        return savingsRows.Sum(item => ResolveSavings(item.SavedAmount, item.OfferDiscountAmount));
    }

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
            PhoneNumber = user.PhoneNumber ?? string.Empty,
            ProfilePhotoUrl = user.ProfilePhotoUrl,
            Role = user.Role
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

    public async Task<string> UploadPhotoAsync(Guid userId, Stream photoStream, string contentType)
    {
        using var memoryStream = new MemoryStream();
        await photoStream.CopyToAsync(memoryStream);

        var bytes = memoryStream.ToArray();
        var normalizedContentType = string.IsNullOrWhiteSpace(contentType) ? "application/octet-stream" : contentType.Trim();
        var photoUrl = $"data:{normalizedContentType};base64,{Convert.ToBase64String(bytes)}";
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

    public async Task<UserHomeDto> GetHomeDataAsync(Guid userId, double? lat, double? lng)
    {
        var trendingOffers = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified)
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .ToListAsync();

        var trending = trendingOffers.Select(o => new OfferSummaryDto
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
            ImageUrl = o.ImageUrl ?? ImageConversionHelper.ToBase64DataUrl(o.Shop.ImageUrl),
            DiscountPercentage = o.DiscountPercentage,
            EndDate = o.EndDate,
            Tags = o.Tags,
        }).ToList();

        List<Shop> nearby;
        if (lat.HasValue && lng.HasValue)
        {
            // Approximate bounding box for 10km radius
            double radiusKm = 10.0;
            double latOffset = radiusKm / 111.0;
            double lngOffset = radiusKm / (111.0 * Math.Cos(lat.Value * Math.PI / 180.0));
            
            var minLat = lat.Value - latOffset;
            var maxLat = lat.Value + latOffset;
            var minLng = lng.Value - lngOffset;
            var maxLng = lng.Value + lngOffset;

            nearby = await _db.Shops
                .AsNoTracking()
                .Include(s => s.Category)
                .Where(s => s.IsActive && s.IsVerified && s.Latitude.HasValue && s.Longitude.HasValue &&
                            s.Latitude.Value >= minLat && s.Latitude.Value <= maxLat &&
                            s.Longitude.Value >= minLng && s.Longitude.Value <= maxLng)
                .OrderBy(s => (s.Latitude!.Value - lat.Value) * (s.Latitude!.Value - lat.Value) + (s.Longitude!.Value - lng.Value) * (s.Longitude!.Value - lng.Value))
                .Take(5)
                .ToListAsync();
        }
        else
        {
            // Fallback if no location is provided
            nearby = await _db.Shops
                .AsNoTracking()
                .Include(s => s.Category)
                .Where(s => s.IsActive && s.IsVerified)
                .OrderByDescending(s => s.CreatedAt)
                .Take(5)
                .ToListAsync();
        }

        var categories = await _db.Categories
            .AsNoTracking()
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

        var totalTrips = await _db.Journeys
            .AsNoTracking()
            .CountAsync(j => j.UserId == userId);
        var totalSaved = await GetTotalSavedAsync(userId);
        var loyaltyPoints = await _db.LoyaltyWallets
            .AsNoTracking()
            .Where(wallet => wallet.UserId == userId)
            .Select(wallet => (int?)(wallet.TotalPoints - wallet.RedeemedPoints))
            .FirstOrDefaultAsync();
        var activeJourney = await _db.Journeys
            .AsNoTracking()
            .Where(j => j.UserId == userId && j.Status == "active")
            .OrderByDescending(j => j.StartTime)
            .Select(j => new { j.JourneyId, j.Type, Destination = j.EndName })
            .FirstOrDefaultAsync();

        return new UserHomeDto 
        { 
            Summary = new HomeSummaryDto
            {
                TotalTrips = totalTrips,
                TotalSaved = totalSaved,
                LoyaltyPoints = loyaltyPoints ?? 0,
                HasActiveJourney = activeJourney != null,
                ActiveJourneyId = activeJourney?.JourneyId,
                ActiveJourneyType = activeJourney?.Type,
                ActiveJourneyDestinationName = activeJourney?.Destination
            },
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
                ImageUrl = ImageConversionHelper.ToBase64DataUrl(s.ImageUrl),
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
        var offers = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified)
            .Take(100)
            .ToListAsync();

        return offers.Select(o => new OfferSummaryDto
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
            ImageUrl = o.ImageUrl ?? ImageConversionHelper.ToBase64DataUrl(o.Shop.ImageUrl),
            DiscountPercentage = o.DiscountPercentage,
            EndDate = o.EndDate,
        }).ToList();
    }

    public async Task<RouteResponseDto> OptimizeRouteAsync(Guid routeId)
    {
        var route = await _db.Routes.FindAsync(routeId);
        return new RouteResponseDto { RouteId = route?.RouteId ?? routeId };
    }

    public async Task<RouteResponseDto?> GetActiveRouteAsync(Guid userId)
    {
        var route = await _db.Routes
            .AsNoTracking()
            .OrderByDescending(r => r.CreatedAt)
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Status == Models.Enums.RouteStatus.Active);
        
        if (route == null) return null;
        return new RouteResponseDto { RouteId = route.RouteId };
    }

    public async Task<List<RouteResponseDto>> GetRouteHistoryAsync(Guid userId)
    {
        return await _db.Routes
            .AsNoTracking()
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new RouteResponseDto { RouteId = r.RouteId })
            .ToListAsync();
    }
}

public class UserOfferService : IOfferService
{
    private readonly AppDbContext _db;
    public UserOfferService(AppDbContext db) => _db = db;

    public async Task<List<OfferSummaryDto>> GetNearbyOffersAsync(double? lat, double? lng, double? radiusKm = null, string? category = null, IReadOnlyCollection<string>? tags = null)
    {
        var query = _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified);
            
        if (!string.IsNullOrEmpty(category))
        {
            var lowerCat = category.ToLower();
            query = query.Where(o => (o.Category != null && o.Category.Name.ToLower() == lowerCat) || 
                                     (o.Shop!.Category != null && o.Shop.Category.Name.ToLower() == lowerCat));
        }

        var effectiveRadiusKm = Math.Clamp(radiusKm ?? 10, 0.5, 25);

        if (lat.HasValue && lng.HasValue)
        {
            var latOffset = effectiveRadiusKm / 111.0;
            var lngOffset = effectiveRadiusKm / (111.0 * Math.Cos(lat.Value * Math.PI / 180.0));

            query = query.Where(o =>
                    o.Shop!.Latitude.HasValue &&
                    o.Shop.Longitude.HasValue &&
                    o.Shop.Latitude.Value >= lat.Value - latOffset &&
                    o.Shop.Latitude.Value <= lat.Value + latOffset &&
                    o.Shop.Longitude.Value >= lng.Value - lngOffset &&
                    o.Shop.Longitude.Value <= lng.Value + lngOffset)
            .OrderBy(o => (o.Shop!.Latitude - lat.Value) * (o.Shop.Latitude - lat.Value) + (o.Shop.Longitude - lng.Value) * (o.Shop.Longitude - lng.Value));
        }
        else
        {
            query = query.OrderByDescending(o => o.CreatedAt);
        }

        var candidates = await query
            .Take(200)
            .Select(o => new
            {
                Offer = o,
                Shop = o.Shop!,
                CategoryName = o.Category != null
                    ? o.Category.Name
                    : o.Shop!.Category != null
                        ? o.Shop.Category.Name
                        : "General"
            })
            .ToListAsync();

        var normalizedTags = tags?
            .Where(tag => !string.IsNullOrWhiteSpace(tag))
            .Select(tag => tag.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList() ?? new List<string>();

        var filtered = candidates.Where(candidate =>
        {
            if (lat.HasValue && lng.HasValue && candidate.Shop.Latitude.HasValue && candidate.Shop.Longitude.HasValue)
            {
                var distanceKm = GeoHelper.CalculateDistanceKm(lat.Value, lng.Value, candidate.Shop.Latitude.Value, candidate.Shop.Longitude.Value);
                if (distanceKm > effectiveRadiusKm)
                {
                    return false;
                }
            }

            if (normalizedTags.Count == 0)
            {
                return true;
            }

            var offerTags = candidate.Offer.Tags ?? new List<string>();
            var shopTags = candidate.Shop.Tags ?? new List<string>();
            return normalizedTags.Any(tag =>
                offerTags.Any(existing => existing.Equals(tag, StringComparison.OrdinalIgnoreCase)) ||
                shopTags.Any(existing => existing.Equals(tag, StringComparison.OrdinalIgnoreCase)) ||
                candidate.CategoryName.Equals(tag, StringComparison.OrdinalIgnoreCase));
        });

        return filtered
            .Take(50)
            .Select(candidate => new OfferSummaryDto
            {
                OfferId = candidate.Offer.OfferId,
                ShopId = candidate.Offer.ShopId,
                Title = candidate.Offer.Title,
                Description = candidate.Offer.Description,
                ShopName = candidate.Shop.Name,
                Category = candidate.CategoryName,
                Address = candidate.Shop.Address,
                Latitude = candidate.Shop.Latitude,
                Longitude = candidate.Shop.Longitude,
                ImageUrl = candidate.Offer.ImageUrl ?? ImageConversionHelper.ToBase64DataUrl(candidate.Shop.ImageUrl),
                DiscountPercentage = candidate.Offer.DiscountPercentage,
                EndDate = candidate.Offer.EndDate,
                Tags = candidate.Offer.Tags
            })
            .ToList();
    }

    public async Task<OfferDetailDto> GetOfferDetailAsync(Guid offerId, Guid userId)
    {
        var offer = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .FirstOrDefaultAsync(o => o.OfferId == offerId);
        if (offer == null || !offer.IsActive || offer.Shop == null || !offer.Shop.IsActive || !offer.Shop.IsVerified) throw new KeyNotFoundException($"Offer {offerId} not found.");
        return new OfferDetailDto
        {
            OfferId = offer.OfferId,
            ShopId = offer.ShopId,
            Title = offer.Title,
            Description = offer.Description ?? string.Empty,
            ShopName = offer.Shop?.Name ?? "Unknown Shop",
            Category = offer.Category?.Name ?? offer.Shop?.Category?.Name ?? "General",
            ShopAddress = offer.Shop?.Address,
            Latitude = offer.Shop?.Latitude,
            Longitude = offer.Shop?.Longitude,
            ImageUrl = offer.ImageUrl ?? ImageConversionHelper.ToBase64DataUrl(offer.Shop?.ImageUrl),
            TermsAndConditions = offer.TermsAndConditions,
            DiscountPercentage = offer.DiscountPercentage,
            MinOrderValue = offer.MinOrderValue,
            EndDate = offer.EndDate,
            IsSaved = await _db.Favourites.AnyAsync(f => f.UserId == userId && f.OfferId == offerId),
            Tags = offer.Tags,
        };
    }

    public async Task<Guid> RedeemOfferAsync(Guid offerId, Guid userId)
    {
        var offer = await _db.Offers
            .Include(item => item.Shop)
            .FirstOrDefaultAsync(item => item.OfferId == offerId)
            ?? throw new KeyNotFoundException($"Offer {offerId} not found.");
        var now = DateTime.UtcNow;

        if (!offer.IsActive || offer.Status != OfferStatus.Active)
        {
            throw new InvalidOperationException("This offer is not active.");
        }

        if (offer.StartDate > now)
        {
            throw new InvalidOperationException("This offer is not available yet.");
        }

        if (offer.EndDate < now)
        {
            throw new InvalidOperationException("This offer has expired.");
        }

        if (offer.Shop == null || !offer.Shop.IsActive || !offer.Shop.IsVerified)
        {
            throw new InvalidOperationException("This shop is not available for redemption.");
        }

        if (offer.MaxRedemptions > 0 && offer.CurrentRedemptions >= offer.MaxRedemptions)
        {
            throw new InvalidOperationException("This offer has reached its redemption limit.");
        }

        var redemption = new Redemption 
        { 
            UserId = userId, 
            OfferId = offerId, 
            ShopId = offer.ShopId,
            SavedAmount = offer.DiscountAmount,
            RedeemedAt = now,
            Status = Models.Enums.RedemptionStatus.Redeemed
        };

        offer.CurrentRedemptions += 1;
        offer.UpdatedAt = now;
        _db.Redemptions.Add(redemption);
        await _db.SaveChangesAsync();
        return redemption.RedemptionId;
    }

    public async Task SaveOfferAsync(Guid offerId, Guid userId)
    {
        var existing = await _db.Favourites.FirstOrDefaultAsync(f => f.UserId == userId && f.OfferId == offerId);
        if (existing != null)
        {
            return;
        }

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

    private static decimal ResolveSavings(decimal? savedAmount, decimal? offerDiscountAmount)
    {
        return savedAmount ?? offerDiscountAmount ?? 0m;
    }

    public async Task<List<RedemptionHistoryDto>> GetRedemptionHistoryAsync(Guid userId)
    {
        return await _db.Redemptions
            .AsNoTracking()
            .Include(r => r.Offer)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.RedeemedAt)
            .Select(r => new RedemptionHistoryDto { RedemptionId = r.RedemptionId, OfferTitle = r.Offer != null ? r.Offer.Title : "Unknown Offer" })
            .ToListAsync();
    }

    public async Task<LoyaltySummaryDto> GetLoyaltyWalletAsync(Guid userId)
    {
        var wallet = await _db.LoyaltyWallets
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.UserId == userId);
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
        var savingsRows = await (
            from redemption in _db.Redemptions.AsNoTracking()
            join offer in _db.Offers.AsNoTracking()
                on redemption.OfferId equals offer.OfferId into offerGroup
            from offer in offerGroup.DefaultIfEmpty()
            where redemption.UserId == userId
            select new
            {
                redemption.SavedAmount,
                OfferDiscountAmount = offer != null ? offer.DiscountAmount : null
            }
        ).ToListAsync();
        var totalRedemptions = await _db.Redemptions
            .AsNoTracking()
            .CountAsync(r => r.UserId == userId);

        var totalSaved = savingsRows.Sum(item =>
            ResolveSavings(item.SavedAmount, item.OfferDiscountAmount));

        return new UserSavingsSummaryDto
        {
            TotalSaved = totalSaved,
            TotalRedemptions = totalRedemptions
        };
    }
}

public class FavouriteService : IFavouriteService
{
    private readonly AppDbContext _db;
    public FavouriteService(AppDbContext db) => _db = db;

    public async Task<List<SavedItemDto>> GetFavouritesAsync(Guid userId)
    {
        var favourites = await _db.Favourites
            .AsNoTracking()
            .Include(f => f.Offer)
            .ThenInclude(offer => offer!.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(f => f.Shop)
            .ThenInclude(shop => shop!.Category)
            .Where(f => f.UserId == userId && 
                        (f.Offer == null || (f.Offer.IsActive && f.Offer.Shop != null && f.Offer.Shop.IsActive && f.Offer.Shop.IsVerified)) &&
                        (f.Shop == null || (f.Shop.IsActive && f.Shop.IsVerified)))
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        return favourites.Select(favourite =>
        {
            if (favourite.Offer != null)
            {
                var shop = favourite.Offer.Shop;
                return new SavedItemDto
                {
                    FavouriteId = favourite.FavouriteId,
                    Type = "offer",
                    OfferId = favourite.OfferId,
                    ShopId = favourite.Offer.ShopId,
                    Title = favourite.Offer.Title,
                    Subtitle = shop?.Name ?? "Offer",
                    Address = shop?.Address,
                    Latitude = shop?.Latitude,
                    Longitude = shop?.Longitude,
                    ImageUrl = favourite.Offer.ImageUrl ?? ImageConversionHelper.ToBase64DataUrl(shop?.ImageUrl),
                    DiscountPercentage = favourite.Offer.DiscountPercentage,
                    EndDate = favourite.Offer.EndDate,
                    IsVerified = shop?.IsVerified ?? false,
                    SavedAt = favourite.CreatedAt
                };
            }

            var shopOnly = favourite.Shop;
            return new SavedItemDto
            {
                FavouriteId = favourite.FavouriteId,
                Type = "shop",
                ShopId = favourite.ShopId,
                Title = shopOnly?.Name ?? "Saved shop",
                Subtitle = shopOnly?.Category?.Name ?? "Shop",
                Address = shopOnly?.Address,
                Latitude = shopOnly?.Latitude,
                Longitude = shopOnly?.Longitude,
                ImageUrl = ImageConversionHelper.ToBase64DataUrl(shopOnly?.ImageUrl),
                IsVerified = shopOnly?.IsVerified ?? false,
                SavedAt = favourite.CreatedAt
            };
        }).ToList();
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
