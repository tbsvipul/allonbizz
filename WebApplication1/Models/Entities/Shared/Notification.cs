using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class Notification
{
    public Guid NotificationId { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    
    public NotificationType Type { get; set; }
    public NotificationPriority Priority { get; set; } = NotificationPriority.Normal;
    
    public string SenderType { get; set; } = "System"; // Admin, Keeper, System
    public Guid? SenderId { get; set; }
    public Guid? ShopId { get; set; }
    public Guid? OfferId { get; set; }
    
    public decimal? RadiusKm { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    
    public bool IsGlobal { get; set; } = false;
    public bool IsActive { get; set; } = true;
    
    public string TargetAudience { get; set; } = "all"; // all, customers, keepers
    public NotificationStatus Status { get; set; } = NotificationStatus.Draft;
    
    public DateTime? ScheduledAt { get; set; }
    public DateTime? SentAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    
    public Guid? UserId { get; set; } // Kept for individual notifications if needed
    public bool IsRead { get; set; } = false;
    public Guid? SentById { get; set; }
    public Guid? SentByAdminAdminId { get; set; }
    
    public int RecipientCount { get; set; } = 0;
    public string? MetadataJson { get; set; } // Extra data as JSON
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public AdminAccount? SentByAdmin { get; set; }
    public Shop? Shop { get; set; }
    public Offer? Offer { get; set; }
    
    // Navigation property to individual user tracking
    public ICollection<UserNotification> UserNotifications { get; set; } = new List<UserNotification>();
    public ICollection<NotificationLog> NotificationLogs { get; set; } = new List<NotificationLog>();
}
