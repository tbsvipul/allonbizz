using System.ComponentModel.DataAnnotations;
using routent.AdminAPI.Models.Enums;
using routent.AdminAPI.DTOs.Common;

namespace routent.AdminAPI.DTOs.Admin;

public class NotificationSummaryDto
{
    public Guid NotificationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Priority { get; set; } = string.Empty;
    public string TargetAudience { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? ScheduledAt { get; set; }
    public DateTime? SentAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public int RecipientCount { get; set; }
}

public class NotificationDetailDto : NotificationSummaryDto
{
    public DateTime? ExpiresAt { get; set; }
    public Guid? SentById { get; set; }
    public string? SentByName { get; set; }
    public string? MetadataJson { get; set; }
    public List<NotificationDeliveryJobDto> DeliveryJobs { get; set; } = new();
}

public class CreateNotificationDto
{
    [Required]
    public string Title { get; set; } = string.Empty;
    [Required]
    public string Message { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Type { get; set; } = "SystemMessage";
    public string Priority { get; set; } = "Normal";
    public string TargetAudience { get; set; } = "all";
    public bool IsGlobal { get; set; } = false;
    public decimal? RadiusKm { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public List<Guid>? TargetUserIds { get; set; }
    public DateTime? ScheduledAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? MetadataJson { get; set; }
    public bool SendImmediately { get; set; } = false;
}

public class UpdateNotificationDto
{
    [Required]
    public string Title { get; set; } = string.Empty;
    [Required]
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "SystemMessage";
    public string Priority { get; set; } = "Normal";
    public string TargetAudience { get; set; } = "all";
    public DateTime? ScheduledAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? MetadataJson { get; set; }
}

public class NotificationStatsDto
{
    public int TotalNotifications { get; set; }
    public int SentNotifications { get; set; }
    public int ScheduledNotifications { get; set; }
    public int DraftNotifications { get; set; }
    public int QueuedNotifications { get; set; }
    public int FailedNotifications { get; set; }
}

public class NotificationDeliveryJobDto
{
    public Guid JobId { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime ScheduledFor { get; set; }
    public DateTime? EnqueuedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? FailedAt { get; set; }
    public string? FailureReason { get; set; }
    public int AttemptCount { get; set; }
}
