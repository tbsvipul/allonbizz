using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class RegisterShopDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public Guid? CategoryId { get; set; }
}

public class CreateOfferDto
{
    public Guid ShopId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal? DiscountAmount { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? TermsAndConditions { get; set; }
}

public class KeeperOfferDetailDto
{
    public Guid OfferId { get; set; }
    public string Title { get; set; } = string.Empty;
    public OfferStatus Status { get; set; }
    public int RedemptionCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

