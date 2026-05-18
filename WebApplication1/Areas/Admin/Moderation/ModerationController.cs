using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.Moderation;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/moderation")]
[Authorize]
public class ModerationController : ControllerBase
{
    private readonly IModerationService _moderationService;
    public ModerationController(IModerationService moderationService) => _moderationService = moderationService;

    [HttpGet("queue")]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetQueue([FromQuery] ModerationQueueQueryDto query)
        => Ok(ApiResponse<PagedResponse<ModerationQueueItemDto>>.Ok(await _moderationService.GetQueueAsync(query, HttpContext.RequestAborted)));

    [HttpGet("{itemId:guid}")]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetDetail(Guid itemId)
        => Ok(ApiResponse<ModerationQueueItemDto>.Ok(await _moderationService.GetItemDetailAsync(itemId, HttpContext.RequestAborted)));

    [HttpPost("{itemId:guid}/approve")]
    [RequirePermission(Permissions.ModerationApprove)]
    public async Task<IActionResult> Approve(Guid itemId, [FromBody] ApproveDto dto)
    {
        await _moderationService.ApproveAsync(itemId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{itemId:guid}/reject")]
    [RequirePermission(Permissions.ModerationReject)]
    public async Task<IActionResult> Reject(Guid itemId, [FromBody] RejectDto dto)
    {
        await _moderationService.RejectAsync(itemId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPut("{itemId:guid}/edit")]
    [RequirePermission(Permissions.ModerationEdit)]
    public async Task<IActionResult> Edit(Guid itemId, [FromBody] EditDto dto)
    {
        await _moderationService.EditContentAsync(itemId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{itemId:guid}/escalate")]
    [RequirePermission(Permissions.ModerationEscalate)]
    public async Task<IActionResult> Escalate(Guid itemId, [FromBody] EscalateDto dto)
    {
        await _moderationService.EscalateAsync(itemId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{itemId:guid}/hide")]
    [RequirePermission(Permissions.ModerationEdit)]
    public async Task<IActionResult> Hide(Guid itemId)
    {
        await _moderationService.HideAsync(itemId, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("reports")]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetReports([FromQuery] ModerationReportQueryDto query)
        => Ok(ApiResponse<PagedResponse<ModerationReportDto>>.Ok(await _moderationService.GetReportsAsync(query, HttpContext.RequestAborted)));

    [HttpPost("reports/{reportId:guid}/dismiss")]
    [RequirePermission(Permissions.ModerationApprove)]
    public async Task<IActionResult> DismissReport(Guid reportId, [FromBody] DismissReportDto dto)
    {
        await _moderationService.DismissReportAsync(reportId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("reports/{reportId:guid}/action")]
    [RequirePermission(Permissions.ModerationApprove)]
    public async Task<IActionResult> ActionOnReport(Guid reportId, [FromBody] ActionOnReportDto dto)
    {
        await _moderationService.TakeActionOnReportAsync(reportId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("stats")]
    [RequirePermission(Permissions.ModerationView)]
    public async Task<IActionResult> GetStats()
        => Ok(ApiResponse<ModerationStatsDto>.Ok(await _moderationService.GetStatsAsync(HttpContext.RequestAborted)));
}
