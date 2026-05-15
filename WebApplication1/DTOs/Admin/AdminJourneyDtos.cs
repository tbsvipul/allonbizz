namespace allonbiz.AdminAPI.DTOs.Admin;

public class AdminJourneyListDto
{
    public Guid JourneyId { get; set; }
    public Guid UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Type { get; set; } = "freeRoam";
    public string Status { get; set; } = "active";
    public string? StartName { get; set; }
    public string? EndName { get; set; }
    public double Distance { get; set; }
    public long Duration { get; set; }
    public int OffersRedeemed { get; set; }
    public decimal TotalSavings { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
}

public class AdminJourneyDetailDto : AdminJourneyListDto
{
    public double StartLat { get; set; }
    public double StartLng { get; set; }
    public double? EndLat { get; set; }
    public double? EndLng { get; set; }
    public int LikesCount { get; set; }
    public int ViewsCount { get; set; }
    public List<string> Tags { get; set; } = new();
    public List<string> ShopsEncountered { get; set; } = new();
    public List<double[]> Path { get; set; } = new();
}

public class JourneyAnalyticsResponseDto
{
    public JourneyAnalyticsSummaryDto Summary { get; set; } = new();
    public List<JourneyTimeSeriesPoint> TimeSeries { get; set; } = new();
    public List<JourneyTypeDistribution> TypeDistribution { get; set; } = new();
    public List<JourneyStatusDistribution> StatusDistribution { get; set; } = new();
    public List<TopJourneyUser> TopUsers { get; set; } = new();
    public List<AdminJourneyListDto> Recent { get; set; } = new();
}

public class JourneyAnalyticsSummaryDto
{
    public int TotalJourneys { get; set; }
    public int ActiveJourneys { get; set; }
    public int CompletedJourneys { get; set; }
    public double TotalDistanceKm { get; set; }
    public double AvgDistanceKm { get; set; }
    public double AvgDurationMinutes { get; set; }
    public int TotalOffersRedeemed { get; set; }
    public decimal TotalSavings { get; set; }
}

public class JourneyTimeSeriesPoint
{
    public string Date { get; set; } = string.Empty;
    public int Count { get; set; }
    public double TotalDistance { get; set; }
}

public class JourneyTypeDistribution
{
    public string Type { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class JourneyStatusDistribution
{
    public string Status { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class TopJourneyUser
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int JourneyCount { get; set; }
    public double TotalDistance { get; set; }
}
