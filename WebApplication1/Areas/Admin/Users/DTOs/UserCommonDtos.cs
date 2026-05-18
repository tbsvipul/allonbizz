using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Users;

public class UserProfileDto
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ProfilePhotoUrl { get; set; }
    public string Role { get; set; } = string.Empty;
}

public class UpdateUserProfileDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
}

public class UserHomeDto
{
    public HomeSummaryDto Summary { get; set; } = new();
    public List<NearbyShopDto> NearbyShops { get; set; } = new();
    public List<OfferSummaryDto> RecommendedOffers { get; set; } = new();
    public List<CategorySummaryDto> Categories { get; set; } = new();
}

public class HomeSummaryDto
{
    public int TotalTrips { get; set; }
    public decimal TotalSaved { get; set; }
    public int LoyaltyPoints { get; set; }
    public bool HasActiveJourney { get; set; }
    public Guid? ActiveJourneyId { get; set; }
    public string? ActiveJourneyType { get; set; }
    public string? ActiveJourneyDestinationName { get; set; }
}

public class NearbyShopDto
{
    public Guid ShopId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public double DistanceKm { get; set; }
    public string? ImageUrl { get; set; }
}

public class OfferSummaryDto
{
    public Guid OfferId { get; set; }
    public Guid ShopId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public string? Address { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public DateTime EndDate { get; set; }
    public List<string> Tags { get; set; } = new();
}

public class CategorySummaryDto
{
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Icon { get; set; }
}
