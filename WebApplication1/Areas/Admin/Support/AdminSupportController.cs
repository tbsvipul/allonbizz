using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Support;
using routent.AdminAPI.Services.Interfaces;
using System.Security.Claims;
using routent.AdminAPI.Constants;
using routent.AdminAPI.Helpers;
using routent.AdminAPI.Filters;

namespace routent.AdminAPI.Areas.Admin.Controllers;

[ApiController]
[Route("api/v1/admin/support")]
[Authorize]
public class AdminSupportController : ControllerBase
{
    private readonly ISupportTicketService _ticketService;

    public AdminSupportController(ISupportTicketService ticketService)
    {
        _ticketService = ticketService;
    }

    private Guid GetAdminId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetTickets([FromQuery] PaginationParams paging, [FromQuery] string? status)
    {
        var result = await _ticketService.GetAdminTicketsAsync(status, paging);
        return Ok(ApiResponse<PagedResponse<SupportTicketSummaryDto>>.Ok(result));
    }

    [HttpGet("{id}")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetTicket(Guid id)
    {
        var ticket = await _ticketService.GetTicketDetailsAsync(id);
        return Ok(ApiResponse<SupportTicketDetailDto>.Ok(ticket));
    }

    [HttpPost("{id}/reply")]
    [RequirePermission(Permissions.SystemEdit)]
    public async Task<IActionResult> ReplyToTicket(Guid id, [FromBody] SupportTicketReplyDto dto)
    {
        var adminId = GetAdminId();
        var message = await _ticketService.ReplyToTicketAsync(id, adminId, "Admin", dto.Message);
        return Ok(ApiResponse<SupportTicketMessageDto>.Ok(message));
    }

    [HttpPut("{id}/status")]
    [RequirePermission(Permissions.SystemEdit)]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] string status)
    {
        await _ticketService.UpdateTicketStatusAsync(id, status);
        return Ok(ApiResponse<object>.Ok(null, "Status updated successfully"));
    }

    [HttpGet("unread-count")]
    [RequirePermission(Permissions.SystemView)]
    public async Task<IActionResult> GetUnreadCount()
    {
        var count = await _ticketService.GetOpenTicketCountAsync();
        return Ok(ApiResponse<object>.Ok(new { unreadCount = count }));
    }
}
