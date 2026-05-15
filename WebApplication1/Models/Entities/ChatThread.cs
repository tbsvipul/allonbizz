namespace allonbiz.AdminAPI.Models.Entities;

public class ChatThread
{
    public Guid ThreadId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid KeeperId { get; set; }
    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastMessageAt { get; set; }

    public User? User { get; set; }
    public Keeper? Keeper { get; set; }
    public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
}
