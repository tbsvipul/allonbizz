using routent.AdminAPI.DTOs.Categories;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Moderation;
using routent.AdminAPI.DTOs.Analytics;
using routent.AdminAPI.DTOs.Admin;

namespace routent.AdminAPI.Services.Interfaces;

public interface ICategoryService {
    Task<List<CategoryTreeDto>> GetCategoryTreeAsync(bool includeInactive = false, CancellationToken ct = default);
    Task<CategoryTreeDto> CreateCategoryAsync(CreateCategoryRequestDto dto, CancellationToken ct = default);
    Task<CategoryTreeDto> UpdateCategoryAsync(Guid categoryId, UpdateCategoryRequestDto dto, CancellationToken ct = default);
    Task DeleteCategoryAsync(Guid categoryId, Guid? reassignToId = null, CancellationToken ct = default);
    Task ReorderCategoriesAsync(ReorderCategoriesRequestDto dto, CancellationToken ct = default);
    Task<object> GetCategoryAnalyticsAsync(Guid categoryId, CancellationToken ct = default);
    Task<int> SyncAllToFirestoreAsync(CancellationToken ct = default);
}

public interface IModerationService {
    Task<PagedResponse<ModerationQueueItemDto>> GetQueueAsync(ModerationQueueQueryDto query, CancellationToken ct = default);
    Task<ModerationQueueItemDto> GetItemDetailAsync(Guid itemId, CancellationToken ct = default);
    Task ApproveAsync(Guid itemId, ApproveDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task RejectAsync(Guid itemId, RejectDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task EditContentAsync(Guid itemId, EditDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task EscalateAsync(Guid itemId, EscalateDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task HideAsync(Guid itemId, Guid actorAdminId, CancellationToken ct = default);
    Task<PagedResponse<ModerationReportDto>> GetReportsAsync(ModerationReportQueryDto query, CancellationToken ct = default);
    Task DismissReportAsync(Guid reportId, DismissReportDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task TakeActionOnReportAsync(Guid reportId, ActionOnReportDto dto, Guid actorAdminId, CancellationToken ct = default);
    Task<ModerationStatsDto> GetStatsAsync(CancellationToken ct = default);
}

public interface IAnalyticsService {
    Task<UserAnalyticsDto> GetUserAnalyticsAsync(AnalyticsRangeQueryDto? query, CancellationToken ct = default);
    Task<JourneyAnalyticsResponseDto> GetJourneyAnalyticsAsync(AnalyticsRangeQueryDto? query, CancellationToken ct = default);
    Task<RevenueAnalyticsDto> GetRevenueAnalyticsAsync(AnalyticsRangeQueryDto? query, CancellationToken ct = default);
    Task<RealTimeMetricsDto> GetRealTimeMetricsAsync(CancellationToken ct = default);
    Task<List<TrendingAdminOfferDto>> GetTrendingOffersAsync(CancellationToken ct = default);
    Task<List<TrendingAdminShopDto>> GetTrendingShopsAsync(CancellationToken ct = default);
    Task<List<TrendingAdminJourneyDto>> GetTrendingJourneysAsync(CancellationToken ct = default);
    Task<byte[]> GetPrebuiltReportCsvAsync(string reportType, AnalyticsRangeQueryDto? query, CancellationToken ct = default);
    Task<CustomAnalyticsReportDto> GenerateCustomReportAsync(GenerateCustomReportDto dto, CancellationToken ct = default);
    Task<byte[]> GenerateCustomReportCsvAsync(GenerateCustomReportDto dto, CancellationToken ct = default);
    Task<AdminDashboardSummaryDto> GetFullDashboardAsync(CancellationToken ct = default);
}
