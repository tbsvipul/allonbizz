using allonbiz.AdminAPI.DTOs.Common;

namespace allonbiz.AdminAPI.DTOs.Admin;

public class AdminOfferListQueryDto : PaginationParams
{
    public string? Search { get; set; }
    public string? Status { get; set; }
}

public class AdminOfferListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string KeeperName { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int Redemptions { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UpdateOfferStatusDto
{
    public string Status { get; set; } = string.Empty;
}
