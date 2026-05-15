using allonbiz.AdminAPI.DTOs.Common;

namespace allonbiz.AdminAPI.DTOs.Admin;

public class AdminReviewListQueryDto : PaginationParams
{
    public Guid? ShopId { get; set; }
    public string? Status { get; set; }
}

public class AdminReviewSummaryDto
{
    public Guid ReviewId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string? Reply { get; set; }
    public DateTime? RepliedAt { get; set; }
}

public class UpdateReviewStatusDto
{
    public string Status { get; set; } = string.Empty;
}
