using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Users;
using routent.AdminAPI.Helpers;
using routent.AdminAPI.Services.Interfaces;

namespace routent.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserDiscoverController : ControllerBase
{
    private readonly IUserDiscoverService _discoverService;

    public UserDiscoverController(IUserDiscoverService discoverService)
    {
        _discoverService = discoverService;
    }

    [HttpGet("discover")]
    public async Task<IActionResult> GetDiscover([FromQuery] UserDiscoverQueryDto query, CancellationToken ct)
    {
        var result = await _discoverService.GetDiscoverAsync(User.GetUserId(), query, ct);
        return Ok(ApiResponse<UserDiscoverResponseDto>.Ok(result));
    }
}
