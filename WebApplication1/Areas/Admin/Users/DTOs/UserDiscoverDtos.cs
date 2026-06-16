namespace routent.AdminAPI.DTOs.Users;

public class UserDiscoverQueryDto
{
    public string? Q { get; set; }
    public Guid? CategoryId { get; set; }
    public string? Category { get; set; }
    public List<string> Tags { get; set; } = new();
    public double? Lat { get; set; }
    public double? Lng { get; set; }
    public double? RadiusKm { get; set; }
    public int? Limit { get; set; }
    public bool IncludeTaxonomy { get; set; } = true;
}

public class UserDiscoverResponseDto
{
    public List<UserDiscoverCategoryDto> Categories { get; set; } = new();
    public List<UserDiscoverTagDto> Tags { get; set; } = new();
    public List<UserDiscoverOfferDto> Offers { get; set; } = new();
    public List<UserDiscoverShopDto> Shops { get; set; } = new();
    public UserDiscoverPersonalizationDto Personalization { get; set; } = new();
}

public class UserDiscoverCategoryDto
{
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
}

public class UserDiscoverTagDto
{
    public Guid TagId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Type { get; set; }
    public string? Color { get; set; }
    public string Icon { get; set; } = string.Empty;
}

public class UserDiscoverOfferDto : OfferSummaryDto
{
    public double? DistanceKm { get; set; }
    public double MatchScore { get; set; }
    public string MatchReason { get; set; } = "Popular near you";
}

public class UserDiscoverShopDto
{
    public Guid ShopId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public Guid? CategoryId { get; set; }
    public string Category { get; set; } = "General";
    public string? ShopProfileImage { get; set; }
    public List<string> ShopImages { get; set; } = new();
    public List<string> Tags { get; set; } = new();
    public bool IsOpen { get; set; }
    public int ActiveOfferCount { get; set; }
    public double? DistanceKm { get; set; }
    public double MatchScore { get; set; }
    public string MatchReason { get; set; } = "Recommended shop";
}

public class UserDiscoverPersonalizationDto
{
    public bool HasHistory { get; set; }
    public string Strategy { get; set; } = "fallback";
    public List<string> InterestTags { get; set; } = new();
    public List<string> EncounteredShops { get; set; } = new();
}
