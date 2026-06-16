namespace routent.AdminAPI.Models.Entities;

public class ChatMessage
{
    public Guid MessageId { get; set; } = Guid.NewGuid();
    public Guid ThreadId { get; set; }
    public string SenderType { get; set; } = string.Empty; // user | keeper | admin | system
    public Guid? SenderId { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }

    public ChatThread? Thread { get; set; }
}
