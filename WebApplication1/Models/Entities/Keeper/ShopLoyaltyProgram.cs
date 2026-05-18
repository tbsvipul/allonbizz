namespace allonbiz.AdminAPI.Models.Entities;

public class ShopLoyaltyProgram
{
    public Guid ProgramId { get; set; } = Guid.NewGuid();
    public Guid ShopId { get; set; }
    public bool IsEnabled { get; set; }
    public string? ProgramName { get; set; }
    public int PointsPerRedemption { get; set; } = 1;
    public int MinimumPointsToRedeem { get; set; }
    public string? RewardDescription { get; set; }
    public string? TermsAndConditions { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Shop? Shop { get; set; }
}
