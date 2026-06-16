using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace routent.AdminAPI.Models.Entities;

public class SupportTicketMessage
{
    [Key]
    public Guid MessageId { get; set; } = Guid.NewGuid();
    public Guid TicketId { get; set; }
    public Guid SenderId { get; set; }
    public string SenderRole { get; set; } = string.Empty; // "User", "Admin"
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public SupportTicket? Ticket { get; set; }
}
