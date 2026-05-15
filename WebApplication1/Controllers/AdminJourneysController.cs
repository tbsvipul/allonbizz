using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/journeys")]
[Authorize]
public class AdminJourneysController : ControllerBase
{
    private readonly IAdminJourneyService _journeyService;
    public AdminJourneysController(IAdminJourneyService journeyService) => _journeyService = journeyService;

    /// <summary>List all journeys with optional search, status filter, and pagination.</summary>
    [HttpGet]
    [RequirePermission(Permissions.JourneysView)]
    public async Task<IActionResult> GetJourneys([FromQuery] AdminJourneyListQueryDto query)
    {
        var result = await _journeyService.GetJourneysAsync(query);
        return Ok(ApiResponse<PagedResponse<AdminJourneyListDto>>.Ok(result));
    }

    /// <summary>Get a single journey with full detail.</summary>
    [HttpGet("{journeyId:guid}")]
    [RequirePermission(Permissions.JourneysView)]
    public async Task<IActionResult> GetJourneyDetail(Guid journeyId)
    {
        var detail = await _journeyService.GetJourneyDetailAsync(journeyId);
        return Ok(ApiResponse<AdminJourneyDetailDto>.Ok(detail));
    }

    /// <summary>Delete a journey record.</summary>
    [HttpDelete("{journeyId:guid}")]
    [RequirePermission(Permissions.JourneysDelete)]
    public async Task<IActionResult> DeleteJourney(Guid journeyId)
    {
        await _journeyService.DeleteJourneyAsync(journeyId);
        return Ok(ApiResponse<object?>.Ok(null, "Journey deleted successfully"));
    }
}
