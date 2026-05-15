namespace allonbiz.AdminAPI.DTOs.System;

public class SystemHealthDto
{
    public string Status { get; set; } = string.Empty;
    public string Database { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class ApiPerformanceQueryDto
{
    public string Window { get; set; } = "last_hour";
}

public class ApiPerformanceDto
{
    public bool Available { get; set; }
    public string Window { get; set; } = string.Empty;
    public int ErrorCount { get; set; }
    public int AuditEventCount { get; set; }
    public string Note { get; set; } = string.Empty;
}

public class SystemAlertsDto
{
    public int CriticalErrors { get; set; }
}

public class MaintenanceModeStatusDto
{
    public bool IsEnabled { get; set; }
    public string? Reason { get; set; }
    public DateTime UpdatedAt { get; set; }
}
