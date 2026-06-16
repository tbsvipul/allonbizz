using System.ComponentModel.DataAnnotations;

namespace routent.AdminAPI.DTOs.Moderation;

public class ApproveDto
{
    public string? Notes { get; set; }
}

public class RejectDto
{
    [Required]
    public string Reason { get; set; } = string.Empty;
}

public class EditDto
{
    public string? Notes { get; set; }
}

public class EscalateDto
{
    [Required]
    public string Reason { get; set; } = string.Empty;
}

public class DismissReportDto
{
    public string? Reason { get; set; }
}

public class ActionOnReportDto
{
    [Required]
    public string Action { get; set; } = string.Empty;
    public string? Notes { get; set; }
}

public class ModerationQueueQueryDto : routent.AdminAPI.DTOs.Common.PaginationParams
{
    public string? Search { get; set; }
    public string? Status { get; set; }
    public string? ContentType { get; set; }
}

public class ModerationQueueItemDto
{
    public Guid Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string ReportedBy { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public Guid ReferenceId { get; set; }
}

public class ModerationReportQueryDto : routent.AdminAPI.DTOs.Common.PaginationParams
{
    public string? Status { get; set; }
    public string? ItemType { get; set; }
}

public class ModerationReportDto
{
    public Guid ReportId { get; set; }
    public string ReportedItemId { get; set; } = string.Empty;
    public string ItemType { get; set; } = string.Empty;
    public Guid ReportedBy { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? Comments { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public Guid? HandledBy { get; set; }
    public string? ResolutionNote { get; set; }
    public DateTime? ResolvedAt { get; set; }
}

public class ModerationStatsDto
{
    public int PendingQueueItems { get; set; }
    public int ApprovedQueueItems { get; set; }
    public int RejectedQueueItems { get; set; }
    public int PendingReports { get; set; }
    public int ResolvedReports { get; set; }
    public int DismissedReports { get; set; }
}
