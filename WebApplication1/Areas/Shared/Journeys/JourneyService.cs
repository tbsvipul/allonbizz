using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Users;
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

        var journey = new Journey
        {
            UserId = userId,
            StartName = dto.StartName,
            StartLat = dto.StartLat,
            StartLng = dto.StartLng,
            Type = dto.Type,
            Status = "active",
            TagsJson = JsonSerializer.Serialize(dto.Tags),
            StartTime = DateTime.UtcNow,
            EndName = dto.DestinationName,
            EndLat = dto.DestLat,
            EndLng = dto.DestLng,
        };

        _db.Journeys.Add(journey);
        await _db.SaveChangesAsync();
        await _firestore.SyncJourneyAsync(journey);
        return journey.JourneyId;
    }

    public async Task<List<JourneyRecommendationResponse>> GetNearByShopsAsync(Guid journeyId, double lat, double lng, double radiusKm = 5)
    {
        var journey = await _db.Journeys.FindAsync(journeyId);
        if (journey == null) return new List<JourneyRecommendationResponse>();

        var journeyTags = string.IsNullOrEmpty(journey.TagsJson) 
            ? new List<string>() 
            : JsonSerializer.Deserialize<List<string>>(journey.TagsJson) ?? new List<string>();

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
            .Where(s => s.IsActive && s.Latitude.HasValue && s.Longitude.HasValue &&
                        s.Latitude.Value >= minLat && s.Latitude.Value <= maxLat &&
                        s.Longitude.Value >= minLng && s.Longitude.Value <= maxLng)
            .OrderBy(s => (s.Latitude!.Value - lat) * (s.Latitude!.Value - lat) + (s.Longitude!.Value - lng) * (s.Longitude!.Value - lng))
            .Take(100) // Limit to a reasonable number to prevent huge memory spikes if too many shops in the box
            .ToListAsync();

        var recommendations = shopsInBox
            .Select(s => new {
                Shop = s,
                Distance = CalculateDistance(lat, lng, s.Latitude!.Value, s.Longitude!.Value),
                Tags = s.Tags != null && s.Tags.Any() ? s.Tags : new List<string> { s.Category?.Name ?? "" }
            })
            .Where(x => x.Distance <= radiusKm)
            .Where(x => journeyTags.Count == 0 || x.Tags.Any(t => journeyTags.Any(jt => jt.Equals(t, StringComparison.OrdinalIgnoreCase))))
            .OrderBy(x => x.Distance)
            .Select(x => new JourneyRecommendationResponse
            {
                ShopId = x.Shop.ShopId,
                Name = x.Shop.Name,
                Category = x.Shop.Category?.Name ?? "General",
                Latitude = x.Shop.Latitude!.Value,
                Longitude = x.Shop.Longitude!.Value,
                Distance = Math.Round(x.Distance, 2),
                Tags = x.Tags
            })
            .ToList();

        return recommendations;
    }

    public async Task<bool> UpdateJourneyProgressAsync(Guid journeyId, UpdateJourneyProgressDto dto)
    {
        var journey = await _db.Journeys.FindAsync(journeyId);
        if (journey == null)
        {
            return false;
        }
        
        if (journey.Status != "active") return true; 

        journey.Distance = dto.Distance;
        journey.Duration = dto.Duration;

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
            journey.Status = "completed";
            journey.EndName = dto.EndName;
            journey.EndLat = dto.EndLat;
            journey.EndLng = dto.EndLng;
            journey.Distance = dto.Distance;
            journey.Duration = dto.Duration;
            journey.ShopsJson = JsonSerializer.Serialize(dto.ShopsEncountered);
            journey.EndTime = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            await _firestore.SyncJourneyAsync(journey);
            return true;
        }
        return false;
    }

    public async Task<List<JourneyHistoryDto>> GetUserJourneysAsync(Guid userId)
    {
        return await _db.Journeys
            .AsNoTracking()
            .Include(j => j.User)
            .Where(j => j.UserId == userId)
            .OrderByDescending(j => j.StartTime)
            .Select(j => new JourneyHistoryDto
            {
                JourneyId = j.JourneyId,
                UserId = j.UserId,
                UserEmail = j.User != null ? j.User.Email ?? string.Empty : string.Empty,
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
                Tags = DeserializeStringList(j.TagsJson),
                ShopsEncountered = DeserializeStringList(j.ShopsJson),
            })
            .ToListAsync();
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
            EndName = journey.EndName,
            EndLat = journey.EndLat,
            EndLng = journey.EndLng,
            StartTime = journey.StartTime,
            EndTime = journey.EndTime,
            Distance = journey.Distance,
            Duration = journey.Duration,
            Tags = DeserializeStringList(journey.TagsJson),
            ShopsEncountered = DeserializeStringList(journey.ShopsJson),
            PathPoints = pathPoints
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
