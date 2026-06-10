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

public class SavedItemDto
{
    public Guid FavouriteId { get; set; }
    public string Type { get; set; } = string.Empty;
    public Guid? OfferId { get; set; }
    public Guid? ShopId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string? Address { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public string? ShopProfileImage { get; set; }
    public bool ShopIsOpen { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsVerified { get; set; }
    public DateTime SavedAt { get; set; }
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
    public string? ImageUrl { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Priority { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
    public Guid? ActionOfferId { get; set; }
    public Guid? ActionShopId { get; set; }
    public Guid? ActionJourneyId { get; set; }
    public string? MetadataJson { get; set; }
}
