using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class Offer
{
    public Guid OfferId { get; set; } = Guid.NewGuid();
    public Guid ShopId { get; set; }
    public Guid KeeperId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? TermsAndConditions { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal? DiscountAmount { get; set; }
    public decimal? MinOrderValue { get; set; }
    public string? CouponCode { get; set; }
    public byte[]? ImageData { get; set; }
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Comma-separated tags for the offer.
    /// Handled by ValueConverter in DbContext.
    /// </summary>
    public List<string> Tags { get; set; } = new();

    public bool IsFlashSale { get; set; }
    public string? RedemptionInstructions { get; set; }
    public int? StockQuantity { get; set; }
    public TimeSpan? AvailableFromTime { get; set; }
    public TimeSpan? AvailableToTime { get; set; }
    public Guid? CategoryId { get; set; }
    public OfferStatus Status { get; set; } = OfferStatus.Active;
    public int MaxRedemptions { get; set; }
    public int CurrentRedemptions { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Shop? Shop { get; set; }
    public Category? Category { get; set; }
    public Keeper? Keeper { get; set; }
}
