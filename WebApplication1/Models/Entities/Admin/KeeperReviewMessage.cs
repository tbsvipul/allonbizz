namespace routent.AdminAPI.Models.Entities;

public class KeeperReviewMessage
{
    public Guid MessageId { get; set; } = Guid.NewGuid();
    public Guid KeeperId { get; set; }
    public Guid AdminId { get; set; }
    public string MessageType { get; set; } = "request_info";
    public string Message { get; set; } = string.Empty;
    public bool IsReadByKeeper { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Keeper? Keeper { get; set; }
    public AdminAccount? Admin { get; set; }
}
