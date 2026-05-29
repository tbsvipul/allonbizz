using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class RegisterShopDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Address { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? ShopProfileImage { get; set; }
    public List<string> ShopImages { get; set; } = new();
    public Guid? CategoryId { get; set; }
    public bool IsOpen { get; set; } = true;
    public double? NotificationRadius { get; set; }
    public List<string> Amenities { get; set; } = new();
    public List<string> Tags { get; set; } = new();
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
    public string? ImageUrl { get; set; }
}

public class KeeperOfferDetailDto
{
    public Guid OfferId { get; set; }
    public Guid ShopId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal? DiscountAmount { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? TermsAndConditions { get; set; }
    public string? ImageUrl { get; set; }
    public OfferStatus Status { get; set; }
    public int RedemptionCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class BulkOfferUploadResultDto
{
    public int ImportedCount { get; set; }
    public int FailedRowCount => FailedRows.Count;
    public List<BulkOfferUploadRowErrorDto> FailedRows { get; set; } = new();
}

public class BulkOfferUploadRowErrorDto
{
    public int RowNumber { get; set; }
    public string Message { get; set; } = string.Empty;
}
