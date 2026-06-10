using allonbiz.AdminAPI.DTOs.Public;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Common;

namespace allonbiz.AdminAPI.Services.Interfaces;

public interface IReviewService
{
    Task<PagedResponse<ReviewDto>> GetReviewsAsync(Guid? shopId, Guid? offerId, PaginationParams paging, bool publishedOnly = false, Guid? keeperId = null);
    Task ReplyToReviewAsync(Guid reviewId, ReviewReplyDto dto, Guid? keeperId = null);
    Task SubmitReviewAsync(Guid userId, SubmitReviewDto dto);
    Task<ReviewStatsDto> GetReviewStatsAsync(Guid? shopId = null, Guid? keeperId = null);
    Task<List<ShopStatsDto>> GetShopsReviewStatsAsync(Guid? keeperId = null);
}



public interface IAdminPanelService
{
    Task<AdminDashboardSummaryDto> GetDashboardSummaryAsync();
    Task<PagedResponse<JourneyHistoryDto>> GetJourneysAsync(PaginationParams paging);
}

public interface IRuleService
{
    Task<List<PlatformRuleDto>> GetRulesAsync();
    Task AddRuleAsync(CreateRuleDto dto);
}

public interface IPlacesService
{
    Task<List<PlaceSearchResponseDto>> SearchPlacesAsync(string query);
    Task<List<TrendingOfferDto>> GetTrendingOffersAsync();
}
