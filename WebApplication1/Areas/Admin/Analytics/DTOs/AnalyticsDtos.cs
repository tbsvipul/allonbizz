using allonbiz.AdminAPI.DTOs.Admin;

namespace allonbiz.AdminAPI.DTOs.Analytics;

public class AnalyticsRangeQueryDto
{
    public string? Range { get; set; } = "month";
}

public class UserAnalyticsDto
{
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int Customers { get; set; }
    public int Keepers { get; set; }
}

public class RevenueAnalyticsDto
{
    public decimal TotalPlatformSavings { get; set; }
    public decimal EstimatedRevenue { get; set; }
}

public class RealTimeMetricsDto
{
    public int ActiveUsersLastHour { get; set; }
    public int? CurrentRequestsPerMinute { get; set; }
    public bool RequestsPerMinuteAvailable { get; set; }
}

public class TrendingAdminOfferDto
{
    public Guid OfferId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
}

public class TrendingAdminShopDto
{
    public Guid ShopId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int ReviewCount { get; set; }
    public double AvgRating { get; set; }
}

public class TrendingAdminJourneyDto
{
    public Guid JourneyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int LikesCount { get; set; }
    public int ViewsCount { get; set; }
    public int Score { get; set; }
}

public class CustomAnalyticsReportDto
{
    public string Dataset { get; set; } = string.Empty;
    public List<string> Metrics { get; set; } = new();
    public string? GroupBy { get; set; }
    public DateTime? DateFrom { get; set; }
    public DateTime? DateTo { get; set; }
    public Dictionary<string, string>? Filters { get; set; }
    public List<CustomAnalyticsRowDto> Rows { get; set; } = new();
}

public class CustomAnalyticsRowDto
{
    public string Label { get; set; } = string.Empty;
    public Dictionary<string, decimal> Metrics { get; set; } = new();
}
