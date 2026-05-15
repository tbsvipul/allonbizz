namespace allonbiz.AdminAPI.Models.Entities;

public class ErrorLog
{
    public Guid LogId { get; set; } = Guid.NewGuid();
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string ErrorType { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? StackTrace { get; set; }
    public Guid? UserId { get; set; }
    public string? Endpoint { get; set; }
    public string? HttpMethod { get; set; }
    public string Severity { get; set; } = "medium";  // critical | high | medium | low
    public bool Resolved { get; set; } = false;
    public Guid? ResolvedBy { get; set; }
    public DateTime? ResolvedAt { get; set; }

    // Navigation
    public AdminAccount? Resolver { get; set; }
}
