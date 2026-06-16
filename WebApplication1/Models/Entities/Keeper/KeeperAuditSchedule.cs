namespace routent.AdminAPI.Models.Entities;

public class KeeperAuditSchedule
{
    public Guid AuditScheduleId { get; set; } = Guid.NewGuid();
    public Guid KeeperId { get; set; }
    public Guid RequestedByAdminId { get; set; }
    public DateTime AuditDate { get; set; }
    public string? Notes { get; set; }
    public string Status { get; set; } = "scheduled"; // scheduled | completed | cancelled
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Keeper? Keeper { get; set; }
    public AdminAccount? RequestedByAdmin { get; set; }
}
