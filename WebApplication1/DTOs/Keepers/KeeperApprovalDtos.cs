using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class ApproveKeeperDto
{
    public string? Notes { get; set; }
}

public class RejectKeeperDto
{
    [Required]
    public string Reason { get; set; } = string.Empty;
}

public class RequestInfoDto
{
    [Required]
    public string Message { get; set; } = string.Empty;
}

public class HoldApplicationDto
{
    public string? Reason { get; set; }
    public DateTime? HoldUntil { get; set; }
}

public class VerifyDocumentDto
{
    public bool IsVerified { get; set; }
    public string? Notes { get; set; }
}

public class ScheduleAuditDto
{
    public DateTime AuditDate { get; set; }
    public string? Notes { get; set; }
}

public class SuspendKeeperDto
{
    [Required]
    public string Reason { get; set; } = string.Empty;
}

public class KeeperListQueryDto : allonbiz.AdminAPI.DTOs.Common.PaginationParams
{
    public string? Search { get; set; }
}

public class KeeperDocumentDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
}

public class KeeperReviewMessageHistoryDto
{
    public string MessageId { get; set; } = string.Empty;
    public string MessageType { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string AdminName { get; set; } = string.Empty;
    public bool IsReadByKeeper { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class KeeperApplicationListItemDto
{
    public Guid Id { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Location { get; set; } = "N/A";
    public DateTime AppliedDate { get; set; }
    public List<KeeperDocumentDto> Documents { get; set; } = new();
}

public class KeeperApplicationDetailDto : KeeperApplicationListItemDto
{
    public Guid UserId { get; set; }
    public string? BusinessLicense { get; set; }
    public string? GstNumber { get; set; }
    public string? PanNumber { get; set; }
    public string? SocialLinksJson { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public List<KeeperReviewMessageHistoryDto> ReviewMessages { get; set; } = new();
}
