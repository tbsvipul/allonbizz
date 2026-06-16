namespace routent.AdminAPI.DTOs.Support;

public class CreateSupportTicketDto
{
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Priority { get; set; } = "Normal";
}

public class SupportTicketReplyDto
{
    public string Message { get; set; } = string.Empty;
}

public class SupportTicketSummaryDto
{
    public Guid TicketId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Priority { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? UserName { get; set; } // Optional for admin view
}

public class SupportTicketMessageDto
{
    public Guid MessageId { get; set; }
    public Guid SenderId { get; set; }
    public string SenderRole { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class SupportTicketDetailDto : SupportTicketSummaryDto
{
    public List<SupportTicketMessageDto> Messages { get; set; } = new();
}
