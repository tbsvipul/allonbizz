namespace allonbiz.AdminAPI.Models.Entities;

public class NotificationDeliveryJob
{
    public Guid JobId { get; set; } = Guid.NewGuid();
    public Guid NotificationId { get; set; }
    public string Status { get; set; } = "queued"; // scheduled | queued | processing | sent | failed | cancelled
    public DateTime ScheduledFor { get; set; }
    public DateTime? EnqueuedAt { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? FailedAt { get; set; }
    public string? FailureReason { get; set; }
    public int AttemptCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Notification? Notification { get; set; }
}
