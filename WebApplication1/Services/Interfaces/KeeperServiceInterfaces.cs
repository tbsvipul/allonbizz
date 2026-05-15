using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.DTOs.Common;

namespace allonbiz.AdminAPI.Services.Interfaces;

public interface IKeeperProfileService
{
    Task<KeeperProfileDto> GetProfileAsync(Guid keeperId);
    Task UpdateProfileAsync(Guid keeperId, UpdateKeeperProfileDto dto);
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
    Task BulkUploadOffersAsync(Guid keeperId, Stream csvStream);
}

public interface IKeeperDashboardService
{
    Task<KeeperDashboardDto> GetDashboardAsync(Guid keeperId);
    Task<KeeperTrafficDto> GetTrafficAnalyticsAsync(Guid shopId);
    Task<KeeperAnalyticsDto> GetAnalyticsAsync(Guid keeperId);
}
