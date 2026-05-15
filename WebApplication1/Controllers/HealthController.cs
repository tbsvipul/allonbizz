using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/health")]
[AllowAnonymous]
public class HealthController : ControllerBase
{
    [HttpGet("ping")]
    public IActionResult Ping()
    {
        return Ok(ApiResponse<object>.Ok(new 
        { 
            status = "Online", 
            timestamp = DateTime.UtcNow
        }, "Backend is reachable"));
    }
}
