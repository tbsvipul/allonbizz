using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Moderation;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class ModerationService : IModerationService
{
    private readonly IRepository<ModerationQueueItem> _queueRepo;
    private readonly IRepository<UserReport> _reportRepo;
    private readonly IAuditService _auditService;

    public ModerationService(
        IRepository<ModerationQueueItem> queueRepo,
        IRepository<UserReport> reportRepo,
        IAuditService auditService)
    {
        _queueRepo = queueRepo;
        _reportRepo = reportRepo;
        _auditService = auditService;
    }

    public async Task<PagedResponse<ModerationQueueItemDto>> GetQueueAsync(ModerationQueueQueryDto query, CancellationToken ct = default)
    {
        var itemsQuery = _queueRepo.Query().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            itemsQuery = itemsQuery.Where(i =>
                i.Title.ToLower().Contains(search) ||
                (i.Preview != null && i.Preview.ToLower().Contains(search)));
        }

        if (!string.IsNullOrWhiteSpace(query.Status))
        {
            itemsQuery = itemsQuery.Where(i => i.Status == query.Status.ToLower());
        }
        else
        {
            itemsQuery = itemsQuery.Where(i => i.Status == "pending" || i.Status == "under_review");
        }

        if (!string.IsNullOrWhiteSpace(query.ContentType))
        {
            itemsQuery = itemsQuery.Where(i => i.ContentType == query.ContentType.ToLower());
        }

        var totalCount = await itemsQuery.CountAsync(ct);
        var items = await itemsQuery
            .OrderByDescending(i => i.SubmittedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<ModerationQueueItemDto>
        {
            Data = items.Select(MapModerationItem).ToList(),
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<ModerationQueueItemDto> GetItemDetailAsync(Guid itemId, CancellationToken ct = default)
    {
        var item = await _queueRepo.GetByIdAsync(itemId, ct);
        if (item == null) throw new KeyNotFoundException($"Item {itemId} not found.");
        return MapModerationItem(item);
    }

    public async Task ApproveAsync(Guid itemId, ApproveDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var item = await RequireQueueItemAsync(itemId, ct);
        EnsureAllowedQueueState(item, "approve", "pending", "under_review");

        item.Status = "approved";
        item.RejectionReason = string.IsNullOrWhiteSpace(dto.Notes) ? null : dto.Notes.Trim();
        item.ReviewedAt = DateTime.UtcNow;
        _queueRepo.Update(item);
        await _queueRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_APPROVE", nameof(ModerationQueueItem), item.ItemId.ToString(), null, "N/A");
    }

    public async Task RejectAsync(Guid itemId, RejectDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var item = await RequireQueueItemAsync(itemId, ct);
        EnsureAllowedQueueState(item, "reject", "pending", "under_review");

        item.Status = "rejected";
        item.RejectionReason = dto.Reason.Trim();
        item.ReviewedAt = DateTime.UtcNow;
        _queueRepo.Update(item);
        await _queueRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_REJECT", nameof(ModerationQueueItem), item.ItemId.ToString(), null, "N/A");
    }

    public async Task EditContentAsync(Guid itemId, EditDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var item = await RequireQueueItemAsync(itemId, ct);
        EnsureAllowedQueueState(item, "edit", "pending", "under_review");

        item.RejectionReason = dto.Notes;
        item.Status = "under_review";
        item.ReviewedAt = DateTime.UtcNow;
        _queueRepo.Update(item);
        await _queueRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_EDIT", nameof(ModerationQueueItem), item.ItemId.ToString(), null, "N/A");
    }

    public async Task EscalateAsync(Guid itemId, EscalateDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var item = await RequireQueueItemAsync(itemId, ct);
        EnsureAllowedQueueState(item, "escalate", "pending", "under_review");

        item.RejectionReason = dto.Reason.Trim();
        item.Status = "under_review";
        item.ReviewedAt = DateTime.UtcNow;
        _queueRepo.Update(item);
        await _queueRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_ESCALATE", nameof(ModerationQueueItem), item.ItemId.ToString(), null, "N/A");
    }

    public async Task HideAsync(Guid itemId, Guid actorAdminId, CancellationToken ct = default)
    {
        var item = await RequireQueueItemAsync(itemId, ct);
        if (string.Equals(item.Status, "rejected", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Only non-rejected moderation items can be hidden.");
        }

        item.Status = "rejected";
        item.ReviewedAt = DateTime.UtcNow;
        _queueRepo.Update(item);
        await _queueRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_HIDE", nameof(ModerationQueueItem), item.ItemId.ToString(), null, "N/A");
    }

    public async Task<PagedResponse<ModerationReportDto>> GetReportsAsync(ModerationReportQueryDto query, CancellationToken ct = default)
    {
        var reportsQuery = _reportRepo.Query().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(query.Status))
        {
            var normalizedStatus = query.Status.Trim().ToLowerInvariant();
            reportsQuery = reportsQuery.Where(report => report.Status == normalizedStatus);
        }

        if (!string.IsNullOrWhiteSpace(query.ItemType))
        {
            var normalizedItemType = query.ItemType.Trim().ToLowerInvariant();
            reportsQuery = reportsQuery.Where(report => report.ItemType == normalizedItemType);
        }

        var totalCount = await reportsQuery.CountAsync(ct);
        var reports = await reportsQuery
            .OrderByDescending(report => report.CreatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(report => new ModerationReportDto
            {
                ReportId = report.ReportId,
                ReportedItemId = report.ReportedItemId,
                ItemType = report.ItemType,
                ReportedBy = report.ReportedBy,
                Reason = report.Reason,
                Comments = report.Comments,
                CreatedAt = report.CreatedAt,
                Status = report.Status,
                HandledBy = report.HandledBy,
                ResolutionNote = report.ResolutionNote,
                ResolvedAt = report.ResolvedAt
            })
            .ToListAsync(ct);

        return new PagedResponse<ModerationReportDto>
        {
            Data = reports,
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task DismissReportAsync(Guid reportId, DismissReportDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var report = await RequireReportAsync(reportId, ct);
        EnsureAllowedReportState(report, "dismiss", "pending", "investigated");

        report.Status = "dismissed";
        report.HandledBy = actorAdminId;
        report.ResolutionNote = dto.Reason?.Trim();
        report.ResolvedAt = DateTime.UtcNow;
        _reportRepo.Update(report);
        await _reportRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_REPORT_DISMISS", nameof(UserReport), report.ReportId.ToString(), null, "N/A");
    }

    public async Task TakeActionOnReportAsync(Guid reportId, ActionOnReportDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var report = await RequireReportAsync(reportId, ct);
        EnsureAllowedReportState(report, "resolve", "pending", "investigated");

        report.Status = "resolved";
        report.HandledBy = actorAdminId;
        report.ResolutionNote = string.IsNullOrWhiteSpace(dto.Notes)
            ? $"Action taken: {dto.Action.Trim()}"
            : $"{dto.Action.Trim()}: {dto.Notes.Trim()}";
        report.ResolvedAt = DateTime.UtcNow;
        _reportRepo.Update(report);
        await _reportRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "MODERATION_REPORT_RESOLVE", nameof(UserReport), report.ReportId.ToString(), null, "N/A");
    }

    public async Task<ModerationStatsDto> GetStatsAsync(CancellationToken ct = default)
    {
        var pending = await _queueRepo.Query().CountAsync(m => m.Status == "pending", ct);
        var approved = await _queueRepo.Query().CountAsync(m => m.Status == "approved", ct);
        var rejected = await _queueRepo.Query().CountAsync(m => m.Status == "rejected", ct);
        var pendingReports = await _reportRepo.Query().CountAsync(r => r.Status == "pending", ct);
        var resolvedReports = await _reportRepo.Query().CountAsync(r => r.Status == "resolved", ct);
        var dismissedReports = await _reportRepo.Query().CountAsync(r => r.Status == "dismissed", ct);

        return new ModerationStatsDto
        {
            PendingQueueItems = pending,
            ApprovedQueueItems = approved,
            RejectedQueueItems = rejected,
            PendingReports = pendingReports,
            ResolvedReports = resolvedReports,
            DismissedReports = dismissedReports
        };
    }

    private static ModerationQueueItemDto MapModerationItem(ModerationQueueItem item)
    {
        return new ModerationQueueItemDto
        {
            Id = item.ItemId,
            Type = item.ContentType,
            Content = item.Preview ?? item.Title,
            ReportedBy = item.SubmittedBy.ToString(),
            Reason = item.FlagReasons.FirstOrDefault() ?? item.RejectionReason ?? "Flagged",
            CreatedAt = item.SubmittedAt,
            Status = item.Status,
            ReferenceId = item.ReferenceId
        };
    }

    private async Task<ModerationQueueItem> RequireQueueItemAsync(Guid itemId, CancellationToken ct)
    {
        return await _queueRepo.GetByIdAsync(itemId, ct)
            ?? throw new KeyNotFoundException($"Item {itemId} not found.");
    }

    private async Task<UserReport> RequireReportAsync(Guid reportId, CancellationToken ct)
    {
        return await _reportRepo.GetByIdAsync(reportId, ct)
            ?? throw new KeyNotFoundException($"Report {reportId} not found.");
    }

    private static void EnsureAllowedQueueState(ModerationQueueItem item, string action, params string[] allowedStates)
    {
        if (!allowedStates.Contains(item.Status, StringComparer.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"Cannot {action} moderation item {item.ItemId} while it is in '{item.Status}' status.");
        }
    }

    private static void EnsureAllowedReportState(UserReport report, string action, params string[] allowedStates)
    {
        if (!allowedStates.Contains(report.Status, StringComparer.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"Cannot {action} report {report.ReportId} while it is in '{report.Status}' status.");
        }
    }
}
