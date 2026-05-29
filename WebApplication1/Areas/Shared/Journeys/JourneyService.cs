using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Text.Json;

namespace allonbiz.AdminAPI.Services;

public class JourneyService : IJourneyService
{
    private readonly AppDbContext _db;
    private readonly IFirestoreService _firestore;
    public JourneyService(AppDbContext db, IFirestoreService firestore) 
    { 
        _db = db; 
        _firestore = firestore; 
    }

    public async Task<Guid> StartJourneyAsync(Guid userId, StartJourneyDto dto)
    {
        var normalizedType = NormalizeJourneyType(dto.Type);
        var normalizedTags = NormalizeTags(dto.Tags);
        var startName = string.IsNullOrWhiteSpace(dto.StartName)
            ? (normalizedType.Equals("freeRoam", StringComparison.OrdinalIgnoreCase)
                ? "Free Roam Start"
                : "Current Location")
            : dto.StartName.Trim();

        // Ensure user exists (Admins acting as users might not be in the Users table)
        if (!await _db.Users.AnyAsync(u => u.UserId == userId))
        {
            var admin = await _db.AdminAccounts.FindAsync(userId);
            if (admin != null)
            {
                _db.Users.Add(new User
                {
                    UserId = userId,
                    Email = admin.Email,
                    FirstName = admin.FirstName,
                    LastName = admin.LastName,
                    IsActive = true,
                    Role = "admin_shadow"
                });
                await _db.SaveChangesAsync();
            }
            else
            {
                throw new UnauthorizedAccessException("User context not found.");
            }
        }

        var existingActiveJourney = await _db.Journeys
            .AsNoTracking()
            .AnyAsync(j => j.UserId == userId && j.Status == "active");

        if (existingActiveJourney)
        {
            throw new InvalidOperationException("You already have an active journey. Complete it before starting a new one.");
        }

        var journey = new Journey
        {
            UserId = userId,
            StartName = startName,
            StartLat = dto.StartLat,
            StartLng = dto.StartLng,
            Type = normalizedType,
            Status = "active",
            TagsJson = JsonSerializer.Serialize(normalizedTags),
            StartTime = DateTime.UtcNow,
            EndName = normalizedType.Equals("destination", StringComparison.OrdinalIgnoreCase)
                ? dto.DestinationName
                : null,
            EndLat = normalizedType.Equals("destination", StringComparison.OrdinalIgnoreCase)
                ? dto.DestLat
                : null,
            EndLng = normalizedType.Equals("destination", StringComparison.OrdinalIgnoreCase)
                ? dto.DestLng
                : null,
            PathJson = JsonSerializer.Serialize(new List<double[]>
            {
                new[] { dto.StartLat, dto.StartLng }
            }),
        };

        _db.Journeys.Add(journey);
        await _db.SaveChangesAsync();
        await _firestore.SyncJourneyAsync(journey);
        return journey.JourneyId;
    }

    private static string NormalizeJourneyType(string? rawType)
    {
        var normalized = rawType?.Trim().ToLowerInvariant();

        return normalized switch
        {
            "destination" => "destination",
            "freeroam" => "freeRoam",
            "free_roam" => "freeRoam",
            "free-roam" => "freeRoam",
            "free roam" => "freeRoam",
            _ => "freeRoam"
        };
    }

    public async Task<List<JourneyRecommendationResponse>> GetNearByShopsAsync(Guid journeyId, double lat, double lng, double radiusKm = 5)
    {
        var journey = await _db.Journeys.FindAsync(journeyId);
        if (journey == null) return new List<JourneyRecommendationResponse>();

        var journeyTags = NormalizeTags(
            string.IsNullOrEmpty(journey.TagsJson)
                ? new List<string>()
                : JsonSerializer.Deserialize<List<string>>(journey.TagsJson) ?? new List<string>());

        // Approximate bounding box (1 degree latitude is approx 111km)
        double latOffset = radiusKm / 111.0;
        double lngOffset = radiusKm / (111.0 * Math.Cos(lat * Math.PI / 180.0));
        
        var minLat = lat - latOffset;
        var maxLat = lat + latOffset;
        var minLng = lng - lngOffset;
        var maxLng = lng + lngOffset;

        // Fetch only shops within the bounding box to avoid loading the entire table
        var shopsInBox = await _db.Shops
            .Include(s => s.Category)
            .Where(s => s.IsActive && s.IsVerified && s.Latitude.HasValue && s.Longitude.HasValue &&
                        s.Latitude.Value >= minLat && s.Latitude.Value <= maxLat &&
                        s.Longitude.Value >= minLng && s.Longitude.Value <= maxLng)
            .OrderBy(s => (s.Latitude!.Value - lat) * (s.Latitude!.Value - lat) + (s.Longitude!.Value - lng) * (s.Longitude!.Value - lng))
            .Take(100) // Limit to a reasonable number to prevent huge memory spikes if too many shops in the box
            .ToListAsync();

        var recommendations = shopsInBox
            .Select(s => new {
                Shop = s,
                Distance = CalculateDistance(lat, lng, s.Latitude!.Value, s.Longitude!.Value),
                Tags = BuildShopMatchTokens(s.Tags, s.Category?.Name)
            })
            .Where(x => x.Distance <= radiusKm)
            .Where(x => journeyTags.Count == 0 || MatchesAnyJourneyTag(journeyTags, x.Tags))
            .OrderBy(x => x.Distance)
            .Select(x => new JourneyRecommendationResponse
            {
                ShopId = x.Shop.ShopId,
                Name = x.Shop.Name,
                Category = x.Shop.Category?.Name ?? "General",
                Address = x.Shop.Address,
                Latitude = x.Shop.Latitude!.Value,
                Longitude = x.Shop.Longitude!.Value,
                Distance = Math.Round(x.Distance, 2),
                ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(x.Shop.ImageUrl),
                IsOpen = x.Shop.IsOpen,
                Tags = x.Tags
            })
            .ToList();

        return recommendations;
    }

    private static List<string> NormalizeTags(IEnumerable<string>? tags)
    {
        return tags?
            .Where(tag => !string.IsNullOrWhiteSpace(tag))
            .Select(tag => tag.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList()
            ?? new List<string>();
    }

    private static List<string> BuildShopMatchTokens(IEnumerable<string>? shopTags, string? categoryName)
    {
        var tokens = NormalizeTags(shopTags);

        if (!string.IsNullOrWhiteSpace(categoryName) &&
            !tokens.Contains(categoryName.Trim(), StringComparer.OrdinalIgnoreCase))
        {
            tokens.Add(categoryName.Trim());
        }

        return tokens;
    }

    private static bool MatchesAnyJourneyTag(IReadOnlyCollection<string> journeyTags, IReadOnlyCollection<string> shopTokens)
    {
        if (journeyTags.Count == 0)
        {
            return true;
        }

        if (shopTokens.Count == 0)
        {
            return false;
        }

        return journeyTags.Any(selectedTag =>
            shopTokens.Any(shopToken =>
                shopToken.Contains(selectedTag, StringComparison.OrdinalIgnoreCase) ||
                selectedTag.Contains(shopToken, StringComparison.OrdinalIgnoreCase)));
    }

    public async Task<bool> UpdateJourneyProgressAsync(Guid journeyId, UpdateJourneyProgressDto dto)
    {
        var journey = await _db.Journeys.FindAsync(journeyId);
        if (journey == null)
        {
            return false;
        }
        
        if (journey.Status != "active") return true; 

        if (dto.Distance > 0)
        {
            journey.Distance = Math.Max(journey.Distance, dto.Distance);
        }

        if (dto.Duration > 0)
        {
            journey.Duration = Math.Max(journey.Duration, dto.Duration);
        }

        // Append current position to path breadcrumb trail
        var path = string.IsNullOrEmpty(journey.PathJson)
            ? new List<double[]>()
            : JsonSerializer.Deserialize<List<double[]>>(journey.PathJson) ?? new List<double[]>();
        path.Add(new[] { dto.CurrentLat, dto.CurrentLng });
        journey.PathJson = JsonSerializer.Serialize(path);

        // Merge any newly encountered shops
        if (dto.ShopsEncountered.Count > 0)
        {
            var existing = string.IsNullOrEmpty(journey.ShopsJson)
                ? new List<string>()
                : JsonSerializer.Deserialize<List<string>>(journey.ShopsJson) ?? new List<string>();
            foreach (var shop in dto.ShopsEncountered)
            {
                if (!existing.Contains(shop)) existing.Add(shop);
            }
            journey.ShopsJson = JsonSerializer.Serialize(existing);
        }

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> EndJourneyAsync(Guid journeyId, EndJourneyDto dto)
    {
        var journey = await _db.Journeys.FindAsync(journeyId);
        if (journey != null)
        {
            var completedAt = DateTime.UtcNow;
            var effectiveEndName = !string.IsNullOrWhiteSpace(dto.EndName)
                ? dto.EndName
                : (!string.IsNullOrWhiteSpace(journey.EndName) ? journey.EndName : journey.StartName) ?? "Destination";
            var effectiveDistance = ResolveJourneyDistanceMeters(
                journey,
                dto.Distance,
                dto.EndLat,
                dto.EndLng);
            var effectiveDuration = ResolveJourneyDurationSeconds(
                journey,
                dto.Duration,
                completedAt);
            var mergedShops = MergeEncounteredShops(journey.ShopsJson, dto.ShopsEncountered);

            journey.Status = "completed";
            journey.EndName = effectiveEndName;
            journey.EndLat = dto.EndLat;
            journey.EndLng = dto.EndLng;
            journey.Distance = effectiveDistance;
            journey.Duration = effectiveDuration;
            journey.ShopsJson = JsonSerializer.Serialize(mergedShops);
            journey.EndTime = completedAt;

            AppendPathPoint(journey, dto.EndLat, dto.EndLng);

            await _db.SaveChangesAsync();
            await _firestore.SyncJourneyAsync(journey);
            return true;
        }
        return false;
    }

    public async Task<List<JourneyHistoryDto>> GetUserJourneysAsync(Guid userId)
    {
        var journeys = await _db.Journeys
            .AsNoTracking()
            .Include(j => j.User)
            .Where(j => j.UserId == userId)
            .OrderByDescending(j => j.StartTime)
            .ToListAsync();

        return journeys.Select(MapJourneyHistory).ToList();
    }

    public async Task<JourneyDetailDto?> GetJourneyDetailAsync(Guid journeyId, Guid userId)
    {
        var journey = await _db.Journeys
            .AsNoTracking()
            .Include(j => j.User)
            .FirstOrDefaultAsync(j => j.JourneyId == journeyId && j.UserId == userId);

        if (journey == null)
        {
            return null;
        }

        var pathPoints = DeserializePathPoints(journey.PathJson);

        var effectiveDistance = ResolveJourneyDistanceMeters(
            journey,
            journey.Distance,
            journey.EndLat,
            journey.EndLng);
        var effectiveDuration = ResolveJourneyDurationSeconds(
            journey,
            journey.Duration,
            journey.EndTime ?? DateTime.UtcNow);

        return new JourneyDetailDto
        {
            JourneyId = journey.JourneyId,
            UserId = journey.UserId,
            UserEmail = journey.User?.Email ?? string.Empty,
            Status = journey.Status,
            Type = journey.Type,
            StartName = journey.StartName,
            StartLat = journey.StartLat,
            StartLng = journey.StartLng,
            EndName = ResolveJourneyEndName(journey),
            EndLat = journey.EndLat,
            EndLng = journey.EndLng,
            StartTime = journey.StartTime,
            EndTime = journey.EndTime,
            Distance = effectiveDistance,
            Duration = effectiveDuration,
            Tags = DeserializeStringList(journey.TagsJson),
            ShopsEncountered = DeserializeStringList(journey.ShopsJson),
            PathPoints = pathPoints
        };
    }

    private JourneyHistoryDto MapJourneyHistory(Journey journey)
    {
        var effectiveDistance = ResolveJourneyDistanceMeters(
            journey,
            journey.Distance,
            journey.EndLat,
            journey.EndLng);
        var effectiveDuration = ResolveJourneyDurationSeconds(
            journey,
            journey.Duration,
            journey.EndTime ?? DateTime.UtcNow);

        return new JourneyHistoryDto
        {
            JourneyId = journey.JourneyId,
            UserId = journey.UserId,
            UserEmail = journey.User?.Email ?? string.Empty,
            Type = journey.Type,
            StartName = journey.StartName,
            StartLat = journey.StartLat,
            StartLng = journey.StartLng,
            EndName = ResolveJourneyEndName(journey),
            EndLat = journey.EndLat,
            EndLng = journey.EndLng,
            StartTime = journey.StartTime,
            EndTime = journey.EndTime,
            Distance = effectiveDistance,
            Duration = effectiveDuration,
            Tags = DeserializeStringList(journey.TagsJson),
            ShopsEncountered = DeserializeStringList(journey.ShopsJson),
        };
    }

    private static List<string> DeserializeStringList(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<string>();
        }

        return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
    }

    private static List<JourneyCoordinateDto> DeserializePathPoints(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<JourneyCoordinateDto>();
        }

        var rawPoints = JsonSerializer.Deserialize<List<double[]>>(json) ?? new List<double[]>();
        return rawPoints
            .Where(point => point.Length >= 2)
            .Select(point => new JourneyCoordinateDto
            {
                Latitude = point[0],
                Longitude = point[1]
            })
            .ToList();
    }

    private static List<string> MergeEncounteredShops(string? existingJson, List<string>? incoming)
    {
        var merged = DeserializeStringList(existingJson);

        if (incoming == null || incoming.Count == 0)
        {
            return merged;
        }

        foreach (var shop in incoming.Where(shop => !string.IsNullOrWhiteSpace(shop)))
        {
            if (!merged.Contains(shop))
            {
                merged.Add(shop);
            }
        }

        return merged;
    }

    private static string ResolveJourneyEndName(Journey journey)
    {
        if (!string.IsNullOrWhiteSpace(journey.EndName))
        {
            return journey.EndName!;
        }

        if (journey.Type.Equals("freeRoam", StringComparison.OrdinalIgnoreCase))
        {
            return "Free Roam End";
        }

        return journey.StartName ?? "Destination";
    }

    private double ResolveJourneyDistanceMeters(
        Journey journey,
        double candidateDistance,
        double? endLat,
        double? endLng)
    {
        if (candidateDistance > 0)
        {
            return candidateDistance;
        }

        if (journey.Distance > 0)
        {
            return journey.Distance;
        }

        if (endLat.HasValue && endLng.HasValue)
        {
            return CalculateDistance(journey.StartLat, journey.StartLng, endLat.Value, endLng.Value) * 1000;
        }

        return 0;
    }

    private static long ResolveJourneyDurationSeconds(
        Journey journey,
        long candidateDuration,
        DateTime referenceTime)
    {
        if (candidateDuration > 0)
        {
            return candidateDuration;
        }

        if (journey.Duration > 0)
        {
            return journey.Duration;
        }

        var effectiveEndTime = journey.EndTime ?? referenceTime;
        var elapsed = (long)Math.Round((effectiveEndTime - journey.StartTime).TotalSeconds);
        return Math.Max(elapsed, 0);
    }

    private static void AppendPathPoint(Journey journey, double latitude, double longitude)
    {
        var path = string.IsNullOrEmpty(journey.PathJson)
            ? new List<double[]>()
            : JsonSerializer.Deserialize<List<double[]>>(journey.PathJson) ?? new List<double[]>();

        if (path.Count == 0)
        {
            path.Add(new[] { journey.StartLat, journey.StartLng });
        }

        if (path.Count == 0 ||
            path[^1].Length < 2 ||
            path[^1][0] != latitude ||
            path[^1][1] != longitude)
        {
            path.Add(new[] { latitude, longitude });
        }

        journey.PathJson = JsonSerializer.Serialize(path);
    }

    private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var R = 6371; // km
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        lat1 = ToRadians(lat1);
        lat2 = ToRadians(lat2);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2) * Math.Cos(lat1) * Math.Cos(lat2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private double ToRadians(double deg) => deg * (Math.PI / 180);
}
