using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace routent.AdminAPI.Models.Entities;

public class UserNotification
{
    [Key]
    public Guid UserNotificationId { get; set; } = Guid.NewGuid();
    
    public Guid UserId { get; set; }
    public Guid NotificationId { get; set; }
    
    public bool IsRead { get; set; } = false;
    public DateTime? ReadAt { get; set; }
    public bool IsDeleted { get; set; } = false;
    
    public DateTime? SentAt { get; set; }
    public string DeliveryStatus { get; set; } = "Pending"; // Pending, Delivered, Failed
    
    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }
    
    [ForeignKey(nameof(NotificationId))]
    public Notification? Notification { get; set; }
}
