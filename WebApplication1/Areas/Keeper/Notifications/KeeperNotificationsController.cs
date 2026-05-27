using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Areas.Keeper.Controllers;

public class KeeperSendNotificationDto
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public Guid? OfferId { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
}

public class KeeperSendRadiusDto
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public decimal RadiusKm { get; set; }
    public Guid? OfferId { get; set; }
}

public class KeeperSettingsDto
{
    public bool AutoRadiusNotification { get; set; }
    public decimal RadiusKm { get; set; }
    public int CooldownHours { get; set; }
}

public class UpdateStatusDto
{
    public bool IsActive { get; set; }
}

public class KeeperNotificationListItemDto
{
    public Guid NotificationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public Guid? OfferId { get; set; }
    public string? OfferTitle { get; set; }
    public int RecipientCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ScheduledAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

[ApiController]
[Route("api/v1/keeper/notifications")]
[Authorize]
public class KeeperNotificationsController : ControllerBase
{
    private readonly AppDbContext _db;
    
    public KeeperNotificationsController(AppDbContext db)
    {
        _db = db;
    }

    private Guid GetUserId()
    {
        return Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    }

    private async Task<List<Shop>> GetKeeperShopsAsync(Guid userId)
    {
        var keeper = await _db.Keepers
            .Include(k => k.Shops)
            .FirstOrDefaultAsync(k => k.UserId == userId);
        return keeper?.Shops.ToList() ?? new List<Shop>();
    }

    private async Task<Guid> GetShopIdAsync(Guid userId)
    {
        var shops = await GetKeeperShopsAsync(userId);
        return shops.FirstOrDefault()?.ShopId ?? Guid.Empty;
    }

    /// <summary>
    /// Send a notification to all users who are currently within the keeper's shop radius.
    /// Creates one Notification per user with the given title, message, optional offer, and image.
    /// </summary>
    [HttpPost("send")]
    public async Task<IActionResult> SendNotification([FromBody] KeeperSendNotificationDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title) || string.IsNullOrWhiteSpace(dto.Message))
        {
            return BadRequest(ApiResponse<object>.Fail("VALIDATION", "Title and message are required."));
        }

        var userId = GetUserId();
        var shops = await GetKeeperShopsAsync(userId);

        if (shops.Count == 0)
            return BadRequest(ApiResponse<object>.Fail("SHOP_NOT_FOUND", "No shop found for this keeper."));

        // Validate offer if provided
        Offer? attachedOffer = null;
        if (dto.OfferId.HasValue)
        {
            attachedOffer = await _db.Offers
                .AsNoTracking()
                .FirstOrDefaultAsync(o => o.OfferId == dto.OfferId.Value && shops.Select(s => s.ShopId).Contains(o.ShopId));

            if (attachedOffer == null)
                return BadRequest(ApiResponse<object>.Fail("OFFER_NOT_FOUND", "Offer not found or does not belong to your shop."));
        }

        var now = DateTime.UtcNow;
        var totalRecipients = 0;

        foreach (var shop in shops)
        {
            var settings = await _db.ShopNotificationSettings.FirstOrDefaultAsync(s => s.ShopId == shop.ShopId);
            var radiusKm = settings != null && settings.RadiusKm > 0 ? (double)settings.RadiusKm : shop.NotificationRadius;

            if (!shop.Latitude.HasValue || !shop.Longitude.HasValue || !radiusKm.HasValue)
                continue;

            // Find users who are within the shop radius based on their last known location
            var usersInRange = await _db.Users
                .Where(u => u.IsActive
                         && u.Role == "customer"
                         && u.LastLatitude.HasValue
                         && u.LastLongitude.HasValue)
                .ToListAsync();

            var qualifiedUsers = usersInRange
                .Where(u =>
                {
                    var dist = GeoHelper.CalculateDistanceKm(
                        u.LastLatitude!.Value, u.LastLongitude!.Value,
                        shop.Latitude!.Value, shop.Longitude!.Value);
                    return dist <= radiusKm.Value;
                })
                .ToList();

            // Allow zero recipient notifications to appear in history
            // if (qualifiedUsers.Count == 0) continue;

            var notifType = dto.OfferId.HasValue ? NotificationType.OfferAlert : NotificationType.Promotion;

            var notification = new Notification
            {
                NotificationId = Guid.NewGuid(),
                Title = dto.Title.Trim(),
                Message = dto.Message.Trim(),
                Type = notifType,
                Priority = NotificationPriority.Normal,
                TargetAudience = "customers",
                SenderType = "Keeper",
                SenderId = userId,
                ShopId = shop.ShopId,
                OfferId = dto.OfferId,
                ImageUrl = dto.ImageUrl ?? (attachedOffer?.ImageData != null ? ImageConversionHelper.ToBase64DataUrl(attachedOffer.ImageData) : null),
                IsGlobal = false,
                Status = NotificationStatus.Sent,
                IsActive = true,
                ScheduledAt = dto.StartDate ?? now,
                ExpiresAt = dto.EndDate,
                SentAt = now,
                RecipientCount = qualifiedUsers.Count,
                CreatedAt = now,
                UpdatedAt = now
            };

            _db.Notifications.Add(notification);

            // Only send immediately if the StartDate is not in the future
            if (!dto.StartDate.HasValue || dto.StartDate.Value <= now)
            {
                foreach (var customer in qualifiedUsers)
                {
                    _db.UserNotifications.Add(new UserNotification
                    {
                        UserId = customer.UserId,
                        NotificationId = notification.NotificationId,
                        IsRead = false,
                        IsDeleted = false,
                        DeliveryStatus = "Delivered",
                        SentAt = now
                    });
                }
                totalRecipients += qualifiedUsers.Count;
            }
        }

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { recipientCount = totalRecipients }, $"Notification sent to {totalRecipients} user(s) in range."));
    }

    /// <summary>
    /// List all notifications sent by this keeper, newest first.
    /// </summary>
    [HttpGet("sent")]
    public async Task<IActionResult> GetSentNotifications()
    {
        var userId = GetUserId();

        var notifications = await _db.Notifications
            .AsNoTracking()
            .Include(n => n.Offer)
            .Where(n => n.SenderId == userId && n.SenderType == "Keeper")
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new KeeperNotificationListItemDto
            {
                NotificationId = n.NotificationId,
                Title = n.Title,
                Message = n.Message,
                ImageUrl = n.ImageUrl,
                Type = n.Type.ToString(),
                Status = n.Status.ToString(),
                IsActive = n.IsActive,
                OfferId = n.OfferId,
                OfferTitle = n.Offer != null ? n.Offer.Title : null,
                RecipientCount = n.RecipientCount,
                CreatedAt = n.CreatedAt,
                ScheduledAt = n.ScheduledAt,
                ExpiresAt = n.ExpiresAt
            })
            .ToListAsync();

        return Ok(ApiResponse<List<KeeperNotificationListItemDto>>.Ok(notifications));
    }

    [HttpPost("send-radius")]
    public async Task<IActionResult> SendRadiusNotification([FromBody] KeeperSendRadiusDto dto)
    {
        var userId = GetUserId();
        var shopId = await GetShopIdAsync(userId);
        
        if (shopId == Guid.Empty) return BadRequest(ApiResponse<object>.Fail("SHOP_NOT_FOUND", "Shop not found"));

        // Generate a Notification record that will be processed by the background worker.
        var notification = new Notification
        {
            Title = dto.Title,
            Message = dto.Message,
            Type = NotificationType.OfferAlert,
            TargetAudience = "customers",
            SenderType = "Keeper",
            SenderId = userId,
            ShopId = shopId,
            OfferId = dto.OfferId,
            RadiusKm = dto.RadiusKm,
            IsGlobal = false,
            Status = NotificationStatus.Queued,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Notifications.Add(notification);
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(null!, "Radius notification queued successfully"));
    }

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateNotificationStatus(Guid id, [FromBody] UpdateStatusDto dto)
    {
        var userId = GetUserId();
        var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.NotificationId == id && n.SenderId == userId);
        
        if (notification == null) return NotFound(ApiResponse<object>.Fail("NOT_FOUND", "Notification not found"));

        notification.IsActive = dto.IsActive;
        notification.UpdatedAt = DateTime.UtcNow;
        
        await _db.SaveChangesAsync();
        return Ok(ApiResponse<object>.Ok(null!, $"Notification status updated to {(dto.IsActive ? "Active" : "Inactive")}"));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(Guid id)
    {
        var userId = GetUserId();
        var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.NotificationId == id && n.SenderId == userId);
        
        if (notification == null) return NotFound(ApiResponse<object>.Fail("NOT_FOUND", "Notification not found"));

        // Soft delete or hard delete depending on relationships. Let's do hard delete since we might not have a global IsDeleted on Notification.
        // Wait, UserNotification relies on it. Better to set IsActive = false and maybe Status to Deleted.
        notification.IsActive = false;
        notification.Status = NotificationStatus.Draft; // Or some deleted status if available, fallback to Draft
        _db.Notifications.Remove(notification);
        
        await _db.SaveChangesAsync();
        return Ok(ApiResponse<object>.Ok(null!, "Notification deleted successfully"));
    }

    [HttpGet("settings")]
    public async Task<IActionResult> GetSettings()
    {
        var userId = GetUserId();
        var shopId = await GetShopIdAsync(userId);
        if (shopId == Guid.Empty) return BadRequest(ApiResponse<object>.Fail("SHOP_NOT_FOUND", "Shop not found"));

        var settings = await _db.ShopNotificationSettings.FirstOrDefaultAsync(s => s.ShopId == shopId);
        if (settings == null)
        {
            settings = new ShopNotificationSetting { ShopId = shopId };
            _db.ShopNotificationSettings.Add(settings);
            await _db.SaveChangesAsync();
        }

        return Ok(ApiResponse<KeeperSettingsDto>.Ok(new KeeperSettingsDto
        {
            AutoRadiusNotification = settings.AutoRadiusNotification,
            RadiusKm = settings.RadiusKm,
            CooldownHours = settings.CooldownHours
        }));
    }

    [HttpPut("settings")]
    public async Task<IActionResult> UpdateSettings([FromBody] KeeperSettingsDto dto)
    {
        var userId = GetUserId();
        var shopId = await GetShopIdAsync(userId);
        if (shopId == Guid.Empty) return BadRequest(ApiResponse<object>.Fail("SHOP_NOT_FOUND", "Shop not found"));

        var settings = await _db.ShopNotificationSettings.FirstOrDefaultAsync(s => s.ShopId == shopId);
        if (settings == null)
        {
            settings = new ShopNotificationSetting { ShopId = shopId };
            _db.ShopNotificationSettings.Add(settings);
        }

        settings.AutoRadiusNotification = dto.AutoRadiusNotification;
        settings.RadiusKm = dto.RadiusKm;
        settings.CooldownHours = dto.CooldownHours;
        settings.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(null!, "Notification settings updated successfully"));
    }
}
