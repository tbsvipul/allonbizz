namespace allonbiz.AdminAPI.Models.Entities;

public class LoyaltyWallet
{
    public Guid WalletId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int TotalPoints { get; set; }
    public int RedeemedPoints { get; set; }
    public int CurrentPoints => TotalPoints - RedeemedPoints;
    public string Tier { get; set; } = "Bronze"; // Bronze, Silver, Gold, Platinum
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
