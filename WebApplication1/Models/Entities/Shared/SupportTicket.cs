using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace routent.AdminAPI.Models.Entities;

public class SupportTicket
{
    [Key]
    public Guid TicketId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Role { get; set; } = string.Empty; // "customer" or "keeper"
    public string Subject { get; set; } = string.Empty;
    public string Status { get; set; } = "Open"; // Open, InProgress, Closed
    public string Priority { get; set; } = "Normal"; // Low, Normal, High
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<SupportTicketMessage> Messages { get; set; } = new List<SupportTicketMessage>();
}
