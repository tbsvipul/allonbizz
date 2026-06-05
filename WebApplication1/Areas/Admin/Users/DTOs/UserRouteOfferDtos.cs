using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Users;

public class RouteCalculateRequestDto
{
    public double OriginLat { get; set; }
    public double OriginLng { get; set; }
    public double DestinationLat { get; set; }
    public double DestinationLng { get; set; }
}

public class RouteResponseDto
{
    public Guid RouteId { get; set; }
    public double DistanceKm { get; set; }
    public int DurationMinutes { get; set; }
    public List<OfferSummaryDto> OffersAlongRoute { get; set; } = new();
}

public class OfferDetailDto
{
    public Guid OfferId { get; set; }
    public Guid ShopId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? TermsAndConditions { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string? ShopAddress { get; set; }
    public string? Category { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public string? ShopProfileImage { get; set; }
    public bool ShopIsOpen { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal? MinOrderValue { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsSaved { get; set; }
    public List<string> Tags { get; set; } = new();
}

public class RedemptionHistoryDto
{
    public Guid RedemptionId { get; set; }
    public string OfferTitle { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public decimal SavedAmount { get; set; }
    public DateTime RedeemedAt { get; set; }
}

