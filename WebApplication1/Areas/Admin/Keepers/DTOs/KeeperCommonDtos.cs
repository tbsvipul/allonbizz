using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class KeeperProfileDto
{
    public Guid KeeperId { get; set; }
    public Guid UserId { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? ContactPhone { get; set; }
    public string? BusinessLicense { get; set; }
    public string? GstNumber { get; set; }
    public string? PanNumber { get; set; }
    public string? SocialLinksJson { get; set; }
    public KeeperStatus Status { get; set; }
    public string? RejectionReason { get; set; }
    public string? HoldReason { get; set; }
    public DateTime? HoldUntil { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public List<KeeperDocumentDto> Documents { get; set; } = new();
    public List<KeeperReviewMessageHistoryDto> ReviewMessages { get; set; } = new();
    public string? IdentityProofType { get; set; }
    public string? IdentityProofNumber { get; set; }
    public byte[]? IdentityProofImage { get; set; }
    public string? BusinessLicenseNumber { get; set; }
    public byte[]? BusinessLicenseImage { get; set; }
    public byte[]? GstCertificateImage { get; set; }
    public byte[]? PanCardImage { get; set; }
    public string? AddressProofType { get; set; }
    public byte[]? AddressProofImage { get; set; }
    public byte[]? ShopFrontImage { get; set; }
    public byte[]? ShopInsideImage { get; set; }
}

public class KeeperDashboardDto
{
    public int ActiveOffersCount { get; set; }
    public int TotalReviews { get; set; }
}

public class KeeperTrafficDto
{
    public int CurrentViewersNearShop { get; set; }
    public List<HourlyTrafficDto> PredictedTraffic { get; set; } = new();
}

public class HourlyTrafficDto
{
    public int Hour { get; set; }
    public int PredictedCount { get; set; }
}

public class KeeperAnalyticsDto
{
    public int TotalShops { get; set; }
    public int ActiveShops { get; set; }
    public int TotalOffers { get; set; }
    public int ActiveOffers { get; set; }
    public List<KeeperShopAnalyticsDto> Shops { get; set; } = new();
}

public class KeeperShopAnalyticsDto
{
    public Guid ShopId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public int OfferCount { get; set; }
    public decimal Savings { get; set; }
}
