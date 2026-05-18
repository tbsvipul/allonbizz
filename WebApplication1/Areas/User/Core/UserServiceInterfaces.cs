using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;

namespace allonbiz.AdminAPI.Services.Interfaces;

public interface IUserProfileService
{
    Task<UserProfileDto> GetProfileAsync(Guid userId);
    Task UpdateProfileAsync(Guid userId, UpdateUserProfileDto dto);
    Task<string> UploadPhotoAsync(Guid userId, Stream photoStream, string fileName);
    Task UpdateFcmTokenAsync(Guid userId, string token);
    Task<UserHomeDto> GetHomeDataAsync(Guid userId, double? lat, double? lng);
}

public interface IRouteService
{
    Task<RouteResponseDto> CalculateRouteAsync(Guid userId, RouteCalculateRequestDto dto);
    Task<List<OfferSummaryDto>> GetOffersAlongRouteAsync(Guid routeId);
    Task<RouteResponseDto> OptimizeRouteAsync(Guid routeId);
    Task<RouteResponseDto?> GetActiveRouteAsync(Guid userId);
    Task<List<RouteResponseDto>> GetRouteHistoryAsync(Guid userId);
}

public interface IOfferService
{
    Task<List<OfferSummaryDto>> GetNearbyOffersAsync(double? lat, double? lng, double? radiusKm = null, string? category = null, IReadOnlyCollection<string>? tags = null);
    Task<OfferDetailDto> GetOfferDetailAsync(Guid offerId, Guid userId);
    Task<Guid> RedeemOfferAsync(Guid offerId, Guid userId);
    Task SaveOfferAsync(Guid offerId, Guid userId);
    Task RateOfferAsync(Guid offerId, Guid userId, int rating, string? comment);
}

public interface IUserHistoryService
{
    Task<List<RedemptionHistoryDto>> GetRedemptionHistoryAsync(Guid userId);
    Task<LoyaltySummaryDto> GetLoyaltyWalletAsync(Guid userId);
    Task<UserSavingsSummaryDto> GetSavingsSummaryAsync(Guid userId);
}

public interface IFavouriteService
{
    Task<List<SavedItemDto>> GetFavouritesAsync(Guid userId);
    Task ToggleFavouriteAsync(Guid userId, ToggleFavouriteDto dto);
}

public interface IChatService
{
    Task<ChatThreadDto> StartChatAsync(Guid userId, Guid keeperId);
}
