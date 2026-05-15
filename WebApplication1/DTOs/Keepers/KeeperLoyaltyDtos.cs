using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class LoyaltyProgramDto
{
    public Guid ShopId { get; set; }
    public bool Configured { get; set; }
    public bool IsEnabled { get; set; }
    public string? ProgramName { get; set; }
    public int PointsPerRedemption { get; set; }
    public int MinimumPointsToRedeem { get; set; }
    public string? RewardDescription { get; set; }
    public string? TermsAndConditions { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class UpdateLoyaltyProgramDto
{
    [Required]
    public Guid ShopId { get; set; }
    public bool IsEnabled { get; set; }
    [StringLength(200)]
    public string? ProgramName { get; set; }
    [Range(0, 100000)]
    public int PointsPerRedemption { get; set; } = 1;
    [Range(0, 100000)]
    public int MinimumPointsToRedeem { get; set; }
    public string? RewardDescription { get; set; }
    public string? TermsAndConditions { get; set; }
}
