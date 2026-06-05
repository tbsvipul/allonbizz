using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace allonbiz.AdminAPI.Services;

public class NotificationService : INotificationService
{
    private readonly AppDbContext _db;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(AppDbContext db, ILogger<NotificationService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<PagedResponse<NotificationSummaryDto>> GetNotificationsAsync(PaginationParams paging, string? status = null, CancellationToken ct = default)
    {
        var query = _db.Notifications.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
        {
            if (Enum.TryParse<NotificationStatus>(status, true, out var parsedStatus))
            {
                query = query.Where(notification => notification.Status == parsedStatus);
            }
            else
            {
                _logger.LogWarning("Invalid notification status filter: {Status}", status);
                // If invalid status is provided, we could either return empty or throw. 
                // Given this is an admin API, throwing an ArgumentException is better for feedback.
                throw new ArgumentException($"Invalid notification status: {status}");
            }
        }

        var totalCount = await query.CountAsync(ct);
        var notifications = await query
            .OrderByDescending(notification => notification.CreatedAt)
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .Select(notification => new NotificationSummaryDto
            {
                NotificationId = notification.NotificationId,
                Title = notification.Title,
                Message = notification.Message,
                Type = notification.Type.ToString(),
                Priority = notification.Priority.ToString(),
                TargetAudience = NotificationAudienceHelper.Normalize(notification.TargetAudience),
                Status = notification.Status.ToString(),
                ScheduledAt = notification.ScheduledAt,
                SentAt = notification.SentAt,
                CreatedAt = notification.CreatedAt,
                RecipientCount = notification.RecipientCount
            })
            .ToListAsync(ct);

        return new PagedResponse<NotificationSummaryDto>
        {
            Data = notifications,
            Pagination = new PaginationMeta
            {
                Page = paging.PageNumber,
                PageSize = paging.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<PagedResponse<UserNotificationDto>> GetUserNotificationsAsync(Guid userId, string role, PaginationParams paging, CancellationToken ct = default)
    {
        var query = _db.UserNotifications
            .Include(un => un.Notification)
            .AsNoTracking()
            .Where(un => un.UserId == userId && !un.IsDeleted);

        var totalCount = await query.CountAsync(ct);
        var notifications = await query
            .OrderByDescending(un => un.Notification!.CreatedAt)
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .ToListAsync(ct);

        return new PagedResponse<UserNotificationDto>
        {
            Data = notifications.Select(MapUserNotification).ToList(),
            Pagination = new PaginationMeta
            {
                Page = paging.PageNumber,
                PageSize = paging.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task MarkUserNotificationReadAsync(Guid userId, Guid notificationId, CancellationToken ct = default)
    {
        var un = await _db.UserNotifications.FirstOrDefaultAsync(
            item => item.NotificationId == notificationId && item.UserId == userId, ct);

        if (un == null) throw new KeyNotFoundException($"Notification {notificationId} not found for user {userId}");

        if (!un.IsRead)
        {
            un.IsRead = true;
            un.ReadAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task DeleteUserNotificationAsync(Guid userId, Guid notificationId, CancellationToken ct = default)
    {
        var un = await _db.UserNotifications.FirstOrDefaultAsync(
            item => item.NotificationId == notificationId && item.UserId == userId, ct);

        if (un != null && !un.IsDeleted)
        {
            un.IsDeleted = true;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task<int> GetUnreadNotificationCountAsync(Guid userId, string role, CancellationToken ct = default)
    {
        return await _db.UserNotifications
            .Where(un => un.UserId == userId && !un.IsDeleted && !un.IsRead)
            .CountAsync(ct);
    }

    public async Task<NotificationDetailDto> GetNotificationByIdAsync(Guid notificationId, CancellationToken ct = default)
    {
        var notification = await _db.Notifications
            .AsNoTracking()
            .Include(item => item.SentByAdmin)
            .FirstOrDefaultAsync(item => item.NotificationId == notificationId, ct);

        if (notification == null)
        {
            throw new KeyNotFoundException($"Notification {notificationId} not found");
        }

        var jobs = await _db.NotificationDeliveryJobs
            .AsNoTracking()
            .Where(job => job.NotificationId == notificationId)
            .OrderByDescending(job => job.CreatedAt)
            .Select(job => new NotificationDeliveryJobDto
            {
                JobId = job.JobId,
                Status = job.Status,
                ScheduledFor = job.ScheduledFor,
                EnqueuedAt = job.EnqueuedAt,
                CompletedAt = job.CompletedAt,
                FailedAt = job.FailedAt,
                FailureReason = job.FailureReason,
                AttemptCount = job.AttemptCount
            })
            .ToListAsync(ct);

        return new NotificationDetailDto
        {
            NotificationId = notification.NotificationId,
            Title = notification.Title,
            Message = notification.Message,
            Type = notification.Type.ToString(),
            Priority = notification.Priority.ToString(),
            TargetAudience = NotificationAudienceHelper.Normalize(notification.TargetAudience),
            Status = notification.Status.ToString(),
            ScheduledAt = notification.ScheduledAt,
            SentAt = notification.SentAt,
            CreatedAt = notification.CreatedAt,
            RecipientCount = notification.RecipientCount,
            ExpiresAt = notification.ExpiresAt,
            SentById = notification.SentByAdminAdminId ?? notification.SentById,
            SentByName = notification.SentByAdmin != null ? $"{notification.SentByAdmin.FirstName} {notification.SentByAdmin.LastName}" : null,
            MetadataJson = notification.MetadataJson,
            DeliveryJobs = jobs
        };
    }

    public async Task<NotificationDetailDto> CreateNotificationAsync(CreateNotificationDto dto, Guid adminId, CancellationToken ct = default)
    {
        var type = Enum.TryParse<NotificationType>(dto.Type, true, out var parsedType) ? parsedType : NotificationType.SystemMessage;
        var priority = Enum.TryParse<NotificationPriority>(dto.Priority, true, out var parsedPriority) ? parsedPriority : NotificationPriority.Normal;
        var schedule = dto.ScheduledAt?.ToUniversalTime();
        var queueNow = dto.SendImmediately || (schedule.HasValue && schedule.Value <= DateTime.UtcNow);
        var status = queueNow
            ? NotificationStatus.Sent
            : schedule.HasValue && schedule.Value > DateTime.UtcNow
                ? NotificationStatus.Scheduled
                : NotificationStatus.Draft;

        var notification = new Notification
        {
            NotificationId = Guid.NewGuid(),
            Title = dto.Title.Trim(),
            Message = dto.Message.Trim(),
            Type = type,
            Priority = priority,
            TargetAudience = NotificationAudienceHelper.Normalize(dto.TargetAudience),
            Status = status,
            ScheduledAt = status == NotificationStatus.Draft ? null : (schedule ?? DateTime.UtcNow),
            ExpiresAt = dto.ExpiresAt,
            SentById = adminId,
            SentByAdminAdminId = adminId,
            MetadataJson = dto.MetadataJson,
            ImageUrl = dto.ImageUrl,
            IsGlobal = dto.IsGlobal,
            RadiusKm = dto.RadiusKm,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            SenderType = "Admin",
            SenderId = adminId,
            RecipientCount = await CountRecipientsAsync(dto.TargetAudience, ct),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Notifications.Add(notification);

        if (status != NotificationStatus.Draft)
        {
            var jobStatus = status == NotificationStatus.Sent ? "completed" : "scheduled";
            _db.NotificationDeliveryJobs.Add(CreateDeliveryJob(notification.NotificationId, status, notification.ScheduledAt ?? DateTime.UtcNow));
            
            if (status == NotificationStatus.Sent)
            {
                var job = await _db.NotificationDeliveryJobs.OrderByDescending(j => j.CreatedAt).FirstOrDefaultAsync(j => j.NotificationId == notification.NotificationId, ct);
                if (job != null)
                {
                    job.Status = "completed";
                    job.CompletedAt = DateTime.UtcNow;
                }
                
                await DeliverNotificationToUsersAsync(notification, ct);
            }
        }

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("Notification {NotificationId} created with status {Status}", notification.NotificationId, notification.Status);

        return await GetNotificationByIdAsync(notification.NotificationId, ct);
    }

    public async Task UpdateNotificationAsync(Guid notificationId, UpdateNotificationDto dto, CancellationToken ct = default)
    {
        var notification = await _db.Notifications.FirstOrDefaultAsync(item => item.NotificationId == notificationId, ct);
        if (notification == null)
        {
            throw new KeyNotFoundException("Notification not found");
        }

        if (notification.Status == NotificationStatus.Sent || notification.Status == NotificationStatus.Cancelled)
        {
            throw new InvalidOperationException("Sent or cancelled notifications cannot be updated");
        }

        notification.Title = dto.Title.Trim();
        notification.Message = dto.Message.Trim();
        if (Enum.TryParse<NotificationType>(dto.Type, true, out var parsedType))
        {
            notification.Type = parsedType;
        }

        if (Enum.TryParse<NotificationPriority>(dto.Priority, true, out var parsedPriority))
        {
            notification.Priority = parsedPriority;
        }

        notification.TargetAudience = NotificationAudienceHelper.Normalize(dto.TargetAudience);
        notification.ExpiresAt = dto.ExpiresAt;
        notification.MetadataJson = dto.MetadataJson;
        notification.RecipientCount = await CountRecipientsAsync(notification.TargetAudience, ct);
        notification.UpdatedAt = DateTime.UtcNow;

        var schedule = dto.ScheduledAt?.ToUniversalTime();
        if (schedule.HasValue && schedule.Value > DateTime.UtcNow)
        {
            notification.Status = NotificationStatus.Scheduled;
            notification.ScheduledAt = schedule.Value;
        }
        else
        {
            notification.Status = NotificationStatus.Draft;
            notification.ScheduledAt = null;
        }

        var openJobs = await _db.NotificationDeliveryJobs
            .Where(job =>
                job.NotificationId == notificationId &&
                (job.Status == "scheduled" || job.Status == "queued" || job.Status == "processing"))
            .ToListAsync(ct);

        _db.NotificationDeliveryJobs.RemoveRange(openJobs);

        if (notification.Status == NotificationStatus.Scheduled)
        {
            _db.NotificationDeliveryJobs.Add(CreateDeliveryJob(notification.NotificationId, NotificationStatus.Scheduled, notification.ScheduledAt!.Value));
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task DeleteNotificationAsync(Guid notificationId, CancellationToken ct = default)
    {
        var notification = await _db.Notifications.FirstOrDefaultAsync(item => item.NotificationId == notificationId, ct);
        if (notification == null)
        {
            return;
        }

        if (notification.Status == NotificationStatus.Sent)
        {
            throw new InvalidOperationException("Cannot delete sent notification");
        }

        _db.Notifications.Remove(notification);
        await _db.SaveChangesAsync(ct);
    }

    public async Task SendNotificationAsync(Guid notificationId, Guid adminId, CancellationToken ct = default)
    {
        var notification = await _db.Notifications.FirstOrDefaultAsync(item => item.NotificationId == notificationId, ct);
        if (notification == null)
        {
            throw new KeyNotFoundException("Notification not found");
        }

        if (notification.Status == NotificationStatus.Cancelled)
        {
            throw new InvalidOperationException("Cancelled notifications cannot be queued for delivery");
        }

        notification.Status = NotificationStatus.Sent;
        notification.ScheduledAt = DateTime.UtcNow;
        notification.SentById = adminId;
        notification.SentByAdminAdminId = adminId;
        notification.SentAt = DateTime.UtcNow;
        notification.RecipientCount = await CountRecipientsAsync(notification.TargetAudience, ct);
        notification.UpdatedAt = DateTime.UtcNow;

        var deliveryJob = CreateDeliveryJob(notification.NotificationId, NotificationStatus.Sent, DateTime.UtcNow);
        deliveryJob.Status = "completed";
        deliveryJob.CompletedAt = DateTime.UtcNow;
        _db.NotificationDeliveryJobs.Add(deliveryJob);

        await DeliverNotificationToUsersAsync(notification, ct);

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("Notification {NotificationId} queued for delivery to {RecipientCount} recipients", notificationId, notification.RecipientCount);
    }

    public async Task<NotificationStatsDto> GetNotificationStatsAsync(CancellationToken ct = default)
    {
        var totals = await _db.Notifications
            .AsNoTracking()
            .GroupBy(notification => notification.Status)
            .Select(group => new { Status = group.Key, Count = group.Count() })
            .ToListAsync(ct);

        return new NotificationStatsDto
        {
            TotalNotifications = totals.Sum(item => item.Count),
            SentNotifications = totals.Where(item => item.Status == NotificationStatus.Sent).Sum(item => item.Count),
            ScheduledNotifications = totals.Where(item => item.Status == NotificationStatus.Scheduled).Sum(item => item.Count),
            DraftNotifications = totals.Where(item => item.Status == NotificationStatus.Draft).Sum(item => item.Count),
            QueuedNotifications = totals.Where(item => item.Status == NotificationStatus.Queued).Sum(item => item.Count),
            FailedNotifications = totals.Where(item => item.Status == NotificationStatus.Failed).Sum(item => item.Count)
        };
    }

    private async Task<int> CountRecipientsAsync(string? targetAudience, CancellationToken ct)
    {
        var normalizedAudience = NotificationAudienceHelper.Normalize(targetAudience);
        return normalizedAudience switch
        {
            "customers" => await _db.Users.CountAsync(user => user.Role == "customer" && user.IsActive, ct),
            "keepers" => await _db.Users.CountAsync(user => user.Role == "keeper" && user.IsActive, ct),
            _ => await _db.Users.CountAsync(user => user.IsActive, ct)
        };
    }

    private static NotificationDeliveryJob CreateDeliveryJob(Guid notificationId, NotificationStatus status, DateTime scheduledFor)
    {
        var normalizedStatus = status switch
        {
            NotificationStatus.Scheduled => "scheduled",
            NotificationStatus.Queued => "queued",
            _ => "queued"
        };

        return new NotificationDeliveryJob
        {
            NotificationId = notificationId,
            Status = normalizedStatus,
            ScheduledFor = scheduledFor,
            EnqueuedAt = normalizedStatus == "queued" ? DateTime.UtcNow : null,
            AttemptCount = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    private async Task DeliverNotificationToUsersAsync(Notification notification, CancellationToken ct)
    {
        var targetAudience = NotificationAudienceHelper.Normalize(notification.TargetAudience);
        List<Guid> recipientIds;

        if (targetAudience == "customers")
        {
            recipientIds = await _db.Users.Where(u => u.Role == "customer" && u.IsActive).Select(u => u.UserId).ToListAsync(ct);
        }
        else if (targetAudience == "keepers")
        {
            recipientIds = await _db.Users.Where(u => u.Role == "keeper" && u.IsActive).Select(u => u.UserId).ToListAsync(ct);
        }
        else
        {
            recipientIds = await _db.Users.Where(u => u.IsActive).Select(u => u.UserId).ToListAsync(ct);
        }

        if (recipientIds.Any())
        {
            var now = DateTime.UtcNow;
            var userNotifications = recipientIds.Select(id => new UserNotification
            {
                UserId = id,
                NotificationId = notification.NotificationId,
                IsRead = false,
                IsDeleted = false,
                DeliveryStatus = "Delivered",
                SentAt = now
            });

            await _db.UserNotifications.AddRangeAsync(userNotifications, ct);
        }
    }

    private static UserNotificationDto MapUserNotification(UserNotification un)
    {
        var notification = un.Notification!;
        var metadata = ParseMetadata(notification.MetadataJson);

        return new UserNotificationDto
        {
            NotificationId = notification.NotificationId,
            Title = notification.Title,
            Message = notification.Message,
            ImageUrl = notification.ImageUrl,
            Type = notification.Type.ToString(),
            Priority = notification.Priority.ToString(),
            IsRead = un.IsRead,
            CreatedAt = notification.CreatedAt,
            ActionOfferId = notification.OfferId ?? metadata.OfferId,
            ActionShopId = notification.ShopId ?? metadata.ShopId,
            ActionJourneyId = metadata.JourneyId,
            MetadataJson = notification.MetadataJson
        };
    }

    private static (Guid? OfferId, Guid? ShopId, Guid? JourneyId) ParseMetadata(string? metadataJson)
    {
        if (string.IsNullOrWhiteSpace(metadataJson))
        {
            return (null, null, null);
        }

        try
        {
            using var document = JsonDocument.Parse(metadataJson);
            var root = document.RootElement;
            return (
                TryReadGuid(root, "offerId"),
                TryReadGuid(root, "shopId"),
                TryReadGuid(root, "journeyId"));
        }
        catch
        {
            return (null, null, null);
        }
    }

    private static Guid? TryReadGuid(JsonElement root, string propertyName)
    {
        if (!root.TryGetProperty(propertyName, out var property))
        {
            return null;
        }

        if (property.ValueKind == JsonValueKind.String && Guid.TryParse(property.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static bool HasUserReadBroadcastNotification(string? metadataJson, Guid userId)
    {
        var metadataNode = ParseMetadataNode(metadataJson);
        if (metadataNode?["readByUserIds"] is not JsonArray readBy)
        {
            return false;
        }

        return readBy.Any(item => string.Equals(item?.GetValue<string>(), userId.ToString(), StringComparison.OrdinalIgnoreCase));
    }

    private static string UpsertReadByUser(string? metadataJson, Guid userId)
    {
        var metadataNode = ParseMetadataNode(metadataJson) ?? new JsonObject();
        var readBy = metadataNode["readByUserIds"] as JsonArray ?? new JsonArray();
        if (!readBy.Any(item => string.Equals(item?.GetValue<string>(), userId.ToString(), StringComparison.OrdinalIgnoreCase)))
        {
            readBy.Add(userId.ToString());
        }

        metadataNode["readByUserIds"] = readBy;
        return metadataNode.ToJsonString();
    }

    private static JsonObject? ParseMetadataNode(string? metadataJson)
    {
        if (string.IsNullOrWhiteSpace(metadataJson))
        {
            return null;
        }

        try
        {
            return JsonNode.Parse(metadataJson) as JsonObject;
        }
        catch
        {
            return null;
        }
    }
}
