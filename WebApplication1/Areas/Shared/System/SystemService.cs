using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Data;
using routent.AdminAPI.Data.Interfaces;
using routent.AdminAPI.DTOs.Common;
using routent.AdminAPI.DTOs.System;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Services.Interfaces;

namespace routent.AdminAPI.Services;

public class SystemService : ISystemService
{
    private readonly IRepository<ErrorLog> _errorRepo;
    private readonly IRepository<AuditLog> _auditRepo;
    private readonly AppDbContext _db; // Needed for health check CanConnect
    private readonly IConfiguration _config;

    public SystemService(IRepository<ErrorLog> errorRepo, IRepository<AuditLog> auditRepo, AppDbContext db, IConfiguration config)
    {
        _errorRepo = errorRepo;
        _auditRepo = auditRepo;
        _db = db;
        _config = config;
    }

    public async Task<SystemHealthDto> GetHealthAsync(CancellationToken ct = default)
    {
        var dbHealthy = await _db.Database.CanConnectAsync(ct);
        return new SystemHealthDto
        {
            Status = dbHealthy ? "healthy" : "degraded",
            Database = dbHealthy ? "connected" : "failed",
            Timestamp = DateTime.UtcNow
        };
    }

    public async Task<PagedResponse<ErrorLog>> GetErrorLogsAsync(PaginationParams paging, CancellationToken ct = default)
    {
        var query = _errorRepo.Query().AsNoTracking();
        var totalCount = await query.CountAsync(ct);
        var logs = await query.OrderByDescending(l => l.Timestamp)
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<ErrorLog>
        {
            Data = logs,
            Pagination = new PaginationMeta
            {
                Page = paging.PageNumber,
                PageSize = paging.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task ResolveErrorAsync(Guid logId, ResolveErrorDto dto, CancellationToken ct = default)
    {
        var log = await _errorRepo.GetByIdAsync(logId, ct);
        if (log != null)
        {
            log.Resolved = true;
            log.ResolvedAt = DateTime.UtcNow;
            _errorRepo.Update(log);
            await _errorRepo.SaveChangesAsync(ct);
        }
    }

    public async Task<ApiPerformanceDto> GetApiPerformanceAsync(ApiPerformanceQueryDto query, CancellationToken ct = default)
    {
        var lastHour = DateTime.UtcNow.AddHours(-1);
        var recentErrors = await _db.ErrorLogs
            .AsNoTracking()
            .Where(log => log.Timestamp >= lastHour)
            .CountAsync(ct);

        var auditEvents = await _db.AuditLogs
            .AsNoTracking()
            .Where(log => log.Timestamp >= lastHour)
            .CountAsync(ct);

        return new ApiPerformanceDto
        {
            Available = true,
            Window = string.IsNullOrWhiteSpace(query.Window) ? "last_hour" : query.Window.Trim().ToLowerInvariant(),
            ErrorCount = recentErrors,
            AuditEventCount = auditEvents,
            Note = "Detailed request latency metrics are not persisted in the current deployment."
        };
    }

    public async Task<SystemAlertsDto> GetAlertsAsync(CancellationToken ct = default)
    {
        var criticalErrors = await _errorRepo.Query().CountAsync(l => l.Severity == "critical" && !l.Resolved, ct);
        return new SystemAlertsDto
        {
            CriticalErrors = criticalErrors
        };
    }

    public async Task<PagedResponse<AuditLog>> GetAuditLogsAsync(PaginationParams paging, CancellationToken ct = default)
    {
        var query = _auditRepo.Query().Include(l => l.Admin).AsNoTracking();
        var totalCount = await query.CountAsync(ct);
        var logs = await query.OrderByDescending(l => l.Timestamp)
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<AuditLog>
        {
            Data = logs,
            Pagination = new PaginationMeta
            {
                Page = paging.PageNumber,
                PageSize = paging.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<MaintenanceModeStatusDto> ToggleMaintenanceModeAsync(ToggleMaintenanceModeDto dto, CancellationToken ct = default)
    {
        var rule = await _db.PlatformRules.FirstOrDefaultAsync(r => r.Group == "System" && r.Key == "MaintenanceMode", ct);
        if (rule == null)
        {
            rule = new PlatformRule
            {
                Group = "System",
                Key = "MaintenanceMode",
                Value = dto.IsEnabled.ToString(),
                Description = dto.Reason,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _db.PlatformRules.Add(rule);
        }
        else
        {
            rule.Value = dto.IsEnabled.ToString();
            rule.Description = dto.Reason;
            rule.UpdatedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(ct);

        return new MaintenanceModeStatusDto
        {
            IsEnabled = dto.IsEnabled,
            Reason = dto.Reason,
            UpdatedAt = rule.UpdatedAt
        };
    }

    public Task<SystemConfigDto> GetConfigAsync(CancellationToken ct = default)
    {
        return Task.FromResult(new SystemConfigDto
        {
            BaseUrl = _config["AppSettings:BaseUrl"] ?? string.Empty,
            FirebaseProjectId = _config["Firebase:ProjectId"] ?? string.Empty,
            ApiVersion = "v1",
            Environment = _config["ASPNETCORE_ENVIRONMENT"] ?? "Production"
        });
    }
}
