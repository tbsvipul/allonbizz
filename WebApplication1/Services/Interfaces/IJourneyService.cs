using allonbiz.AdminAPI.DTOs.Users;

namespace allonbiz.AdminAPI.Services.Interfaces;

public interface IJourneyService
{
    Task<Guid> StartJourneyAsync(Guid userId, StartJourneyDto dto);
    Task<List<JourneyRecommendationResponse>> GetNearByShopsAsync(Guid journeyId, double lat, double lng, double radiusKm = 5);
    Task<bool> UpdateJourneyProgressAsync(Guid journeyId, UpdateJourneyProgressDto dto);
    Task<bool> EndJourneyAsync(Guid journeyId, EndJourneyDto dto);
    Task<List<JourneyHistoryDto>> GetUserJourneysAsync(Guid userId);
}
