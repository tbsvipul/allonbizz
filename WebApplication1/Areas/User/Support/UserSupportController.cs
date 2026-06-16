using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Support;
using routent.AdminAPI.Services.Interfaces;
using System.Security.Claims;

namespace routent.AdminAPI.Areas.User.Controllers;

[ApiController]
[Route("api/v1/user/support")]
[Authorize]
public class UserSupportController : ControllerBase
{
    private readonly ISupportTicketService _ticketService;

    public UserSupportController(ISupportTicketService ticketService)
    {
        _ticketService = ticketService;
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpPost]
    public async Task<IActionResult> CreateTicket([FromBody] CreateSupportTicketDto dto)
    {
        var ticket = await _ticketService.CreateTicketAsync(GetUserId(), "customer", dto);
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
