using System.Text.Json;

namespace routent.AdminAPI.Models.Entities;

public class AuditLog
{
    public Guid AuditId { get; set; } = Guid.NewGuid();
    public Guid AdminId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string TargetEntity { get; set; } = string.Empty;
    public string TargetId { get; set; } = string.Empty;
    public JsonDocument? Changes { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }

    // Navigation
    public AdminAccount Admin { get; set; } = null!;
}
