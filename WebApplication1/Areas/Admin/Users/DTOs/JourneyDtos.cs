    using System.ComponentModel.DataAnnotations;

namespace routent.AdminAPI.DTOs.Users;

public class StartJourneyDto
{
    [Required]
    public string StartName { get; set; } = string.Empty;
    public double StartLat { get; set; }
    public double StartLng { get; set; }
    public string Type { get; set; } = "freeRoam";
    public List<string> Tags { get; set; } = new();
    public string? DestinationName { get; set; }
    public double? DestLat { get; set; }
    public double? DestLng { get; set; }
}

public class EndJourneyDto
{
    [Required]
    public string EndName { get; set; } = string.Empty;
    public double EndLat { get; set; }
    public double EndLng { get; set; }
    public double Distance { get; set; }
    public long Duration { get; set; }
    public List<string> ShopsEncountered { get; set; } = new(); // Just names or IDs for now
}

public class UpdateJourneyProgressDto
{
    public double CurrentLat { get; set; }
    public double CurrentLng { get; set; }
    public double Distance { get; set; }
    public long Duration { get; set; }
    public List<string> ShopsEncountered { get; set; } = new();
}

public class JourneyOfferDto
{
    public Guid OfferId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal? DiscountAmount { get; set; }
    public string? CouponCode { get; set; }
    public string? OfferImage { get; set; }
    public List<string> Tags { get; set; } = new();
}

public class JourneyRecommendationResponse
{
    public Guid ShopId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Address { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double Distance { get; set; }
    public string? ShopProfileImage { get; set; }
    public bool IsOpen { get; set; }
    public List<string> Tags { get; set; } = new();
    public List<JourneyOfferDto> Offers { get; set; } = new();
}

public class JourneyHistoryDto
{
    public Guid JourneyId { get; set; }
    public Guid UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string Type { get; set; } = "freeRoam";
    public string? StartName { get; set; }
    public double StartLat { get; set; }
    public double StartLng { get; set; }
    public string? EndName { get; set; }
    public double? EndLat { get; set; }
    public double? EndLng { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public double Distance { get; set; }
    public long Duration { get; set; }
    public List<string> Tags { get; set; } = new();
    public List<string> ShopsEncountered { get; set; } = new();
}

public class JourneyCoordinateDto
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class JourneyDetailDto
{
    public Guid JourneyId { get; set; }
    public Guid UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Type { get; set; } = "freeRoam";
    public string? StartName { get; set; }
    public double StartLat { get; set; }
    public double StartLng { get; set; }
    public string? EndName { get; set; }
    public double? EndLat { get; set; }
    public double? EndLng { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public double Distance { get; set; }
    public long Duration { get; set; }
    public List<string> Tags { get; set; } = new();
    public List<string> ShopsEncountered { get; set; } = new();
    public List<JourneyCoordinateDto> PathPoints { get; set; } = new();
}
