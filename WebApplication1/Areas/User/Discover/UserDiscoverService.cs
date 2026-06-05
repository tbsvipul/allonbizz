using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Text.Json;

namespace allonbiz.AdminAPI.Services;

public class UserDiscoverService : IUserDiscoverService
{
    private const int JourneyHistoryLimit = 25;
    private const int CandidateLimit = 600;

    private readonly AppDbContext _db;

    public UserDiscoverService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<UserDiscoverResponseDto> GetDiscoverAsync(Guid userId, UserDiscoverQueryDto query, CancellationToken ct = default)
    {
        var normalizedQuery = Normalize(query.Q);
        var normalizedCategory = Normalize(query.Category);
        var normalizedTags = NormalizeList(query.Tags);
        var limit = Math.Clamp(query.Limit ?? 30, 5, 100);
        var effectiveRadiusKm = Math.Clamp(query.RadiusKm ?? 10, 0.5, 50);
        var hasLocation = query.Lat.HasValue && query.Lng.HasValue;
        var now = DateTime.UtcNow;

        var profile = await BuildInterestProfileAsync(userId, ct);

        var offersQuery = _db.Offers
            .AsNoTracking()
            .Include(offer => offer.Shop)
                .ThenInclude(shop => shop!.Category)
            .Include(offer => offer.Category)
            .Where(offer =>
                offer.IsActive &&
                offer.Status == OfferStatus.Active &&
                offer.StartDate <= now &&
                offer.EndDate >= now &&
                offer.Shop != null &&
                offer.Shop.IsActive &&
                offer.Shop.IsVerified);

        if (query.CategoryId.HasValue)
        {
            var categoryId = query.CategoryId.Value;
            offersQuery = offersQuery.Where(offer => offer.CategoryId == categoryId || offer.Shop!.CategoryId == categoryId);
        }

        if (!string.IsNullOrWhiteSpace(normalizedCategory))
        {
            offersQuery = offersQuery.Where(offer =>
                (offer.Category != null && offer.Category.Name.ToLower() == normalizedCategory) ||
                (offer.Shop!.Category != null && offer.Shop.Category.Name.ToLower() == normalizedCategory));
        }

        if (hasLocation)
        {
            var bounds = CreateBounds(query.Lat!.Value, query.Lng!.Value, effectiveRadiusKm);
            offersQuery = offersQuery.Where(offer =>
                offer.Shop!.Latitude.HasValue &&
                offer.Shop.Longitude.HasValue &&
                offer.Shop.Latitude.Value >= bounds.MinLat &&
                offer.Shop.Latitude.Value <= bounds.MaxLat &&
                offer.Shop.Longitude.Value >= bounds.MinLng &&
                offer.Shop.Longitude.Value <= bounds.MaxLng);
        }

        var candidates = await offersQuery
            .OrderByDescending(offer => offer.CreatedAt)
            .Take(CandidateLimit)
            .ToListAsync(ct);

        var offerMatches = candidates
            .Select(offer => BuildOfferMatch(offer, profile, query.Lat, query.Lng, effectiveRadiusKm, hasLocation))
            .Where(match => match != null)
            .Select(match => match!)
            .Where(match => MatchesSearch(match.SearchTokens, normalizedQuery))
            .Where(match => MatchesAnyTag(match.MatchTokens, normalizedTags))
            .OrderByDescending(match => match.Score)
            .ThenBy(match => match.DistanceKm ?? double.MaxValue)
            .ThenByDescending(match => match.Offer.DiscountPercentage ?? 0)
            .ThenByDescending(match => match.Offer.CreatedAt)
            .Take(limit)
            .ToList();

        var shops = await LoadMatchingShopsAsync(
            profile,
            query.CategoryId,
            normalizedCategory,
            normalizedTags,
            normalizedQuery,
            query.Lat,
            query.Lng,
            effectiveRadiusKm,
            hasLocation,
            limit,
            now,
            ct);

        var taxonomy = query.IncludeTaxonomy
            ? await LoadTaxonomyAsync(ct)
            : (new List<UserDiscoverCategoryDto>(), new List<UserDiscoverTagDto>());

        return new UserDiscoverResponseDto
        {
            Categories = taxonomy.Item1,
            Tags = taxonomy.Item2,
            Offers = offerMatches.Select(MapOffer).ToList(),
            Shops = shops,
            Personalization = new UserDiscoverPersonalizationDto
            {
                HasHistory = profile.HasHistory,
                Strategy = profile.HasHistory ? "journey-history" : "fallback-nearby-trending",
                InterestTags = profile.InterestWeights
                    .OrderByDescending(item => item.Value)
                    .Select(item => item.Key)
                    .Take(12)
                    .ToList(),
                EncounteredShops = profile.EncounteredShopNames.Take(12).ToList()
            }
        };
    }

    private async Task<(List<UserDiscoverCategoryDto>, List<UserDiscoverTagDto>)> LoadTaxonomyAsync(CancellationToken ct)
    {
        var categories = await _db.Categories
            .AsNoTracking()
            .Where(category => category.IsActive)
            .OrderBy(category => category.DisplayOrder)
            .ThenBy(category => category.Name)
            .Select(category => new UserDiscoverCategoryDto
            {
                CategoryId = category.CategoryId,
                Name = category.Name,
                Icon = category.IconData ?? string.Empty,
                Color = category.Color ?? string.Empty,
                Description = category.Description,
                DisplayOrder = category.DisplayOrder
            })
            .ToListAsync(ct);

        var tags = await _db.Tags
            .AsNoTracking()
            .Where(tag => tag.IsActive)
            .OrderBy(tag => tag.Name)
            .Select(tag => new UserDiscoverTagDto
            {
                TagId = tag.TagId,
                Name = tag.Name,
                Type = tag.Type,
                Color = tag.Color,
                Icon = tag.IconData ?? string.Empty
            })
            .ToListAsync(ct);

        return (categories, tags);
    }

    private async Task<InterestProfile> BuildInterestProfileAsync(Guid userId, CancellationToken ct)
    {
        var journeys = await _db.Journeys
            .AsNoTracking()
            .Where(journey => journey.UserId == userId && (journey.EndTime.HasValue || journey.Status != "active"))
            .OrderByDescending(journey => journey.EndTime ?? journey.StartTime)
            .Take(JourneyHistoryLimit)
            .Select(journey => new
            {
                journey.TagsJson,
                journey.ShopsJson
            })
            .ToListAsync(ct);

        var profile = new InterestProfile
        {
            HasHistory = journeys.Count > 0
        };

        var encounteredIds = new HashSet<Guid>();
        var encounteredNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (var index = 0; index < journeys.Count; index++)
        {
            var recencyWeight = Math.Max(1.0, 4.0 - (index * 0.15));

            foreach (var tag in ReadJsonStringList(journeys[index].TagsJson))
            {
                AddWeight(profile.InterestWeights, tag, 4 * recencyWeight);
            }

            foreach (var shopToken in ReadJsonStringList(journeys[index].ShopsJson))
            {
                if (Guid.TryParse(shopToken, out var shopId))
                {
                    encounteredIds.Add(shopId);
                    continue;
                }

                encounteredNames.Add(shopToken);
                profile.EncounteredShopNames.Add(shopToken);
                AddWeight(profile.InterestWeights, shopToken, 1.5 * recencyWeight);
            }
        }

        if (encounteredIds.Count == 0 && encounteredNames.Count == 0)
        {
            return profile;
        }

        var encounteredShops = await _db.Shops
            .AsNoTracking()
            .Include(shop => shop.Category)
            .Where(shop =>
                encounteredIds.Contains(shop.ShopId) ||
                encounteredNames.Contains(shop.Name))
            .ToListAsync(ct);

        foreach (var shop in encounteredShops)
        {
            profile.EncounteredShopIds.Add(shop.ShopId);
            profile.EncounteredShopNames.Add(shop.Name);
            AddWeight(profile.InterestWeights, shop.Name, 3);

            foreach (var tag in shop.Tags ?? new List<string>())
            {
                AddWeight(profile.InterestWeights, tag, 3);
            }

            if (!string.IsNullOrWhiteSpace(shop.Category?.Name))
            {
                AddWeight(profile.InterestWeights, shop.Category.Name, 4);
            }
        }

        return profile;
    }

    private async Task<List<UserDiscoverShopDto>> LoadMatchingShopsAsync(
        InterestProfile profile,
        Guid? categoryId,
        string? category,
        IReadOnlyCollection<string> selectedTags,
        string? search,
        double? lat,
        double? lng,
        double radiusKm,
        bool hasLocation,
        int limit,
        DateTime now,
        CancellationToken ct)
    {
        var query = _db.Shops
            .AsNoTracking()
            .Include(shop => shop.Category)
            .Where(shop => shop.IsActive && shop.IsVerified);

        if (categoryId.HasValue)
        {
            query = query.Where(shop => shop.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            query = query.Where(shop => shop.Category != null && shop.Category.Name.ToLower() == category);
        }

        if (hasLocation)
        {
            var bounds = CreateBounds(lat!.Value, lng!.Value, radiusKm);
            query = query.Where(shop =>
                shop.Latitude.HasValue &&
                shop.Longitude.HasValue &&
                shop.Latitude.Value >= bounds.MinLat &&
                shop.Latitude.Value <= bounds.MaxLat &&
                shop.Longitude.Value >= bounds.MinLng &&
                shop.Longitude.Value <= bounds.MaxLng);
        }

        var candidates = await query
            .OrderByDescending(shop => shop.CreatedAt)
            .Take(CandidateLimit)
            .ToListAsync(ct);

        var matches = candidates
            .Select(shop => BuildShopMatch(shop, profile, lat, lng, radiusKm, hasLocation))
            .Where(match => match != null)
            .Select(match => match!)
            .Where(match => MatchesSearch(match.SearchTokens, search))
            .Where(match => MatchesAnyTag(match.MatchTokens, selectedTags))
            .OrderByDescending(match => match.Score)
            .ThenBy(match => match.DistanceKm ?? double.MaxValue)
            .ThenByDescending(match => match.Shop.CreatedAt)
            .Take(limit)
            .ToList();

        var shopIds = matches.Select(match => match.Shop.ShopId).ToList();
        var activeCounts = await _db.Offers
            .AsNoTracking()
            .Where(offer =>
                shopIds.Contains(offer.ShopId) &&
                offer.IsActive &&
                offer.Status == OfferStatus.Active &&
                offer.StartDate <= now &&
                offer.EndDate >= now)
            .GroupBy(offer => offer.ShopId)
            .Select(group => new { ShopId = group.Key, Count = group.Count() })
            .ToDictionaryAsync(item => item.ShopId, item => item.Count, ct);

        return matches.Select(match => new UserDiscoverShopDto
        {
            ShopId = match.Shop.ShopId,
            Name = match.Shop.Name,
            Description = match.Shop.Description,
            Address = match.Shop.Address,
            Latitude = match.Shop.Latitude,
            Longitude = match.Shop.Longitude,
            CategoryId = match.Shop.CategoryId,
            Category = match.CategoryName,
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(match.Shop.ImageUrl),
            ShopImages = match.Shop.ShopImages?
                .Select(image => ImageConversionHelper.ToBase64DataUrl(image))
                .OfType<string>()
                .ToList() ?? new List<string>(),
            Tags = match.Shop.Tags ?? new List<string>(),
            IsOpen = match.Shop.IsOpen,
            ActiveOfferCount = activeCounts.GetValueOrDefault(match.Shop.ShopId),
            DistanceKm = match.DistanceKm,
            MatchScore = Math.Round(match.Score, 2),
            MatchReason = ResolveMatchReason(match.MatchTokens, profile, match.DistanceKm)
        }).ToList();
    }

    private static OfferMatch? BuildOfferMatch(Offer offer, InterestProfile profile, double? lat, double? lng, double radiusKm, bool hasLocation)
    {
        var shop = offer.Shop;
        if (shop == null)
        {
            return null;
        }

        var distanceKm = CalculateDistance(lat, lng, shop.Latitude, shop.Longitude, hasLocation);
        if (hasLocation && (!distanceKm.HasValue || distanceKm.Value > radiusKm))
        {
            return null;
        }

        var categoryName = offer.Category?.Name ?? shop.Category?.Name ?? "General";
        var matchTokens = NormalizeList((offer.Tags ?? new List<string>())
            .Concat(shop.Tags ?? new List<string>())
            .Append(categoryName));

        var searchTokens = NormalizeList(matchTokens
            .Append(offer.Title)
            .Append(offer.Description ?? string.Empty)
            .Append(shop.Name)
            .Append(shop.Address ?? string.Empty));

        var score = CalculateTokenScore(matchTokens.Append(shop.Name), profile);
        if (profile.EncounteredShopIds.Contains(shop.ShopId) || profile.EncounteredShopNames.Contains(shop.Name))
        {
            score += 8;
        }

        if (distanceKm.HasValue)
        {
            score += Math.Max(0, 8 - distanceKm.Value);
        }

        score += (double)(offer.DiscountPercentage ?? 0) * 0.05;
        score += Math.Max(0, 5 - (DateTime.UtcNow - offer.CreatedAt).TotalDays / 7);

        return new OfferMatch(offer, shop, categoryName, distanceKm, score, matchTokens, searchTokens, profile);
    }

    private static ShopMatch? BuildShopMatch(Shop shop, InterestProfile profile, double? lat, double? lng, double radiusKm, bool hasLocation)
    {
        var distanceKm = CalculateDistance(lat, lng, shop.Latitude, shop.Longitude, hasLocation);
        if (hasLocation && (!distanceKm.HasValue || distanceKm.Value > radiusKm))
        {
            return null;
        }

        var categoryName = shop.Category?.Name ?? "General";
        var matchTokens = NormalizeList((shop.Tags ?? new List<string>()).Append(categoryName));
        var searchTokens = NormalizeList(matchTokens
            .Append(shop.Name)
            .Append(shop.Description ?? string.Empty)
            .Append(shop.Address ?? string.Empty));

        var score = CalculateTokenScore(matchTokens.Append(shop.Name), profile);
        if (profile.EncounteredShopIds.Contains(shop.ShopId) || profile.EncounteredShopNames.Contains(shop.Name))
        {
            score += 8;
        }

        if (distanceKm.HasValue)
        {
            score += Math.Max(0, 8 - distanceKm.Value);
        }

        score += Math.Max(0, 5 - (DateTime.UtcNow - shop.CreatedAt).TotalDays / 14);

        return new ShopMatch(shop, categoryName, distanceKm, score, matchTokens, searchTokens);
    }

    private static UserDiscoverOfferDto MapOffer(OfferMatch match)
    {
        return new UserDiscoverOfferDto
        {
            OfferId = match.Offer.OfferId,
            ShopId = match.Offer.ShopId,
            Title = match.Offer.Title,
            Description = match.Offer.Description,
            ShopName = match.Shop.Name,
            Category = match.CategoryName,
            Address = match.Shop.Address,
            Latitude = match.Shop.Latitude,
            Longitude = match.Shop.Longitude,
            ImageUrl = ImageConversionHelper.ToBase64DataUrl(match.Offer.ImageData) ??
                ImageConversionHelper.ToBase64DataUrl(match.Shop.ImageUrl ?? match.Shop.ShopImages.FirstOrDefault()),
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(match.Shop.ImageUrl),
            ShopIsOpen = match.Shop.IsOpen,
            DiscountPercentage = match.Offer.DiscountPercentage,
            EndDate = match.Offer.EndDate,
            Tags = match.Offer.Tags ?? new List<string>(),
            DistanceKm = match.DistanceKm,
            MatchScore = Math.Round(match.Score, 2),
            MatchReason = ResolveMatchReason(match.MatchTokens, match.Profile, match.DistanceKm)
        };
    }

    private static double CalculateTokenScore(IEnumerable<string> tokens, InterestProfile profile)
    {
        var score = profile.HasHistory ? 0.0 : 1.0;

        foreach (var token in tokens)
        {
            var normalized = Normalize(token);
            if (string.IsNullOrWhiteSpace(normalized))
            {
                continue;
            }

            if (profile.InterestWeights.TryGetValue(normalized, out var exactWeight))
            {
                score += exactWeight;
                continue;
            }

            score += profile.InterestWeights
                .Where(item => normalized.Contains(item.Key, StringComparison.OrdinalIgnoreCase) || item.Key.Contains(normalized, StringComparison.OrdinalIgnoreCase))
                .Select(item => item.Value * 0.5)
                .DefaultIfEmpty(0)
                .Max();
        }

        return score;
    }

    private static string ResolveMatchReason(IReadOnlyCollection<string> tokens, InterestProfile profile, double? distanceKm)
    {
        var matchingInterest = profile.InterestWeights
            .OrderByDescending(item => item.Value)
            .FirstOrDefault(item => tokens.Any(token =>
                token.Equals(item.Key, StringComparison.OrdinalIgnoreCase) ||
                token.Contains(item.Key, StringComparison.OrdinalIgnoreCase) ||
                item.Key.Contains(token, StringComparison.OrdinalIgnoreCase)));

        if (!string.IsNullOrWhiteSpace(matchingInterest.Key))
        {
            return $"Matched with {matchingInterest.Key}";
        }

        if (distanceKm.HasValue)
        {
            return $"{distanceKm.Value:0.0} km away";
        }

        return profile.HasHistory ? "Inspired by your journeys" : "Popular right now";
    }

    private static bool MatchesSearch(IReadOnlyCollection<string> tokens, string? search)
    {
        if (string.IsNullOrWhiteSpace(search))
        {
            return true;
        }

        return tokens.Any(token => token.Contains(search, StringComparison.OrdinalIgnoreCase));
    }

    private static bool MatchesAnyTag(IReadOnlyCollection<string> tokens, IReadOnlyCollection<string> selectedTags)
    {
        if (selectedTags.Count == 0)
        {
            return true;
        }

        return selectedTags.Any(tag => tokens.Any(token =>
            token.Equals(tag, StringComparison.OrdinalIgnoreCase) ||
            token.Contains(tag, StringComparison.OrdinalIgnoreCase) ||
            tag.Contains(token, StringComparison.OrdinalIgnoreCase)));
    }

    private static double? CalculateDistance(double? lat, double? lng, double? itemLat, double? itemLng, bool hasLocation)
    {
        if (!hasLocation || !lat.HasValue || !lng.HasValue || !itemLat.HasValue || !itemLng.HasValue)
        {
            return null;
        }

        return Math.Round(GeoHelper.CalculateDistanceKm(lat.Value, lng.Value, itemLat.Value, itemLng.Value), 2);
    }

    private static GeoBounds CreateBounds(double lat, double lng, double radiusKm)
    {
        var latOffset = radiusKm / 111.0;
        var lngOffset = radiusKm / (111.0 * Math.Cos(lat * Math.PI / 180.0));

        return new GeoBounds(
            lat - latOffset,
            lat + latOffset,
            lng - lngOffset,
            lng + lngOffset);
    }

    private static List<string> ReadJsonStringList(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<string>();
        }

        try
        {
            using var document = JsonDocument.Parse(json);
            if (document.RootElement.ValueKind != JsonValueKind.Array)
            {
                return new List<string>();
            }

            var values = new List<string>();
            foreach (var item in document.RootElement.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String)
                {
                    var value = item.GetString();
                    if (!string.IsNullOrWhiteSpace(value))
                    {
                        values.Add(value.Trim());
                    }
                    continue;
                }

                if (item.ValueKind == JsonValueKind.Object)
                {
                    var value = TryGetStringProperty(item, "shopId") ??
                        TryGetStringProperty(item, "id") ??
                        TryGetStringProperty(item, "name") ??
                        TryGetStringProperty(item, "title");

                    if (!string.IsNullOrWhiteSpace(value))
                    {
                        values.Add(value.Trim());
                    }
                }
            }

            return values;
        }
        catch (JsonException)
        {
            return new List<string>();
        }
    }

    private static string? TryGetStringProperty(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString()
            : null;
    }

    private static string? Normalize(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? null : normalized;
    }

    private static List<string> NormalizeList(IEnumerable<string>? values)
    {
        return values?
            .Select(value => value.Trim())
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList() ?? new List<string>();
    }

    private static void AddWeight(IDictionary<string, double> weights, string? rawKey, double amount)
    {
        var key = Normalize(rawKey);
        if (string.IsNullOrWhiteSpace(key))
        {
            return;
        }

        weights[key] = weights.TryGetValue(key, out var existing) ? existing + amount : amount;
    }

    private sealed class InterestProfile
    {
        public bool HasHistory { get; set; }
        public Dictionary<string, double> InterestWeights { get; } = new(StringComparer.OrdinalIgnoreCase);
        public HashSet<Guid> EncounteredShopIds { get; } = new();
        public HashSet<string> EncounteredShopNames { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    private sealed record GeoBounds(double MinLat, double MaxLat, double MinLng, double MaxLng);

    private sealed record OfferMatch(
        Offer Offer,
        Shop Shop,
        string CategoryName,
        double? DistanceKm,
        double Score,
        IReadOnlyCollection<string> MatchTokens,
        IReadOnlyCollection<string> SearchTokens,
        InterestProfile Profile);

    private sealed record ShopMatch(
        Shop Shop,
        string CategoryName,
        double? DistanceKm,
        double Score,
        IReadOnlyCollection<string> MatchTokens,
        IReadOnlyCollection<string> SearchTokens);
}
