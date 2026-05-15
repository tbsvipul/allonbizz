using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Users;

public class ReviewDto
{
    public Guid ReviewId { get; set; }
    public Guid UserId { get; set; }
    public string UserFullName { get; set; } = string.Empty;
    public Guid? ShopId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public Guid? OfferId { get; set; }
    public string? OfferTitle { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public string? Reply { get; set; }
    public DateTime? RepliedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class SubmitReviewDto
{
    public Guid? ShopId { get; set; }
    public Guid? OfferId { get; set; }
    [Range(1, 5)]
    public int Rating { get; set; }
    [StringLength(500)]
    public string? Comment { get; set; }
}

public class ReviewReplyDto
{
    [Required]
    [StringLength(500)]
    public string Reply { get; set; } = string.Empty;
}
