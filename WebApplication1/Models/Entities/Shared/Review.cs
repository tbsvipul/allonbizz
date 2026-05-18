using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class Review
{
    public Guid ReviewId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid? ShopId { get; set; }
    public Guid? OfferId { get; set; }
    public int Rating { get; set; } // 1-5
    public string? Comment { get; set; }
    public ReviewStatus Status { get; set; } = ReviewStatus.Pending;
    public string? Reply { get; set; }
    public DateTime? RepliedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Shop? Shop { get; set; }
    public Offer? Offer { get; set; }
}
