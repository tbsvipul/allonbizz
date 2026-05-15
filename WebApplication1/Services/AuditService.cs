using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class AuditService : IAuditService
{
    private readonly AppDbContext _db;
    private readonly ILogger<AuditService> _logger;

    public AuditService(AppDbContext db, ILogger<AuditService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task LogAsync(Guid adminId, string action, string targetEntity, string targetId, string? ipAddress, string? userAgent)
    {
        var auditLog = new AuditLog
        {
            AdminId = adminId,
            Action = action,
            TargetEntity = targetEntity,
            TargetId = targetId,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            Timestamp = DateTime.UtcNow
        };

        if (adminId != Guid.Empty)
        {
            _db.AuditLogs.Add(auditLog);
            await _db.SaveChangesAsync();
        }

        _logger.LogDebug("Audit: {Action} on {Entity}/{Id} by {AdminId}", action, targetEntity, targetId, adminId);
    }
}
