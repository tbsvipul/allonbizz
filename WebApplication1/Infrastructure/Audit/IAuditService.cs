namespace routent.AdminAPI.Services.Interfaces;

public interface IAuditService
{
    Task LogAsync(Guid adminId, string action, string targetEntity, string targetId, string? ipAddress, string? userAgent);
}
