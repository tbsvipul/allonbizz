using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class Redemption
{
    public Guid RedemptionId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid OfferId { get; set; }
    public Guid ShopId { get; set; }
    public RedemptionStatus Status { get; set; } = RedemptionStatus.Redeemed;
    public decimal? SavedAmount { get; set; }
    public int LoyaltyPointsEarned { get; set; }
    public DateTime RedeemedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Offer? Offer { get; set; }
    public Shop? Shop { get; set; }
}
