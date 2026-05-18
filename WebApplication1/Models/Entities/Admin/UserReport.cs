namespace allonbiz.AdminAPI.Models.Entities;

public class UserReport
{
    public Guid ReportId { get; set; } = Guid.NewGuid();
    public string ReportedItemId { get; set; } = string.Empty;
    public string ItemType { get; set; } = string.Empty;  // review | promotion | user
    public Guid ReportedBy { get; set; }
    public string Reason { get; set; } = string.Empty;  // abuse | spam | inappropriate | fraudulent
    public string? Comments { get; set; }
    public List<string> Evidence { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "pending";  // pending | investigated | resolved | dismissed
    public Guid? HandledBy { get; set; }
    public string? ResolutionNote { get; set; }
    public DateTime? ResolvedAt { get; set; }

    // Navigation
    public AdminAccount? Handler { get; set; }
}
