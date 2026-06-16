using routent.AdminAPI.DTOs.Users;
using routent.AdminAPI.DTOs.Keepers;
using routent.AdminAPI.DTOs.Common;
using System.IO;
using System.Threading;

namespace routent.AdminAPI.Services.Interfaces;

public interface IUserService
{
    Task<PagedResponse<UserDetailDto>> GetUsersAsync(UserListQueryDto query, CancellationToken ct = default);
    Task<UserDetailDto> GetUserDetailAsync(Guid userId, CancellationToken ct = default);
    Task<AdminUserProfileDto> GetUserProfileAsync(Guid userId, CancellationToken ct = default);
    Task<UserActivityDto> GetUserActivityAsync(Guid userId, CancellationToken ct = default);
    Task<PagedResponse<LoginHistoryItemDto>> GetLoginHistoryAsync(Guid userId, PaginationParams paging, CancellationToken ct = default);
    Task UpdateStatusAsync(Guid userId, UpdateStatusRequestDto dto, CancellationToken ct = default);
    Task ForcePasswordResetAsync(Guid userId, CancellationToken ct = default);
    Task Reset2FAAsync(Guid userId, Guid actorAdminId, CancellationToken ct = default);
    Task TerminateSessionsAsync(Guid userId, CancellationToken ct = default);
    Task SuspendUserAsync(Guid userId, SuspendUserRequestDto dto, CancellationToken ct = default);
    Task BanUserAsync(Guid userId, BanUserRequestDto dto, CancellationToken ct = default);
    Task SendWarningAsync(Guid userId, WarnUserRequestDto dto, CancellationToken ct = default);
    Task BulkActionAsync(BulkActionRequestDto dto, CancellationToken ct = default);
    Task ExportToCsvToStreamAsync(Stream outputStream, UserListQueryDto query, CancellationToken ct = default);
    Task ConvertRoleAsync(Guid userId, ConvertRoleRequestDto dto, CancellationToken ct = default);
    Task UnbanUserAsync(Guid userId, CancellationToken ct = default);
    Task UnsuspendUserAsync(Guid userId, CancellationToken ct = default);
}


public interface IKeeperService
{
    Task<PagedResponse<KeeperApplicationListItemDto>> GetPendingKeepersAsync(KeeperListQueryDto query, CancellationToken ct = default);
    Task<KeeperApplicationDetailDto> GetPendingKeeperDetailAsync(Guid keeperId, CancellationToken ct = default);
    Task ApproveKeeperAsync(Guid keeperId, ApproveKeeperDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task RejectKeeperAsync(Guid keeperId, RejectKeeperDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task RequestMoreInfoAsync(Guid keeperId, RequestInfoDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task HoldApplicationAsync(Guid keeperId, HoldApplicationDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task VerifyDocumentAsync(Guid keeperId, Guid docId, VerifyDocumentDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task<PagedResponse<KeeperApplicationListItemDto>> GetVerifiedKeepersAsync(KeeperListQueryDto query, CancellationToken ct = default);
    Task<KeeperApplicationDetailDto> GetKeeperDetailAsync(Guid keeperId, CancellationToken ct = default);
    Task SuspendKeeperAsync(Guid keeperId, SuspendKeeperDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task ScheduleAuditAsync(Guid keeperId, ScheduleAuditDto dto, Guid actorAdminId, CancellationToken ct = default);
}
