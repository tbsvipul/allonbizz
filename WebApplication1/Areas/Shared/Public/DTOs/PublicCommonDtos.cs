namespace allonbiz.AdminAPI.DTOs.Public;

public class PublicCategoryDto
{
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public string? Color { get; set; }
}

public class PlaceSearchResponseDto
{
    public string GooglePlaceId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class TrendingOfferDto
{
    public Guid OfferId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public double PopularityScore { get; set; }
}
