using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Support;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Security.Claims;

namespace allonbiz.AdminAPI.Areas.Keeper.Controllers;

[ApiController]
[Route("api/v1/keeper/support")]
[Authorize]
public class KeeperSupportController : ControllerBase
{
    private readonly ISupportTicketService _ticketService;

    public KeeperSupportController(ISupportTicketService ticketService)
    {
        _ticketService = ticketService;
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpPost]
    public async Task<IActionResult> CreateTicket([FromBody] CreateSupportTicketDto dto)
    {
        var ticket = await _ticketService.CreateTicketAsync(GetUserId(), "keeper", dto);
        return Ok(ApiResponse<SupportTicketDetailDto>.Ok(ticket, "Ticket created successfully"));
    }

    [HttpGet]
    public async Task<IActionResult> GetTickets([FromQuery] PaginationParams paging)
    {
        var result = await _ticketService.GetUserTicketsAsync(GetUserId(), paging);
        return Ok(ApiResponse<PagedResponse<SupportTicketSummaryDto>>.Ok(result));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetTicket(Guid id)
    {
        var ticket = await _ticketService.GetTicketDetailsAsync(id, GetUserId());
        return Ok(ApiResponse<SupportTicketDetailDto>.Ok(ticket));
    }

    [HttpPost("{id}/reply")]
    public async Task<IActionResult> ReplyToTicket(Guid id, [FromBody] SupportTicketReplyDto dto)
    {
        var message = await _ticketService.ReplyToTicketAsync(id, GetUserId(), "User", dto.Message);
        return Ok(ApiResponse<SupportTicketMessageDto>.Ok(message));
    }
}
