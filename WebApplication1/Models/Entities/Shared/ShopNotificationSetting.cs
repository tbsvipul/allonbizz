using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace routent.AdminAPI.Models.Entities;

public class ShopNotificationSetting
{
    [Key]
    public Guid SettingId { get; set; } = Guid.NewGuid();
    
    public Guid ShopId { get; set; }
    
    public bool AutoRadiusNotification { get; set; } = false;
    public decimal RadiusKm { get; set; } = 5.0m;
    public int CooldownHours { get; set; } = 24;
    
    public bool IsActive { get; set; } = true;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    [ForeignKey(nameof(ShopId))]
    public Shop? Shop { get; set; }
}
