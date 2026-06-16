using routent.AdminAPI.DTOs.Keepers;
using routent.AdminAPI.DTOs.Shops;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Services.Interfaces;

public interface IKeeperProfileService
{
    Task<KeeperProfileDto> GetProfileAsync(Guid keeperId);
    Task UpdateProfileAsync(Guid keeperId, UpdateKeeperProfileDto dto);
    Task<Guid> CreateDocumentAsync(Guid keeperId, UpsertKeeperDocumentDto dto);
    Task UpdateDocumentAsync(Guid keeperId, Guid documentId, UpsertKeeperDocumentDto dto);
    Task DeleteDocumentAsync(Guid keeperId, Guid documentId);
    Task<int> MarkReviewMessagesReadAsync(Guid keeperId);
    Task<Guid> RegisterShopAsync(Guid keeperId, RegisterShopDto dto);
    Task<List<ShopSummaryDto>> GetMyShopsAsync(Guid keeperId);
    Task SyncWithGoogleBusinessAsync(Guid shopId);
}

public interface IKeeperOfferService
{
    Task<List<KeeperOfferDetailDto>> GetMyOffersAsync(Guid keeperId);
    Task<Guid> CreateOfferAsync(Guid keeperId, CreateOfferDto dto);
    Task<KeeperOfferDetailDto> GetOfferDetailAsync(Guid keeperId, Guid offerId);
    Task UpdateOfferAsync(Guid keeperId, Guid offerId, CreateOfferDto dto);
    Task DeleteOfferAsync(Guid keeperId, Guid offerId);
    Task<BulkOfferUploadResultDto> BulkUploadOffersAsync(Guid keeperId, Stream csvStream);
}

public interface IKeeperDashboardService
{
    Task<KeeperDashboardDto> GetDashboardAsync(Guid keeperId);
    Task<KeeperTrafficDto> GetTrafficAnalyticsAsync(Guid keeperId, Guid shopId);
    Task<KeeperAnalyticsDto> GetAnalyticsAsync(Guid keeperId);
}

public interface IKeeperContextService
{
    Task<Keeper> GetRequiredKeeperAsync(Guid userId, CancellationToken ct = default);
    Task<Keeper> GetRequiredActiveKeeperAsync(Guid userId, CancellationToken ct = default);
}
