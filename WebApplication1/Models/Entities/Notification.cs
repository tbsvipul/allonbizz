using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class Notification
{
    public Guid NotificationId { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; } // Kept for individual notifications if needed
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public NotificationPriority Priority { get; set; } = NotificationPriority.Normal;
    public bool IsRead { get; set; } = false;
    
    public string TargetAudience { get; set; } = "all"; // all, customers, keepers
    public NotificationStatus Status { get; set; } = NotificationStatus.Draft;
    
    public DateTime? ScheduledAt { get; set; }
    public DateTime? SentAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    
    public Guid? SentById { get; set; }
    public Guid? SentByAdminAdminId { get; set; }
    public int RecipientCount { get; set; } = 0;
    
    public string? MetadataJson { get; set; } // Extra data as JSON
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public AdminAccount? SentByAdmin { get; set; }
}
