using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Shops;

namespace allonbiz.AdminAPI.DTOs.Users;

public class AdminUserProfileDto
{
    public UserDetailDto Summary { get; set; } = new();
    public UserActivityDto Activity { get; set; } = new();
    public List<LoginHistoryItemDto> LoginHistory { get; set; } = new();
    public CustomerUserProfileDto? Customer { get; set; }
    public KeeperUserProfileDto? Keeper { get; set; }
}

public class CustomerUserProfileDto
{
    public List<JourneyHistoryDto> Journeys { get; set; } = new();
    public List<ReviewDto> Reviews { get; set; } = new();
}

public class KeeperUserProfileDto
{
    public Guid KeeperId { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string? BusinessLicense { get; set; }
    public string? GstNumber { get; set; }
    public string? PanNumber { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public List<KeeperDocumentDto> Documents { get; set; } = new();
    public List<ShopSummaryDto> Shops { get; set; } = new();
    public List<AdminOfferListItemDto> Offers { get; set; } = new();
    public List<AdminReviewSummaryDto> ShopReviews { get; set; } = new();
}

