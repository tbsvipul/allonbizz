using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class KeeperProfileDto
{
    public Guid KeeperId { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public KeeperStatus Status { get; set; }
}

public class KeeperDashboardDto
{
    public int ActiveOffersCount { get; set; }
    public int TotalRedemptions { get; set; }
    public decimal TotalSalesValue { get; set; } // Estimated
    public List<RedemptionTrendDto> RedemptionTrend { get; set; } = new();
}

public class RedemptionTrendDto
{
    public DateTime Date { get; set; }
    public int Count { get; set; }
}

public class KeeperTrafficDto
{
    public int CurrentViewersNearShop { get; set; }
    public List<HourlyTrafficDto> PredictedTraffic { get; set; } = new();
}

public class HourlyTrafficDto
{
    public int Hour { get; set; }
    public int PredictedCount { get; set; }
}

public class KeeperAnalyticsDto
{
    public int TotalShops { get; set; }
    public int ActiveShops { get; set; }
    public int TotalOffers { get; set; }
    public int ActiveOffers { get; set; }
    public int TotalRedemptions { get; set; }
    public decimal TotalSavings { get; set; }
    public List<RedemptionTrendDto> RedemptionTrend { get; set; } = new();
    public List<KeeperShopAnalyticsDto> Shops { get; set; } = new();
}

public class KeeperShopAnalyticsDto
{
    public Guid ShopId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public int OfferCount { get; set; }
    public int RedemptionCount { get; set; }
    public decimal Savings { get; set; }
}
