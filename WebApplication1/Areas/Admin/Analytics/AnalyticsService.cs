using Microsoft.EntityFrameworkCore;
using System.Text;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Analytics;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class AnalyticsService : IAnalyticsService
{
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<Keeper> _keeperRepo;
    private readonly IRepository<Shop> _shopRepo;
    private readonly IRepository<Offer> _offerRepo;
    private readonly IRepository<Journey> _journeyRepo;
    private readonly IRepository<Redemption> _redemptionRepo;
    private readonly IRepository<ModerationQueueItem> _moderationRepo;

    public AnalyticsService(
        IRepository<User> userRepo,
        IRepository<Keeper> keeperRepo,
        IRepository<Shop> shopRepo,
        IRepository<Offer> offerRepo,
        IRepository<Journey> journeyRepo,
        IRepository<Redemption> redemptionRepo,
        IRepository<ModerationQueueItem> moderationRepo)
    {
        _userRepo = userRepo;
        _keeperRepo = keeperRepo;
        _shopRepo = shopRepo;
        _offerRepo = offerRepo;
        _journeyRepo = journeyRepo;
        _redemptionRepo = redemptionRepo;
        _moderationRepo = moderationRepo;
    }

    public async Task<UserAnalyticsDto> GetUserAnalyticsAsync(AnalyticsRangeQueryDto? query, CancellationToken ct = default)
    {
        var totalUsers = await _userRepo.Query().CountAsync(ct);
        var activeUsers = await _userRepo.Query().CountAsync(u => u.IsActive, ct);
        var customers = await _userRepo.Query().CountAsync(u => u.Role == "customer", ct);
        var keepers = await _userRepo.Query().CountAsync(u => u.Role == "keeper", ct);

        return new UserAnalyticsDto
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            Customers = customers,
            Keepers = keepers
        };
    }

    public async Task<JourneyAnalyticsResponseDto> GetJourneyAnalyticsAsync(AnalyticsRangeQueryDto? query, CancellationToken ct = default)
    {
        var rangeStr = query?.Range?.Trim().ToLowerInvariant() ?? "month";
        var daysBack = rangeStr switch { "week" => 7, "year" => 365, _ => 30 };
        var since = DateTime.UtcNow.AddDays(-daysBack);

        var rangeJourneys = await _journeyRepo.Query()
            .AsNoTracking()
            .Where(j => j.StartTime >= since)
            .ToListAsync(ct);

        var totalJourneys = rangeJourneys.Count;
        var activeJourneys = rangeJourneys.Count(j => j.Status.Equals("active", StringComparison.OrdinalIgnoreCase));
        var completedJourneys = rangeJourneys.Count(j => j.Status.Equals("completed", StringComparison.OrdinalIgnoreCase));
        var totalDist = rangeJourneys.Sum(j => j.Distance);
        var avgDist = totalJourneys > 0 ? totalDist / totalJourneys : 0;
        var avgDurMin = totalJourneys > 0 ? rangeJourneys.Average(j => j.Duration) / 60.0 : 0;
        var totalOffers = rangeJourneys.Sum(j => j.OffersRedeemed);
        var totalSavings = rangeJourneys.Sum(j => j.TotalSavings);

        var timeSeries = Enumerable.Range(0, daysBack)
            .Select(i => since.AddDays(i).Date)
            .Select(date => new JourneyTimeSeriesPoint
            {
                Date = date.ToString("yyyy-MM-dd"),
                Count = rangeJourneys.Count(j => j.StartTime.Date == date),
                TotalDistance = Math.Round(rangeJourneys.Where(j => j.StartTime.Date == date).Sum(j => j.Distance), 2)
            })
            .ToList();

        var typeDistribution = rangeJourneys
            .GroupBy(j => string.IsNullOrWhiteSpace(j.Type) ? "unknown" : j.Type)
            .Select(group => new JourneyTypeDistribution
            {
                Type = group.Key,
                Count = group.Count()
            })
            .OrderByDescending(item => item.Count)
            .ToList();

        var statusDistribution = rangeJourneys
            .GroupBy(j => string.IsNullOrWhiteSpace(j.Status) ? "unknown" : j.Status)
            .Select(group => new JourneyStatusDistribution
            {
                Status = group.Key,
                Count = group.Count()
            })
            .OrderByDescending(item => item.Count)
            .ToList();

        var userIds = rangeJourneys.Select(j => j.UserId).Distinct().ToList();
        var users = await _userRepo.Query().AsNoTracking().Where(u => userIds.Contains(u.UserId)).ToListAsync(ct);
        var usersById = users.ToDictionary(u => u.UserId, u => u);

        var topUsers = rangeJourneys
            .GroupBy(j => j.UserId)
            .Select(group =>
            {
                usersById.TryGetValue(group.Key, out var user);
                var fullName = user == null
                    ? "Unknown"
                    : string.Join(' ', new[] { user.FirstName, user.LastName }.Where(part => !string.IsNullOrWhiteSpace(part))).Trim();

                return new TopJourneyUser
                {
                    UserId = group.Key,
                    Email = user?.Email ?? string.Empty,
                    Name = string.IsNullOrWhiteSpace(fullName) ? user?.Email ?? "Unknown" : fullName,
                    JourneyCount = group.Count(),
                    TotalDistance = Math.Round(group.Sum(item => item.Distance), 2)
                };
            })
            .OrderByDescending(item => item.JourneyCount)
            .ThenByDescending(item => item.TotalDistance)
            .Take(10)
            .ToList();

        return new JourneyAnalyticsResponseDto
        {
            Summary = new JourneyAnalyticsSummaryDto
            {
                TotalJourneys = totalJourneys,
                ActiveJourneys = activeJourneys,
                CompletedJourneys = completedJourneys,
                TotalDistanceKm = Math.Round(totalDist, 2),
                AvgDistanceKm = Math.Round(avgDist, 2),
                AvgDurationMinutes = Math.Round(avgDurMin, 1),
                TotalOffersRedeemed = totalOffers,
                TotalSavings = totalSavings
            },
            TimeSeries = timeSeries,
            TypeDistribution = typeDistribution,
            StatusDistribution = statusDistribution,
            TopUsers = topUsers,
            Recent = rangeJourneys.OrderByDescending(j => j.StartTime).Take(20).Select(j =>
            {
                usersById.TryGetValue(j.UserId, out var user);
                var fullName = user == null
                    ? "Unknown"
                    : string.Join(' ', new[] { user.FirstName, user.LastName }.Where(part => !string.IsNullOrWhiteSpace(part))).Trim();

                return new AdminJourneyListDto
                {
                    JourneyId = j.JourneyId,
                    UserId = j.UserId,
                    UserEmail = user?.Email ?? string.Empty,
                    UserName = string.IsNullOrWhiteSpace(fullName) ? user?.Email ?? "Unknown" : fullName,
                    Type = j.Type,
                    Status = j.Status,
                    StartName = j.StartName,
                    EndName = j.EndName,
                    Distance = j.Distance,
                    Duration = j.Duration,
                    OffersRedeemed = j.OffersRedeemed,
                    TotalSavings = j.TotalSavings,
                    StartTime = j.StartTime,
                    EndTime = j.EndTime
                };
            }).ToList()
        };
    }

    public async Task<RevenueAnalyticsDto> GetRevenueAnalyticsAsync(AnalyticsRangeQueryDto? query, CancellationToken ct = default)
    {
        var totalSavings = await _redemptionRepo.Query().SumAsync(r => r.SavedAmount ?? 0, ct);
        return new RevenueAnalyticsDto
        {
            TotalPlatformSavings = totalSavings,
            EstimatedRevenue = totalSavings * 0.1m
        };
    }

    public async Task<RealTimeMetricsDto> GetRealTimeMetricsAsync(CancellationToken ct = default)
    {
        var hourAgo = DateTime.UtcNow.AddHours(-1);
        var recentLogins = await _userRepo.Query().CountAsync(u => u.LastLoginAt > hourAgo, ct);
        return new RealTimeMetricsDto
        {
            ActiveUsersLastHour = recentLogins,
            CurrentRequestsPerMinute = null,
            RequestsPerMinuteAvailable = false
        };
    }

    public async Task<List<TrendingAdminOfferDto>> GetTrendingOffersAsync(CancellationToken ct = default)
    {
        return await _offerRepo.Query()
            .AsNoTracking()
            .Include(offer => offer.Shop)
            .OrderByDescending(offer => offer.CurrentRedemptions)
            .Take(10)
            .Select(offer => new TrendingAdminOfferDto
            {
                OfferId = offer.OfferId,
                Title = offer.Title,
                CurrentRedemptions = offer.CurrentRedemptions,
                ShopName = offer.Shop != null ? offer.Shop.Name : "Unknown"
            })
            .ToListAsync(ct);
    }

    public async Task<List<TrendingAdminShopDto>> GetTrendingShopsAsync(CancellationToken ct = default)
    {
        return await _shopRepo.Query()
            .AsNoTracking()
            .Include(shop => shop.Reviews)
            .Select(shop => new TrendingAdminShopDto
            {
                ShopId = shop.ShopId,
                Name = shop.Name,
                ReviewCount = shop.Reviews.Count(),
                AvgRating = shop.Reviews.Any() ? shop.Reviews.Average(review => (double)(int)review.Rating) : 0d
            })
            .OrderByDescending(shop => shop.AvgRating)
            .ThenByDescending(shop => shop.ReviewCount)
            .Take(10)
            .ToListAsync(ct);
    }

    public async Task<List<TrendingAdminJourneyDto>> GetTrendingJourneysAsync(CancellationToken ct = default)
    {
        return await _journeyRepo.Query()
            .AsNoTracking()
            .Select(journey => new TrendingAdminJourneyDto
            {
                JourneyId = journey.JourneyId,
                Name = journey.StartName ?? string.Empty,
                LikesCount = journey.LikesCount,
                ViewsCount = journey.ViewsCount,
                Score = journey.LikesCount * 2 + journey.ViewsCount
            })
            .OrderByDescending(journey => journey.Score)
            .Take(10)
            .ToListAsync(ct);
    }

    public async Task<byte[]> GetPrebuiltReportCsvAsync(string reportType, AnalyticsRangeQueryDto? query, CancellationToken ct = default)
    {
        var normalizedReportType = reportType.Trim().ToLowerInvariant();
        return normalizedReportType switch
        {
            "users" => BuildSingleObjectCsv(normalizedReportType, await GetUserAnalyticsAsync(query, ct)),
            "journeys" => BuildSingleObjectCsv(normalizedReportType, (await GetJourneyAnalyticsAsync(query, ct)).Summary),
            "revenue" => BuildSingleObjectCsv(normalizedReportType, await GetRevenueAnalyticsAsync(query, ct)),
            "dashboard" => BuildSingleObjectCsv(normalizedReportType, FlattenDashboard(await GetFullDashboardAsync(ct))),
            _ => throw new NotSupportedException($"Prebuilt report '{reportType}' is not available.")
        };
    }

    public async Task<CustomAnalyticsReportDto> GenerateCustomReportAsync(GenerateCustomReportDto dto, CancellationToken ct = default)
    {
        var dataset = dto.Dataset.Trim().ToLowerInvariant();
        var metrics = dto.Metrics.Count > 0 ? dto.Metrics.Select(metric => metric.Trim().ToLowerInvariant()).Distinct().ToList() : new List<string> { "count" };
        var groupBy = dto.GroupBy?.Trim().ToLowerInvariant();

        return dataset switch
        {
            "users" => await BuildUserReportAsync(dto, metrics, groupBy, ct),
            "keepers" => await BuildKeeperReportAsync(dto, metrics, groupBy, ct),
            "shops" => await BuildShopReportAsync(dto, metrics, groupBy, ct),
            "journeys" => await BuildJourneyReportAsync(dto, metrics, groupBy, ct),
            "redemptions" or "revenue" => await BuildRedemptionReportAsync(dto, metrics, groupBy, ct),
            _ => throw new NotSupportedException($"Custom analytics dataset '{dto.Dataset}' is not supported.")
        };
    }

    public async Task<byte[]> GenerateCustomReportCsvAsync(GenerateCustomReportDto dto, CancellationToken ct = default)
    {
        var report = await GenerateCustomReportAsync(dto, ct);
        var metricHeaders = report.Metrics.Count > 0 ? report.Metrics : report.Rows.SelectMany(row => row.Metrics.Keys).Distinct().ToList();
        var builder = new StringBuilder();
        builder.Append("label");

        foreach (var header in metricHeaders)
        {
            builder.Append(',');
            builder.Append(header);
        }

        builder.AppendLine();

        foreach (var row in report.Rows)
        {
            builder.Append(EscapeCsv(row.Label));

            foreach (var header in metricHeaders)
            {
                builder.Append(',');
                builder.Append(row.Metrics.TryGetValue(header, out var value) ? value.ToString(System.Globalization.CultureInfo.InvariantCulture) : "0");
            }

            builder.AppendLine();
        }

        return Encoding.UTF8.GetBytes(builder.ToString());
    }

    public async Task<AdminDashboardSummaryDto> GetFullDashboardAsync(CancellationToken ct = default)
    {
        var totalSavings = await _redemptionRepo.Query().SumAsync(r => r.SavedAmount ?? 0, ct);
        var totalUsers = await _userRepo.Query().CountAsync(ct);
        var totalKeepers = await _keeperRepo.Query().CountAsync(ct);
        var totalShops = await _shopRepo.Query().CountAsync(ct);
        var pendingModeration = await _moderationRepo.Query().CountAsync(m => m.Status == "pending", ct);

        return new AdminDashboardSummaryDto
        {
            TotalUsers = totalUsers,
            TotalKeepers = totalKeepers,
            TotalShops = totalShops,
            PendingModeration = pendingModeration,
            TotalPlatformSavings = totalSavings,
            TotalRedemptions = await _redemptionRepo.Query().CountAsync(ct)
        };
    }

    private static byte[] BuildSingleObjectCsv(string reportType, object payload)
    {
        var properties = payload.GetType().GetProperties();
        var header = string.Join(",", properties.Select(property => property.Name));
        var values = string.Join(",", properties.Select(property => EscapeCsv(property.GetValue(payload))));
        var content = $"reportType{(properties.Length > 0 ? "," : string.Empty)}{header}{Environment.NewLine}{EscapeCsv(reportType)}{(properties.Length > 0 ? "," : string.Empty)}{values}";
        return Encoding.UTF8.GetBytes(content);
    }

    private static string EscapeCsv(object? value)
    {
        if (value == null)
        {
            return string.Empty;
        }

        var text = value switch
        {
            string s => s,
            _ => value.ToString() ?? string.Empty
        };

        if (text.Contains(',') || text.Contains('"') || text.Contains('\n'))
        {
            return $"\"{text.Replace("\"", "\"\"")}\"";
        }

        return text;
    }

    private static object FlattenDashboard(AdminDashboardSummaryDto dashboard)
    {
        return new
        {
            dashboard.TotalUsers,
            dashboard.TotalKeepers,
            dashboard.TotalShops,
            dashboard.PendingModeration,
            dashboard.TotalPlatformSavings,
            dashboard.TotalRedemptions
        };
    }

    private async Task<CustomAnalyticsReportDto> BuildUserReportAsync(GenerateCustomReportDto dto, List<string> metrics, string? groupBy, CancellationToken ct)
    {
        var query = _userRepo.Query().AsNoTracking();

        if (dto.DateFrom.HasValue) query = query.Where(u => u.CreatedAt >= dto.DateFrom.Value);
        if (dto.DateTo.HasValue) query = query.Where(u => u.CreatedAt <= dto.DateTo.Value);
        
        if (TryGetFilter(dto.Filters, "role", out var role)) 
            query = query.Where(u => u.Role == role);
        if (TryGetFilter(dto.Filters, "status", out var statusStr) && Enum.TryParse<UserStatus>(statusStr, true, out var status)) 
            query = query.Where(u => u.Status == status);

        var data = await query.ToListAsync(ct);

        return BuildReport(
            dto,
            metrics,
            groupBy,
            data,
            user => ResolveUserLabel(user, groupBy),
            (rowMetrics, user) =>
            {
                IncrementMetric(rowMetrics, "count", 1);
                IncrementMetric(rowMetrics, "active", user.IsActive ? 1 : 0);
                IncrementMetric(rowMetrics, "banned", user.Status == UserStatus.Banned ? 1 : 0);
                IncrementMetric(rowMetrics, "suspended", user.Status == UserStatus.Suspended ? 1 : 0);
            });
    }

    private async Task<CustomAnalyticsReportDto> BuildKeeperReportAsync(GenerateCustomReportDto dto, List<string> metrics, string? groupBy, CancellationToken ct)
    {
        var keepers = await _keeperRepo.Query().AsNoTracking().ToListAsync(ct);
        keepers = keepers
            .Where(keeper => !dto.DateFrom.HasValue || keeper.CreatedAt >= dto.DateFrom.Value)
            .Where(keeper => !dto.DateTo.HasValue || keeper.CreatedAt <= dto.DateTo.Value)
            .Where(keeper => !TryGetFilter(dto.Filters, "status", out var status) || keeper.Status.ToString().Equals(status, StringComparison.OrdinalIgnoreCase))
            .ToList();

        return BuildReport(
            dto,
            metrics,
            groupBy,
            keepers,
            keeper => ResolveKeeperLabel(keeper, groupBy),
            (rowMetrics, keeper) =>
            {
                IncrementMetric(rowMetrics, "count", 1);
                IncrementMetric(rowMetrics, "approved", keeper.Status == KeeperStatus.Approved ? 1 : 0);
                IncrementMetric(rowMetrics, "pending", keeper.Status == KeeperStatus.PendingApproval ? 1 : 0);
                IncrementMetric(rowMetrics, "on_hold", keeper.Status == KeeperStatus.OnHold ? 1 : 0);
            });
    }

    private async Task<CustomAnalyticsReportDto> BuildShopReportAsync(GenerateCustomReportDto dto, List<string> metrics, string? groupBy, CancellationToken ct)
    {
        var query = _shopRepo.Query().AsNoTracking().Include(s => s.Category).AsQueryable();

        if (dto.DateFrom.HasValue) query = query.Where(s => s.CreatedAt >= dto.DateFrom.Value);
        if (dto.DateTo.HasValue) query = query.Where(s => s.CreatedAt <= dto.DateTo.Value);
        
        if (TryGetFilter(dto.Filters, "category", out var category))
            query = query.Where(s => s.Category != null && s.Category.Name == category);

        var data = await query.ToListAsync(ct);

        return BuildReport(
            dto,
            metrics,
            groupBy,
            data,
            shop => ResolveShopLabel(shop, groupBy),
            (rowMetrics, shop) =>
            {
                IncrementMetric(rowMetrics, "count", 1);
                IncrementMetric(rowMetrics, "active", shop.IsActive ? 1 : 0);
                IncrementMetric(rowMetrics, "verified", shop.IsVerified ? 1 : 0);
            });
    }

    private async Task<CustomAnalyticsReportDto> BuildJourneyReportAsync(GenerateCustomReportDto dto, List<string> metrics, string? groupBy, CancellationToken ct)
    {
        var journeys = await _journeyRepo.Query().AsNoTracking().ToListAsync(ct);
        journeys = journeys
            .Where(journey => !dto.DateFrom.HasValue || journey.StartTime >= dto.DateFrom.Value)
            .Where(journey => !dto.DateTo.HasValue || journey.StartTime <= dto.DateTo.Value)
            .Where(journey => !TryGetFilter(dto.Filters, "status", out var status) || journey.Status.Equals(status, StringComparison.OrdinalIgnoreCase))
            .Where(journey => !TryGetFilter(dto.Filters, "type", out var type) || journey.Type.Equals(type, StringComparison.OrdinalIgnoreCase))
            .ToList();

        return BuildReport(
            dto,
            metrics,
            groupBy,
            journeys,
            journey => ResolveJourneyLabel(journey, groupBy),
            (rowMetrics, journey) =>
            {
                IncrementMetric(rowMetrics, "count", 1);
                IncrementMetric(rowMetrics, "distance_km", (decimal)journey.Distance);
                IncrementMetric(rowMetrics, "offers_redeemed", journey.OffersRedeemed);
                IncrementMetric(rowMetrics, "total_savings", journey.TotalSavings);
            });
    }

    private async Task<CustomAnalyticsReportDto> BuildRedemptionReportAsync(GenerateCustomReportDto dto, List<string> metrics, string? groupBy, CancellationToken ct)
    {
        var redemptions = await _redemptionRepo.Query()
            .AsNoTracking()
            .Include(redemption => redemption.Shop)
            .ToListAsync(ct);

        redemptions = redemptions
            .Where(redemption => !dto.DateFrom.HasValue || redemption.RedeemedAt >= dto.DateFrom.Value)
            .Where(redemption => !dto.DateTo.HasValue || redemption.RedeemedAt <= dto.DateTo.Value)
            .Where(redemption => !TryGetFilter(dto.Filters, "status", out var status) || redemption.Status.ToString().Equals(status, StringComparison.OrdinalIgnoreCase))
            .Where(redemption => !TryGetFilter(dto.Filters, "shop", out var shopName) || (redemption.Shop?.Name ?? "unknown").Equals(shopName, StringComparison.OrdinalIgnoreCase))
            .ToList();

        return BuildReport(
            dto,
            metrics,
            groupBy,
            redemptions,
            redemption => ResolveRedemptionLabel(redemption, groupBy),
            (rowMetrics, redemption) =>
            {
                IncrementMetric(rowMetrics, "count", 1);
                IncrementMetric(rowMetrics, "total_savings", redemption.SavedAmount ?? 0);
            });
    }

    private static CustomAnalyticsReportDto BuildReport<TItem>(
        GenerateCustomReportDto dto,
        IReadOnlyCollection<string> metrics,
        string? groupBy,
        IEnumerable<TItem> items,
        Func<TItem, string> labelSelector,
        Action<Dictionary<string, decimal>, TItem> accumulator)
    {
        var rows = new Dictionary<string, Dictionary<string, decimal>>(StringComparer.OrdinalIgnoreCase);

        foreach (var item in items)
        {
            var label = labelSelector(item);
            if (!rows.TryGetValue(label, out var rowMetrics))
            {
                rowMetrics = metrics.ToDictionary(metric => metric, _ => 0m, StringComparer.OrdinalIgnoreCase);
                rows[label] = rowMetrics;
            }

            accumulator(rowMetrics, item);
        }

        return new CustomAnalyticsReportDto
        {
            Dataset = dto.Dataset,
            Metrics = metrics.ToList(),
            GroupBy = groupBy,
            DateFrom = dto.DateFrom,
            DateTo = dto.DateTo,
            Filters = dto.Filters,
            Rows = rows
                .OrderBy(item => item.Key, StringComparer.OrdinalIgnoreCase)
                .Select(item => new CustomAnalyticsRowDto
                {
                    Label = item.Key,
                    Metrics = item.Value
                })
                .ToList()
        };
    }

    private static string ResolveUserLabel(User user, string? groupBy)
    {
        return groupBy switch
        {
            "role" => user.Role,
            "status" => user.Status.ToString(),
            "day" => user.CreatedAt.ToString("yyyy-MM-dd"),
            "month" => user.CreatedAt.ToString("yyyy-MM"),
            _ => "all"
        };
    }

    private static string ResolveKeeperLabel(Keeper keeper, string? groupBy)
    {
        return groupBy switch
        {
            "status" => keeper.Status.ToString(),
            "day" => keeper.CreatedAt.ToString("yyyy-MM-dd"),
            "month" => keeper.CreatedAt.ToString("yyyy-MM"),
            _ => "all"
        };
    }

    private static string ResolveShopLabel(Shop shop, string? groupBy)
    {
        return groupBy switch
        {
            "category" => shop.Category?.Name ?? "uncategorized",
            "status" => ResolveShopStatus(shop),
            "day" => shop.CreatedAt.ToString("yyyy-MM-dd"),
            "month" => shop.CreatedAt.ToString("yyyy-MM"),
            _ => "all"
        };
    }

    private static string ResolveJourneyLabel(Journey journey, string? groupBy)
    {
        return groupBy switch
        {
            "status" => journey.Status,
            "type" => journey.Type,
            "day" => journey.StartTime.ToString("yyyy-MM-dd"),
            "month" => journey.StartTime.ToString("yyyy-MM"),
            _ => "all"
        };
    }

    private static string ResolveRedemptionLabel(Redemption redemption, string? groupBy)
    {
        return groupBy switch
        {
            "status" => redemption.Status.ToString(),
            "shop" => redemption.Shop?.Name ?? "unknown",
            "day" => redemption.RedeemedAt.ToString("yyyy-MM-dd"),
            "month" => redemption.RedeemedAt.ToString("yyyy-MM"),
            _ => "all"
        };
    }

    private static string ResolveShopStatus(Shop shop)
    {
        if (!shop.IsActive)
        {
            return "inactive";
        }

        return shop.IsVerified ? "verified" : "active";
    }

    private static void IncrementMetric(Dictionary<string, decimal> metrics, string metricName, decimal value)
    {
        if (!metrics.ContainsKey(metricName))
        {
            return;
        }

        metrics[metricName] += value;
    }

    private static bool TryGetFilter(IReadOnlyDictionary<string, string>? filters, string key, out string value)
    {
        value = string.Empty;
        if (filters == null)
        {
            return false;
        }

        if (!filters.TryGetValue(key, out var rawValue) || string.IsNullOrWhiteSpace(rawValue))
        {
            return false;
        }

        value = rawValue;
        return true;
    }
}
