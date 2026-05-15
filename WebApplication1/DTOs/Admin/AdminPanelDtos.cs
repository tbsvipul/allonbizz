using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Admin;

public class AdminDashboardSummaryDto
{
    // Core counts
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int TotalKeepers { get; set; }
    public int TotalShops { get; set; }
    public int ActiveShops { get; set; }
    public int TotalOffers { get; set; }
    public int ActiveOffers { get; set; }
    public int TotalJourneys { get; set; }
    public int TotalCategories { get; set; }

    // Pending / action items
    public int PendingKeepers { get; set; }
    public int PendingShops { get; set; }
    public int PendingOffers { get; set; }
    public int PendingModeration { get; set; }

    // Revenue / savings
    public decimal TotalPlatformSavings { get; set; }
    public int TotalRedemptions { get; set; }

    // Growth (last 30 days)
    public int NewUsersLast30Days { get; set; }
    public int NewShopsLast30Days { get; set; }
    public int NewOffersLast30Days { get; set; }
    public int JourneysLast30Days { get; set; }

    // Recent activity
    public List<RecentActivityDto> RecentActivity { get; set; } = new();

    // Top shops
    public List<TopShopDto> TopShops { get; set; } = new();
}

public class RecentActivityDto
{
    public string Type { get; set; } = string.Empty; // user_registered, shop_created, offer_created, journey_completed, keeper_applied
    public string Description { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class TopShopDto
{
    public Guid ShopId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public int OffersCount { get; set; }
    public int RedemptionsCount { get; set; }
    public bool IsActive { get; set; }
}

public class ApprovalRequestDto
{
    public bool IsApproved { get; set; }
    public string? Reason { get; set; }
}

public class CreateRuleDto
{
    [Required]
    [StringLength(100)]
    public string Key { get; set; } = string.Empty;

    [Required]
    [StringLength(4000)]
    public string Value { get; set; } = string.Empty;

    [StringLength(100)]
    public string? Group { get; set; }

    [StringLength(500)]
    public string? Description { get; set; }
}

public class PlatformRuleDto
{
    public Guid RuleId { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string Group { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class PushNotificationRequestDto
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? TargetAudience { get; set; } // "all", "customers", "keepers"
}
