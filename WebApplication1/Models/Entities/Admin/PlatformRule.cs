namespace allonbiz.AdminAPI.Models.Entities;

public class PlatformRule
{
    public Guid RuleId { get; set; } = Guid.NewGuid();
    public string Key { get; set; } = string.Empty; // e.g., "MinOfferDuration", "MaxRefundDays"
    public string Value { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Group { get; set; } = "General"; // General, Offer, Shop, Loyalty
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
