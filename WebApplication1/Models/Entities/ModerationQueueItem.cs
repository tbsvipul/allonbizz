namespace allonbiz.AdminAPI.Models.Entities;

public class ModerationQueueItem
{
    public Guid ItemId { get; set; } = Guid.NewGuid();
    public string ContentType { get; set; } = string.Empty;  // review | promotion | user_report
    public string Title { get; set; } = string.Empty;
    public string? Preview { get; set; }
    public Guid ReferenceId { get; set; }
    public Guid SubmittedBy { get; set; }
    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "pending";  // pending | under_review | approved | rejected
    public int ReportCount { get; set; } = 0;
    public List<string> FlagReasons { get; set; } = new();
    public Guid? ReviewedBy { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public string? RejectionReason { get; set; }

    // Navigation
    public AdminAccount? Reviewer { get; set; }
}
