using System.Security.Claims;
using routent.AdminAPI.DTOs.Admin;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Shops;
using routent.AdminAPI.DTOs.Tags;
using routent.AdminAPI.DTOs.System;
using routent.AdminAPI.DTOs.Settings;
using routent.AdminAPI.DTOs.Users;

namespace routent.AdminAPI.Services.Interfaces;

public interface ISystemService {
    Task<SystemHealthDto> GetHealthAsync(CancellationToken ct = default);
    Task<PagedResponse<ErrorLog>> GetErrorLogsAsync(PaginationParams paging, CancellationToken ct = default);
    Task ResolveErrorAsync(Guid logId, ResolveErrorDto dto, CancellationToken ct = default);
    Task<ApiPerformanceDto> GetApiPerformanceAsync(ApiPerformanceQueryDto query, CancellationToken ct = default);
    Task<SystemAlertsDto> GetAlertsAsync(CancellationToken ct = default);
    Task<PagedResponse<AuditLog>> GetAuditLogsAsync(PaginationParams paging, CancellationToken ct = default);
    Task<MaintenanceModeStatusDto> ToggleMaintenanceModeAsync(ToggleMaintenanceModeDto dto, CancellationToken ct = default);
    Task<routent.AdminAPI.DTOs.System.SystemConfigDto> GetConfigAsync(CancellationToken ct = default);
}

public interface ISettingsService {
    Task<SystemConfigDto> GetSettingsAsync(CancellationToken ct = default);
    Task UpdateSettingsAsync(UpdateSettingsDto dto, CancellationToken ct = default);
    Task<SecuritySettingsDto> GetSecuritySettingsAsync(CancellationToken ct = default);
    Task UpdateSecuritySettingsAsync(UpdateSecurityDto dto, CancellationToken ct = default);
    Task<PagedResponse<AdminListItemDto>> GetAdminsAsync(AdminListQueryDto query, CancellationToken ct = default);
    Task<AdminDetailDto> CreateAdminAsync(CreateAdminRequestDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task<AdminDetailDto> GetAdminAsync(Guid adminId, CancellationToken ct = default);
    Task UpdateAdminAsync(Guid adminId, UpdateAdminRequestDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task DeleteAdminAsync(Guid adminId, Guid actorAdminId, CancellationToken ct = default);
    Task ResetAdminPasswordAsync(Guid adminId, Guid actorAdminId, CancellationToken ct = default);
    Task TerminateAdminSessionsAsync(Guid adminId, Guid actorAdminId, CancellationToken ct = default);
}

public interface IFirestoreService {
    Task SyncCategoryAsync(Category category, CancellationToken ct = default);
    Task DeleteCategoryAsync(string categoryId, CancellationToken ct = default);
    Task<int> SyncAllCategoriesAsync(IEnumerable<Category> categories, CancellationToken ct = default);
    
    Task SyncOfferAsync(Offer offer, CancellationToken ct = default);
    Task DeleteOfferAsync(string offerId, CancellationToken ct = default);
    
    Task SyncJourneyAsync(Journey journey, CancellationToken ct = default);
}

public interface IShopService {
    Task<PagedResponse<ShopSummaryDto>> GetShopsAsync(ShopListQueryDto query, CancellationToken ct = default);
    Task<ShopDetailDto?> GetShopAsync(Guid shopId, CancellationToken ct = default);
    Task<ShopDetailDto> CreateShopAsync(CreateShopRequestDto dto, CancellationToken ct = default);
    Task UpdateShopAsync(Guid shopId, UpdateShopRequestDto dto, CancellationToken ct = default);
    Task DeleteShopAsync(Guid shopId, CancellationToken ct = default);
    Task UpdateShopStatusAsync(Guid shopId, UpdateShopStatusDto dto, CancellationToken ct = default);
    Task VerifyShopAsync(Guid shopId, VerifyShopRequestDto dto, CancellationToken ct = default);
    Task UnverifyShopAsync(Guid shopId, CancellationToken ct = default);
    Task ApproveShopAsync(Guid shopId, CancellationToken ct = default);
    Task RejectShopAsync(Guid shopId, RejectShopRequestDto dto, CancellationToken ct = default);
    Task ReapplyShopAsync(Guid shopId, CancellationToken ct = default);
    Task<List<ShopSummaryDto>> GetShopsByKeeperAsync(Guid keeperId, CancellationToken ct = default);
    Task AssignTagsAsync(Guid shopId, AssignTagsDto dto, CancellationToken ct = default);
    Task<bool> ToggleShopOpenAsync(Guid shopId, CancellationToken ct = default);
}

public interface ITagService {
    Task<List<TagDetailDto>> GetTagsAsync(string? type = null, CancellationToken ct = default);
    Task<TagDetailDto> GetTagAsync(Guid tagId, CancellationToken ct = default);
    Task<TagDetailDto> CreateTagAsync(CreateTagRequestDto dto, CancellationToken ct = default);
    Task UpdateTagAsync(Guid tagId, UpdateTagRequestDto dto, CancellationToken ct = default);
    Task DeleteTagAsync(Guid tagId, CancellationToken ct = default);
}

public interface INotificationService {
    Task<PagedResponse<NotificationSummaryDto>> GetNotificationsAsync(PaginationParams paging, string? status = null, CancellationToken ct = default);
    Task<PagedResponse<UserNotificationDto>> GetUserNotificationsAsync(Guid userId, string role, PaginationParams paging, CancellationToken ct = default);
    Task MarkUserNotificationReadAsync(Guid userId, Guid notificationId, CancellationToken ct = default);
    Task DeleteUserNotificationAsync(Guid userId, Guid notificationId, CancellationToken ct = default);
    Task<int> GetUnreadNotificationCountAsync(Guid userId, string role, CancellationToken ct = default);
    Task<NotificationDetailDto> GetNotificationByIdAsync(Guid notificationId, CancellationToken ct = default);
    Task<NotificationDetailDto> CreateNotificationAsync(CreateNotificationDto dto, Guid adminId, CancellationToken ct = default);
    Task UpdateNotificationAsync(Guid notificationId, UpdateNotificationDto dto, CancellationToken ct = default);
    Task DeleteNotificationAsync(Guid notificationId, CancellationToken ct = default);
    Task SendNotificationAsync(Guid notificationId, Guid adminId, CancellationToken ct = default);
    Task<NotificationStatsDto> GetNotificationStatsAsync(CancellationToken ct = default);
}

public interface IAdminOfferService
{
    Task<PagedResponse<AdminOfferListItemDto>> GetOffersAsync(AdminOfferListQueryDto query, CancellationToken ct = default);
    Task UpdateStatusAsync(Guid offerId, UpdateOfferStatusDto dto, CancellationToken ct = default);
    Task DeleteAsync(Guid offerId, CancellationToken ct = default);
}

public interface IAdminReviewService
{
    Task<PagedResponse<AdminReviewSummaryDto>> GetReviewsAsync(AdminReviewListQueryDto query, CancellationToken ct = default);
    Task UpdateStatusAsync(Guid reviewId, UpdateReviewStatusDto dto, CancellationToken ct = default);
}

public interface IAdminJourneyService
{
    Task<PagedResponse<AdminJourneyListDto>> GetJourneysAsync(AdminJourneyListQueryDto query, CancellationToken ct = default);
    Task<AdminJourneyDetailDto> GetJourneyDetailAsync(Guid journeyId, CancellationToken ct = default);
    Task DeleteJourneyAsync(Guid journeyId, CancellationToken ct = default);
}
