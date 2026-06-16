using routent.AdminAPI.Data;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace routent.AdminAPI.Services;

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
        if (adminId == Guid.Empty)
        {
            _logger.LogDebug("Audit skipped for {Action} because admin id is empty", action);
            return;
        }

        var adminExists = await _db.AdminAccounts
            .AsNoTracking()
            .AnyAsync(admin => admin.AdminId == adminId);

        if (!adminExists)
        {
            _logger.LogWarning(
                "Audit skipped for {Action} on {Entity}/{Id} because admin account {AdminId} was not found",
                action,
                targetEntity,
                targetId,
                adminId);
            return;
        }

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

        _db.AuditLogs.Add(auditLog);
        await _db.SaveChangesAsync();

        _logger.LogDebug("Audit: {Action} on {Entity}/{Id} by {AdminId}", action, targetEntity, targetId, adminId);
    }
}
