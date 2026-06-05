using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Support;

namespace allonbiz.AdminAPI.Services.Interfaces;

public interface ISupportTicketService
{
    Task<SupportTicketDetailDto> CreateTicketAsync(Guid userId, string role, CreateSupportTicketDto dto, CancellationToken ct = default);
    Task<PagedResponse<SupportTicketSummaryDto>> GetUserTicketsAsync(Guid userId, PaginationParams paging, CancellationToken ct = default);
    Task<PagedResponse<SupportTicketSummaryDto>> GetAdminTicketsAsync(string? status, PaginationParams paging, CancellationToken ct = default);
    Task<SupportTicketDetailDto> GetTicketDetailsAsync(Guid ticketId, Guid? userId = null, CancellationToken ct = default);
    Task<SupportTicketMessageDto> ReplyToTicketAsync(Guid ticketId, Guid senderId, string senderRole, string message, CancellationToken ct = default);
    Task UpdateTicketStatusAsync(Guid ticketId, string status, CancellationToken ct = default);
    Task<int> GetOpenTicketCountAsync(CancellationToken ct = default);
}
