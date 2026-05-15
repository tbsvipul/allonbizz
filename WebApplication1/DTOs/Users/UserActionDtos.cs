namespace allonbiz.AdminAPI.DTOs.Users;

/// <summary>DTO for updating FCM device token.</summary>
public class UpdateFcmTokenDto
{
    public string Token { get; set; } = string.Empty;
}

/// <summary>DTO for rating an offer.</summary>
public class RateOfferRequestDto
{
    public int Rating { get; set; } // 1-5
    public string? Comment { get; set; }
}

/// <summary>DTO for toggling favourites.</summary>
public class ToggleFavouriteDto
{
    public Guid? ShopId { get; set; }
    public Guid? OfferId { get; set; }
    public string Type { get; set; } = "shop"; // shop | offer
}


/// <summary>DTO for starting a chat session.</summary>
public class StartChatResponseDto
{
    public Guid ChatId { get; set; }
    public string Status { get; set; } = "connected";
}

/// <summary>Savings summary response.</summary>
public class SavingsSummaryDto
{
    public decimal TotalSaved { get; set; }
    public int TotalRedemptions { get; set; }
    public string MostSavedCategory { get; set; } = string.Empty;
}

/// <summary>Route history item DTO.</summary>
public class RouteHistoryItemDto
{
    public Guid RouteId { get; set; }
    public string? StartAddress { get; set; }
    public string? EndAddress { get; set; }
    public double DistanceKm { get; set; }
    public int OffersFound { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>Notification DTO for customer-facing notifications.</summary>
public class UserNotificationDto
{
    public Guid NotificationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}
