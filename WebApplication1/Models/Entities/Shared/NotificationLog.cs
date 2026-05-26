using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace allonbiz.AdminAPI.Models.Entities;

public class NotificationLog
{
    [Key]
    public Guid LogId { get; set; } = Guid.NewGuid();
    
    public Guid NotificationId { get; set; }
    public Guid? UserId { get; set; }
    
    public string Status { get; set; } = "Pending";
    public string? FailureReason { get; set; }
    
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? DeliveredAt { get; set; }
    
    [ForeignKey(nameof(NotificationId))]
    public Notification? Notification { get; set; }
    
    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }
}
