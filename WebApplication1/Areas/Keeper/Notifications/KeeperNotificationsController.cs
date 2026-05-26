using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Areas.Keeper.Controllers;

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

    private async Task<Guid> GetShopIdAsync(Guid userId)
    {
        var keeper = await _db.Keepers
            .Include(k => k.Shops)
            .FirstOrDefaultAsync(k => k.UserId == userId);
        return keeper?.Shops.FirstOrDefault()?.ShopId ?? Guid.Empty;
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
