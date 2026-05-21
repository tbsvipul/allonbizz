using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class KeeperService : IKeeperService
{
    private readonly AppDbContext _db;
    private readonly IRepository<Keeper> _keeperRepo;
    private readonly ILogger<KeeperService> _logger;
    private readonly IAuditService _auditService;

    public KeeperService(
        AppDbContext db,
        IRepository<Keeper> keeperRepo,
        ILogger<KeeperService> logger,
        IAuditService auditService)
    {
        _db = db;
        _keeperRepo = keeperRepo;
        _logger = logger;
        _auditService = auditService;
    }

    public async Task<PagedResponse<KeeperApplicationListItemDto>> GetPendingKeepersAsync(KeeperListQueryDto query, CancellationToken ct = default)
    {
        var keepersQuery = _keeperRepo.Query()
            .AsNoTracking()
            .Include(k => k.User)
            .Include(k => k.Documents)
            .Where(k => k.Status == KeeperStatus.PendingApproval || k.Status == KeeperStatus.OnHold);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            keepersQuery = keepersQuery.Where(k =>
                k.BusinessName.ToLower().Contains(search) ||
                (k.User != null && (
                    k.User.FirstName.ToLower().Contains(search) ||
                    k.User.LastName.ToLower().Contains(search) ||
                    ((k.User.Email ?? string.Empty).ToLower().Contains(search)))));
        }

        var totalCount = await keepersQuery.CountAsync(ct);
        var keepers = await keepersQuery
            .OrderByDescending(k => k.CreatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<KeeperApplicationListItemDto>
        {
            Data = keepers.Select(MapKeeperListItem).ToList(),
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<KeeperApplicationDetailDto> GetPendingKeeperDetailAsync(Guid keeperId, CancellationToken ct = default)
    {
        var keeper = await LoadKeeperAsync(keeperId, ct);
        EnsureKeeperStatus(keeper, "open the pending review for", KeeperStatus.PendingApproval, KeeperStatus.OnHold);
        return MapKeeperDetail(keeper);
    }

    public async Task ApproveKeeperAsync(Guid keeperId, ApproveKeeperDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var keeper = await _keeperRepo.GetByIdAsync(keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
        EnsureKeeperStatus(keeper, "approve", KeeperStatus.PendingApproval, KeeperStatus.OnHold);

        keeper.Status = KeeperStatus.Approved;
        keeper.ApprovedAt = DateTime.UtcNow;
        keeper.RejectionReason = null;
        keeper.HoldReason = null;
        keeper.HoldUntil = null;
        keeper.UpdatedAt = DateTime.UtcNow;

        AddReviewMessage(
            keeperId,
            actorAdminId,
            "approve",
            string.IsNullOrWhiteSpace(dto.Notes) ? "Application approved." : dto.Notes.Trim());

        await _db.SaveChangesAsync(ct);

        await _auditService.LogAsync(actorAdminId, "KEEPER_APPROVE", nameof(Keeper), keeperId.ToString(), null, "N/A");
        _logger.LogInformation("Keeper {KeeperId} approved", keeperId);
    }

    public async Task RejectKeeperAsync(Guid keeperId, RejectKeeperDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var reason = dto.Reason.Trim();
        var keeper = await _keeperRepo.GetByIdAsync(keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
        EnsureKeeperStatus(keeper, "reject", KeeperStatus.PendingApproval, KeeperStatus.OnHold);

        keeper.Status = KeeperStatus.Rejected;
        keeper.RejectionReason = reason;
        keeper.HoldReason = null;
        keeper.HoldUntil = null;
        keeper.ApprovedAt = null;
        keeper.UpdatedAt = DateTime.UtcNow;

        AddReviewMessage(keeperId, actorAdminId, "reject", reason);
        await _db.SaveChangesAsync(ct);

        await _auditService.LogAsync(actorAdminId, "KEEPER_REJECT", nameof(Keeper), keeperId.ToString(), null, "N/A");
        _logger.LogInformation("Keeper {KeeperId} rejected. Reason: {Reason}", keeperId, dto.Reason);
    }

    public async Task RequestMoreInfoAsync(Guid keeperId, RequestInfoDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var keeper = await _keeperRepo.GetByIdAsync(keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
        EnsureKeeperStatus(keeper, "request more information for", KeeperStatus.PendingApproval, KeeperStatus.OnHold);

        var message = dto.Message.Trim();
        keeper.Status = KeeperStatus.OnHold;
        keeper.RejectionReason = null;
        keeper.HoldReason = message;
        keeper.HoldUntil = null;
        keeper.UpdatedAt = DateTime.UtcNow;

        AddReviewMessage(keeperId, actorAdminId, "request_info", message);
        await _db.SaveChangesAsync(ct);

        await _auditService.LogAsync(actorAdminId, "KEEPER_REQUEST_INFO", nameof(Keeper), keeperId.ToString(), null, "N/A");
    }

    public async Task HoldApplicationAsync(Guid keeperId, HoldApplicationDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var keeper = await _keeperRepo.GetByIdAsync(keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
        EnsureKeeperStatus(keeper, "place on hold", KeeperStatus.PendingApproval, KeeperStatus.OnHold);

        var reason = string.IsNullOrWhiteSpace(dto.Reason) ? null : dto.Reason.Trim();
        keeper.Status = KeeperStatus.OnHold;
        keeper.RejectionReason = null;
        keeper.HoldReason = reason;
        keeper.HoldUntil = dto.HoldUntil;
        keeper.ApprovedAt = null;
        keeper.UpdatedAt = DateTime.UtcNow;

        AddReviewMessage(
            keeperId,
            actorAdminId,
            "hold",
            string.IsNullOrWhiteSpace(reason) ? "Application placed on hold." : reason);

        await _db.SaveChangesAsync(ct);

        await _auditService.LogAsync(actorAdminId, "KEEPER_HOLD", nameof(Keeper), keeperId.ToString(), null, "N/A");
    }

    public async Task VerifyDocumentAsync(Guid keeperId, Guid docId, VerifyDocumentDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var keeper = await _keeperRepo.Query()
            .Include(item => item.Documents)
            .FirstOrDefaultAsync(item => item.KeeperId == keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        var document = keeper.Documents.FirstOrDefault(item => item.DocumentId == docId);
        if (document == null && !string.IsNullOrWhiteSpace(keeper.DocumentData) && docId == keeper.KeeperId)
        {
            document = new KeeperDocument
            {
                DocumentId = docId,
                KeeperId = keeperId,
                Name = "Business Document",
                DocumentType = "Primary",
                DocumentReference = KeeperDocumentHelper.NormalizeDocumentReference(keeper.DocumentData),
                Status = "pending",
                CreatedAt = keeper.CreatedAt,
                UpdatedAt = DateTime.UtcNow
            };
            keeper.DocumentData = null;
            _db.KeeperDocuments.Add(document);
        }

        if (document == null)
        {
            throw new KeyNotFoundException($"Document {docId} not found for keeper {keeperId}.");
        }

        document.Status = dto.IsVerified ? "verified" : "rejected";
        document.ReviewNotes = string.IsNullOrWhiteSpace(dto.Notes) ? null : dto.Notes.Trim();
        document.ReviewedByAdminId = actorAdminId;
        document.ReviewedAt = DateTime.UtcNow;
        document.UpdatedAt = DateTime.UtcNow;

        keeper.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        await _auditService.LogAsync(actorAdminId, "KEEPER_DOCUMENT_VERIFY", nameof(KeeperDocument), docId.ToString(), null, "N/A");
    }

    public async Task<PagedResponse<KeeperApplicationListItemDto>> GetVerifiedKeepersAsync(KeeperListQueryDto query, CancellationToken ct = default)
    {
        var keepersQuery = _keeperRepo.Query()
            .AsNoTracking()
            .Include(k => k.User)
            .Include(k => k.Documents)
            .Where(k => k.Status == KeeperStatus.Approved || k.Status == KeeperStatus.Active);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            keepersQuery = keepersQuery.Where(k =>
                k.BusinessName.ToLower().Contains(search) ||
                (k.User != null && (
                    k.User.FirstName.ToLower().Contains(search) ||
                    k.User.LastName.ToLower().Contains(search) ||
                    ((k.User.Email ?? string.Empty).ToLower().Contains(search)))));
        }

        var totalCount = await keepersQuery.CountAsync(ct);
        var keepers = await keepersQuery
            .OrderByDescending(k => k.ApprovedAt ?? k.UpdatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<KeeperApplicationListItemDto>
        {
            Data = keepers.Select(MapKeeperListItem).ToList(),
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<KeeperApplicationDetailDto> GetKeeperDetailAsync(Guid keeperId, CancellationToken ct = default)
    {
        var keeper = await LoadKeeperAsync(keeperId, ct);
        return MapKeeperDetail(keeper);
    }

    public async Task SuspendKeeperAsync(Guid keeperId, SuspendKeeperDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var reason = dto.Reason.Trim();
        var keeper = await _keeperRepo.GetByIdAsync(keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
        EnsureKeeperStatus(keeper, "suspend", KeeperStatus.Approved, KeeperStatus.Active);

        keeper.Status = KeeperStatus.Suspended;
        keeper.RejectionReason = reason;
        keeper.HoldReason = null;
        keeper.HoldUntil = null;
        keeper.UpdatedAt = DateTime.UtcNow;

        AddReviewMessage(keeperId, actorAdminId, "suspend", reason);
        await _db.SaveChangesAsync(ct);

        await _auditService.LogAsync(actorAdminId, "KEEPER_SUSPEND", nameof(Keeper), keeperId.ToString(), null, "N/A");
        _logger.LogInformation("Keeper {KeeperId} suspended. Reason: {Reason}", keeperId, dto.Reason);
    }

    public async Task ScheduleAuditAsync(Guid keeperId, ScheduleAuditDto dto, Guid actorAdminId, CancellationToken ct = default)
    {
        var keeper = await _keeperRepo.GetByIdAsync(keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
        EnsureKeeperStatus(keeper, "schedule an audit for", KeeperStatus.Approved, KeeperStatus.Active);

        _db.KeeperAuditSchedules.Add(new KeeperAuditSchedule
        {
            KeeperId = keeperId,
            RequestedByAdminId = actorAdminId,
            AuditDate = dto.AuditDate,
            Notes = string.IsNullOrWhiteSpace(dto.Notes) ? null : dto.Notes.Trim(),
            Status = "scheduled",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "KEEPER_AUDIT_SCHEDULE", nameof(KeeperAuditSchedule), keeperId.ToString(), null, "N/A");
    }

    private async Task<Keeper> LoadKeeperAsync(Guid keeperId, CancellationToken ct)
    {
        return await _keeperRepo.Query()
            .Include(k => k.User)
            .Include(k => k.Documents)
            .Include(k => k.ReviewMessages)
            .ThenInclude(message => message.Admin)
            .Include(k => k.Shops)
            .FirstOrDefaultAsync(k => k.KeeperId == keeperId, ct)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");
    }

    private static KeeperApplicationListItemDto MapKeeperListItem(Keeper keeper)
    {
        return new KeeperApplicationListItemDto
        {
            Id = keeper.KeeperId,
            BusinessName = keeper.BusinessName,
            OwnerName = keeper.User != null ? $"{keeper.User.FirstName} {keeper.User.LastName}".Trim() : "Unknown",
            Email = keeper.User?.Email ?? "N/A",
            Category = keeper.BusinessLicense ?? "Unknown",
            Status = keeper.Status.ToString(),
            AppliedDate = keeper.CreatedAt,
            Documents = KeeperDocumentHelper.BuildDocuments(keeper)
        };
    }

    private static KeeperApplicationDetailDto MapKeeperDetail(Keeper keeper)
    {
        return new KeeperApplicationDetailDto
        {
            Id = keeper.KeeperId,
            UserId = keeper.UserId,
            BusinessName = keeper.BusinessName,
            OwnerName = keeper.User != null ? $"{keeper.User.FirstName} {keeper.User.LastName}".Trim() : "Unknown",
            Email = keeper.User?.Email ?? "N/A",
            Category = keeper.BusinessLicense ?? "Unknown",
            AppliedDate = keeper.CreatedAt,
            Documents = KeeperDocumentHelper.BuildDocuments(keeper),
            BusinessLicense = keeper.BusinessLicense,
            GstNumber = keeper.GstNumber,
            PanNumber = keeper.PanNumber,
            SocialLinksJson = keeper.SocialLinksJson,
            Status = keeper.Status.ToString(),
            RejectionReason = keeper.RejectionReason,
            HoldReason = keeper.HoldReason,
            HoldUntil = keeper.HoldUntil,
            ApprovedAt = keeper.ApprovedAt,
            IdentityProofType = keeper.IdentityProofType,
            IdentityProofNumber = keeper.IdentityProofNumber,
            IdentityProofImage = keeper.IdentityProofImage,
            BusinessLicenseNumber = keeper.BusinessLicenseNumber,
            BusinessLicenseImage = keeper.BusinessLicenseImage,
            GstCertificateImage = keeper.GstCertificateImage,
            PanCardImage = keeper.PanCardImage,
            AddressProofType = keeper.AddressProofType,
            AddressProofImage = keeper.AddressProofImage,
            ShopFrontImage = keeper.ShopFrontImage,
            ShopInsideImage = keeper.ShopInsideImage,
            VerificationNotes = keeper.VerificationNotes,
            IsVerified = keeper.IsVerified,
            DeletedAt = keeper.DeletedAt,
            ReviewMessages = keeper.ReviewMessages
                .OrderByDescending(message => message.CreatedAt)
                .Select(message => new KeeperReviewMessageHistoryDto
                {
                    MessageId = message.MessageId.ToString(),
                    MessageType = message.MessageType,
                    Message = message.Message,
                    AdminName = message.Admin != null
                        ? $"{message.Admin.FirstName} {message.Admin.LastName}".Trim()
                        : "Administrator",
                    IsReadByKeeper = message.IsReadByKeeper,
                    CreatedAt = message.CreatedAt
                })
                .ToList()
        };
    }

    private void AddReviewMessage(Guid keeperId, Guid actorAdminId, string messageType, string message)
    {
        _db.KeeperReviewMessages.Add(new KeeperReviewMessage
        {
            KeeperId = keeperId,
            AdminId = actorAdminId,
            MessageType = messageType,
            Message = message,
            CreatedAt = DateTime.UtcNow
        });
    }

    private static void EnsureKeeperStatus(Keeper keeper, string action, params KeeperStatus[] allowedStatuses)
    {
        if (allowedStatuses.Contains(keeper.Status))
        {
            return;
        }

        throw new InvalidOperationException($"Cannot {action} a keeper in {keeper.Status} status.");
    }
}
