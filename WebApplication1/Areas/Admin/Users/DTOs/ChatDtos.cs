namespace routent.AdminAPI.DTOs.Users;

public class ChatThreadDto
{
    public Guid ThreadId { get; set; }
    public Guid UserId { get; set; }
    public Guid KeeperId { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? LastMessageAt { get; set; }
    public int MessageCount { get; set; }
}

public class UserSavingsSummaryDto
{
    public decimal TotalSaved { get; set; }
}
