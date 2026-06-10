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

    private Task<decimal> GetTotalSavedAsync(Guid userId)
    {
        return Task.FromResult(0m);
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
        var now = DateTime.UtcNow;
        var trendingOffers = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Status == OfferStatus.Active && o.StartDate <= now && o.EndDate >= now && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified)
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
            ImageUrl = ImageConversionHelper.ToBase64DataUrl(o.ImageData) ?? ImageConversionHelper.ToBase64DataUrl(o.Shop.ImageUrl ?? o.Shop.ShopImages.FirstOrDefault()),
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(o.Shop.ImageUrl),
            ShopIsOpen = o.Shop.IsOpen,
            DiscountPercentage = o.DiscountPercentage,
            EndDate = o.EndDate,
            Tags = o.Tags,
        }).ToList();

        List<Shop> nearby;
        if (lat.HasValue && lng.HasValue)
        {
            var user = await _db.Users.FindAsync(userId);
            if (user != null)
            {
                user.LastLatitude = lat.Value;
                user.LastLongitude = lng.Value;
                user.LastLoginAt = DateTime.UtcNow;

                var shopsInRange = await _db.Shops
                    .Where(s => s.IsActive && s.IsVerified && s.Latitude.HasValue && s.Longitude.HasValue && s.NotificationRadius.HasValue)
                    .ToListAsync();

                // var now = DateTime.UtcNow; // defined at start of method
                var cutoff = now.AddHours(-24);

                foreach (var s in shopsInRange) 
                {
                    var dist = GeoHelper.CalculateDistanceKm(lat.Value, lng.Value, s.Latitude!.Value, s.Longitude!.Value);
                    if (dist <= s.NotificationRadius!.Value)
                    {
                        // Get all active offers for this shop
                        var activeOffers = await _db.Offers
                            .AsNoTracking()
                            .Where(o => o.ShopId == s.ShopId 
                                     && o.IsActive 
                                     && o.Status == OfferStatus.Active
                                     && o.StartDate <= now 
                                     && o.EndDate >= now)
                            .ToListAsync();

                        foreach (var offer in activeOffers)
                        {
                            // Check if we already sent a notification for this offer to this user in the last 24 hours
                            var alreadySent = await _db.UserNotifications
                                .AnyAsync(un => un.UserId == userId 
                                             && un.Notification!.OfferId == offer.OfferId
                                             && un.Notification.Type == NotificationType.OfferAlert
                                             && un.Notification.CreatedAt > cutoff);

                            if (!alreadySent)
                            {
                                var discountText = offer.DiscountPercentage.HasValue && offer.DiscountPercentage > 0
                                    ? $" — {offer.DiscountPercentage}% off"
                                    : "";

                                var newNotif = new Notification
                                {
                                    NotificationId = Guid.NewGuid(),
                                    Title = $"🔥 {offer.Title}",
                                    Message = $"{s.Name} has an active offer nearby{discountText}! Check it out.",
                                    Type = NotificationType.OfferAlert,
                                    Priority = NotificationPriority.Normal,
                                    TargetAudience = "customers",
                                    Status = NotificationStatus.Sent,
                                    ScheduledAt = now,
                                    SentAt = now,
                                    CreatedAt = now,
                                    UpdatedAt = now,
                                    ShopId = s.ShopId,
                                    OfferId = offer.OfferId,
                                    ImageUrl = ImageConversionHelper.ToBase64DataUrl(offer.ImageData),
                                    SenderType = "System"
                                };
                                _db.Notifications.Add(newNotif);
                                _db.UserNotifications.Add(new UserNotification
                                {
                                    UserId = userId,
                                    NotificationId = newNotif.NotificationId,
                                    IsRead = false,
                                    IsDeleted = false,
                                    DeliveryStatus = "Delivered",
                                    SentAt = now
                                });
                            }
                        }

                        // Check for active persistent Keeper notifications
                        var activeNotifications = await _db.Notifications
                            .Where(n => n.SenderType == "Keeper"
                                     && n.ShopId == s.ShopId
                                     && n.IsActive
                                     && (n.ScheduledAt == null || n.ScheduledAt <= now)
                                     && (n.ExpiresAt == null || n.ExpiresAt >= now))
                            .ToListAsync();

                        foreach (var notif in activeNotifications)
                        {
                            var alreadySentNotif = await _db.UserNotifications
                                .AnyAsync(un => un.UserId == userId && un.NotificationId == notif.NotificationId);

                            if (!alreadySentNotif)
                            {
                                _db.UserNotifications.Add(new UserNotification
                                {
                                    UserId = userId,
                                    NotificationId = notif.NotificationId,
                                    IsRead = false,
                                    IsDeleted = false,
                                    DeliveryStatus = "Delivered",
                                    SentAt = now
                                });
                                notif.RecipientCount++;
                                _db.Notifications.Update(notif);
                            }
                        }
                    }
                }
                await _db.SaveChangesAsync();
            }

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
                ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(s.ImageUrl),
                IsOpen = s.IsOpen,
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
        var now = DateTime.UtcNow;
        var offers = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Status == OfferStatus.Active && o.StartDate <= now && o.EndDate >= now && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified)
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
            ImageUrl = ImageConversionHelper.ToBase64DataUrl(o.ImageData) ?? ImageConversionHelper.ToBase64DataUrl(o.Shop.ImageUrl ?? o.Shop.ShopImages.FirstOrDefault()),
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(o.Shop.ImageUrl),
            ShopIsOpen = o.Shop.IsOpen,
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
        var now = DateTime.UtcNow;
        var query = _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .ThenInclude(shop => shop!.Category)
            .Include(o => o.Category)
            .Where(o => o.IsActive && o.Status == OfferStatus.Active && o.StartDate <= now && o.EndDate >= now && o.Shop != null && o.Shop.IsActive && o.Shop.IsVerified);
            
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
                ImageUrl = ImageConversionHelper.ToBase64DataUrl(candidate.Offer.ImageData) ?? ImageConversionHelper.ToBase64DataUrl(candidate.Shop.ImageUrl ?? candidate.Shop.ShopImages.FirstOrDefault()),
                ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(candidate.Shop.ImageUrl),
                ShopIsOpen = candidate.Shop.IsOpen,
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
        if (offer == null) throw new KeyNotFoundException($"Offer {offerId} not found. (offer is null)");
        if (!offer.IsActive) throw new KeyNotFoundException($"Offer {offerId} not found. (offer is inactive)");
        if (offer.Shop == null) throw new KeyNotFoundException($"Offer {offerId} not found. (shop is null)");
        if (!offer.Shop.IsActive) throw new KeyNotFoundException($"Offer {offerId} not found. (shop is inactive)");
        if (!offer.Shop.IsVerified) throw new KeyNotFoundException($"Offer {offerId} not found. (shop is unverified)");
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
            ImageUrl = ImageConversionHelper.ToBase64DataUrl(offer.ImageData) ?? ImageConversionHelper.ToBase64DataUrl(offer.Shop?.ImageUrl ?? offer.Shop?.ShopImages.FirstOrDefault()),
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(offer.Shop?.ImageUrl),
            ShopIsOpen = offer.Shop?.IsOpen ?? false,
            TermsAndConditions = offer.TermsAndConditions,
            DiscountPercentage = offer.DiscountPercentage,
            MinOrderValue = offer.MinOrderValue,
            EndDate = offer.EndDate,
            IsSaved = await _db.Favourites.AnyAsync(f => f.UserId == userId && f.OfferId == offerId),
            Tags = offer.Tags,
        };
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
        var offer = await _db.Offers.AsNoTracking().FirstOrDefaultAsync(o => o.OfferId == offerId);
        if (offer == null) throw new KeyNotFoundException($"Offer {offerId} not found.");

        var review = new Review
        {
            UserId = userId,
            ShopId = offer.ShopId,
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

    public Task<UserSavingsSummaryDto> GetSavingsSummaryAsync(Guid userId)
    {
        return Task.FromResult(new UserSavingsSummaryDto
        {
            TotalSaved = 0
        });
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
                    ImageUrl = ImageConversionHelper.ToBase64DataUrl(favourite.Offer.ImageData) ?? ImageConversionHelper.ToBase64DataUrl(shop?.ImageUrl ?? shop?.ShopImages.FirstOrDefault()),
                    ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(shop?.ImageUrl),
                    ShopIsOpen = shop?.IsOpen ?? false,
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
                ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(shopOnly?.ImageUrl),
                ShopIsOpen = shopOnly?.IsOpen ?? false,
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
