using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using routent.AdminAPI.Data;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.Support;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Models.Enums;
using routent.AdminAPI.Services.Interfaces;

namespace routent.AdminAPI.Infrastructure.Support;

public class SupportTicketService : ISupportTicketService
{
    private readonly AppDbContext _db;

    public SupportTicketService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<SupportTicketDetailDto> CreateTicketAsync(Guid userId, string role, CreateSupportTicketDto dto, CancellationToken ct = default)
    {
        var ticket = new SupportTicket
        {
            UserId = userId,
            Role = role,
            Subject = dto.Subject,
            Priority = dto.Priority,
            Status = "Open"
        };

        _db.SupportTickets.Add(ticket);

        var message = new SupportTicketMessage
        {
            TicketId = ticket.TicketId,
            SenderId = userId,
            SenderRole = "User",
            Message = dto.Message
        };

        _db.SupportTicketMessages.Add(message);
        await _db.SaveChangesAsync(ct);

        return await GetTicketDetailsAsync(ticket.TicketId, userId, ct);
    }

    public async Task<PagedResponse<SupportTicketSummaryDto>> GetUserTicketsAsync(Guid userId, PaginationParams paging, CancellationToken ct = default)
    {
        var query = _db.SupportTickets
            .Include(t => t.User)
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.UpdatedAt);

        var total = await query.CountAsync(ct);
        var tickets = await query
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .Select(t => new SupportTicketSummaryDto
            {
                TicketId = t.TicketId,
                UserId = t.UserId,
                Role = t.Role,
                Subject = t.Subject,
                Status = t.Status,
                Priority = t.Priority,
                CreatedAt = t.CreatedAt,
                UpdatedAt = t.UpdatedAt,
                UserName = t.User != null ? t.User.FirstName + " " + t.User.LastName : null
            })
            .ToListAsync(ct);

        return new PagedResponse<SupportTicketSummaryDto>
        {
            Data = tickets,
            Pagination = new PaginationMeta { Page = paging.PageNumber, PageSize = paging.PageSize, TotalCount = total }
        };
    }

    public async Task<PagedResponse<SupportTicketSummaryDto>> GetAdminTicketsAsync(string? status, PaginationParams paging, CancellationToken ct = default)
    {
        var query = _db.SupportTickets.Include(t => t.User).AsQueryable();

        if (!string.IsNullOrEmpty(status))
        {
            query = query.Where(t => t.Status == status);
        }

        query = query.OrderByDescending(t => t.UpdatedAt);

        var total = await query.CountAsync(ct);
        var tickets = await query
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .Select(t => new SupportTicketSummaryDto
            {
                TicketId = t.TicketId,
                UserId = t.UserId,
                Role = t.Role,
                Subject = t.Subject,
                Status = t.Status,
                Priority = t.Priority,
                CreatedAt = t.CreatedAt,
                UpdatedAt = t.UpdatedAt,
                UserName = t.User != null ? t.User.FirstName + " " + t.User.LastName : null
            })
            .ToListAsync(ct);

        return new PagedResponse<SupportTicketSummaryDto>
        {
            Data = tickets,
            Pagination = new PaginationMeta { Page = paging.PageNumber, PageSize = paging.PageSize, TotalCount = total }
        };
    }

    public async Task<SupportTicketDetailDto> GetTicketDetailsAsync(Guid ticketId, Guid? userId = null, CancellationToken ct = default)
    {
        var ticket = await _db.SupportTickets
            .Include(t => t.User)
            .Include(t => t.Messages)
            .FirstOrDefaultAsync(t => t.TicketId == ticketId, ct);

        if (ticket == null || (userId.HasValue && ticket.UserId != userId.Value))
            throw new KeyNotFoundException("Ticket not found");

        return new SupportTicketDetailDto
        {
            TicketId = ticket.TicketId,
            UserId = ticket.UserId,
            Role = ticket.Role,
            Subject = ticket.Subject,
            Status = ticket.Status,
            Priority = ticket.Priority,
            CreatedAt = ticket.CreatedAt,
            UpdatedAt = ticket.UpdatedAt,
            UserName = ticket.User != null ? ticket.User.FirstName + " " + ticket.User.LastName : null,
            Messages = ticket.Messages.OrderBy(m => m.CreatedAt).Select(m => new SupportTicketMessageDto
            {
                MessageId = m.MessageId,
                SenderId = m.SenderId,
                SenderRole = m.SenderRole,
                Message = m.Message,
                CreatedAt = m.CreatedAt
            }).ToList()
        };
    }

    public async Task<SupportTicketMessageDto> ReplyToTicketAsync(Guid ticketId, Guid senderId, string senderRole, string messageText, CancellationToken ct = default)
    {
        var ticket = await _db.SupportTickets.FindAsync(new object[] { ticketId }, ct);
        if (ticket == null) throw new KeyNotFoundException("Ticket not found");

        var message = new SupportTicketMessage
        {
            TicketId = ticket.TicketId,
            SenderId = senderId,
            SenderRole = senderRole,
            Message = messageText
        };

        _db.SupportTicketMessages.Add(message);
        
        ticket.UpdatedAt = DateTime.UtcNow;
        if (senderRole == "Admin")
        {
            if (ticket.Status == "Open")
            {
                ticket.Status = "InProgress";
            }

            AddSupportReplyNotification(ticket, message);
        }
        else if (senderRole == "User" && ticket.Status == "Closed")
        {
            ticket.Status = "Open"; // reopen if user replies
        }

        await _db.SaveChangesAsync(ct);

        return new SupportTicketMessageDto
        {
            MessageId = message.MessageId,
            SenderId = message.SenderId,
            SenderRole = message.SenderRole,
            Message = message.Message,
            CreatedAt = message.CreatedAt
        };
    }

    public async Task UpdateTicketStatusAsync(Guid ticketId, string status, CancellationToken ct = default)
    {
        var ticket = await _db.SupportTickets.FindAsync(new object[] { ticketId }, ct);
        if (ticket == null) throw new KeyNotFoundException("Ticket not found");

        ticket.Status = status;
        ticket.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
    }

    public async Task<int> GetOpenTicketCountAsync(CancellationToken ct = default)
    {
        return await _db.SupportTickets.CountAsync(t => t.Status == "Open", ct);
    }

    private void AddSupportReplyNotification(SupportTicket ticket, SupportTicketMessage message)
    {
        var now = DateTime.UtcNow;
        var notification = new Notification
        {
            NotificationId = Guid.NewGuid(),
            Title = $"Support reply: {ticket.Subject}",
            Message = message.Message,
            Type = NotificationType.Chat,
            Priority = NotificationPriority.Normal,
            SenderType = "Admin",
            SenderId = message.SenderId,
            TargetAudience = ticket.Role == "keeper" ? "keepers" : "customers",
            Status = NotificationStatus.Sent,
            ScheduledAt = now,
            SentAt = now,
            UserId = ticket.UserId,
            SentById = message.SenderId,
            SentByAdminAdminId = message.SenderId,
            RecipientCount = 1,
            MetadataJson = JsonSerializer.Serialize(new
            {
                kind = "supportReply",
                ticketId = ticket.TicketId,
                messageId = message.MessageId,
                subject = ticket.Subject
            }),
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Notifications.Add(notification);
        _db.UserNotifications.Add(new UserNotification
        {
            UserId = ticket.UserId,
            NotificationId = notification.NotificationId,
            IsRead = false,
            IsDeleted = false,
            DeliveryStatus = "Delivered",
            SentAt = now
        });
    }
}
