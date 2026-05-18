namespace allonbiz.AdminAPI.Models.Entities;

public class KeeperDocument
{
    public Guid DocumentId { get; set; } = Guid.NewGuid();
    public Guid KeeperId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string DocumentType { get; set; } = string.Empty;
    public string DocumentReference { get; set; } = string.Empty;
    public string Status { get; set; } = "pending"; // pending | verified | rejected
    public string? ReviewNotes { get; set; }
    public Guid? ReviewedByAdminId { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Keeper? Keeper { get; set; }
    public AdminAccount? ReviewedByAdmin { get; set; }
}
