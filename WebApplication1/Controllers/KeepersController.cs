using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/keepers")]
[Authorize]
public class KeepersController : ControllerBase
{
    private readonly IKeeperService _keeperService;
    public KeepersController(IKeeperService keeperService) => _keeperService = keeperService;

    [HttpGet("pending")]
    [RequirePermission(Permissions.KeepersView)]
    public async Task<IActionResult> GetPending([FromQuery] KeeperListQueryDto query)
        => Ok(ApiResponse<PagedResponse<KeeperApplicationListItemDto>>.Ok(await _keeperService.GetPendingKeepersAsync(query, HttpContext.RequestAborted)));

    [HttpGet("pending/{keeperId:guid}")]
    [RequirePermission(Permissions.KeepersView)]
    public async Task<IActionResult> GetPendingDetail(Guid keeperId)
        => Ok(ApiResponse<KeeperApplicationDetailDto>.Ok(await _keeperService.GetPendingKeeperDetailAsync(keeperId, HttpContext.RequestAborted)));

    [HttpPost("{keeperId:guid}/approve")]
    [RequirePermission(Permissions.KeepersApprove)]
    public async Task<IActionResult> Approve(Guid keeperId, [FromBody] ApproveKeeperDto dto)
    {
        await _keeperService.ApproveKeeperAsync(keeperId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "Keeper approved successfully"));
    }

    [HttpPost("{keeperId:guid}/reject")]
    [RequirePermission(Permissions.KeepersReject)]
    public async Task<IActionResult> Reject(Guid keeperId, [FromBody] RejectKeeperDto dto)
    {
        await _keeperService.RejectKeeperAsync(keeperId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "Keeper rejected"));
    }

    [HttpPost("{keeperId:guid}/request-info")]
    [RequirePermission(Permissions.KeepersView)]
    public async Task<IActionResult> RequestInfo(Guid keeperId, [FromBody] RequestInfoDto dto)
    {
        await _keeperService.RequestMoreInfoAsync(keeperId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{keeperId:guid}/hold")]
    [RequirePermission(Permissions.KeepersApprove)]
    public async Task<IActionResult> Hold(Guid keeperId, [FromBody] HoldApplicationDto dto)
    {
        await _keeperService.HoldApplicationAsync(keeperId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{keeperId:guid}/verify-document/{docId:guid}")]
    [RequirePermission(Permissions.KeepersApprove)]
    public async Task<IActionResult> VerifyDocument(Guid keeperId, Guid docId, [FromBody] VerifyDocumentDto dto)
    {
        await _keeperService.VerifyDocumentAsync(keeperId, docId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("verified")]
    [RequirePermission(Permissions.KeepersView)]
    public async Task<IActionResult> GetVerified([FromQuery] KeeperListQueryDto query)
        => Ok(ApiResponse<PagedResponse<KeeperApplicationListItemDto>>.Ok(await _keeperService.GetVerifiedKeepersAsync(query, HttpContext.RequestAborted)));

    [HttpGet("{keeperId:guid}")]
    [RequirePermission(Permissions.KeepersView)]
    public async Task<IActionResult> GetDetail(Guid keeperId)
        => Ok(ApiResponse<KeeperApplicationDetailDto>.Ok(await _keeperService.GetKeeperDetailAsync(keeperId, HttpContext.RequestAborted)));

    [HttpPost("{keeperId:guid}/suspend")]
    [RequirePermission(Permissions.KeepersSuspend)]
    public async Task<IActionResult> Suspend(Guid keeperId, [FromBody] SuspendKeeperDto dto)
    {
        await _keeperService.SuspendKeeperAsync(keeperId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{keeperId:guid}/schedule-audit")]
    [RequirePermission(Permissions.KeepersApprove)]
    public async Task<IActionResult> ScheduleAudit(Guid keeperId, [FromBody] ScheduleAuditDto dto)
    {
        await _keeperService.ScheduleAuditAsync(keeperId, dto, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }
}
