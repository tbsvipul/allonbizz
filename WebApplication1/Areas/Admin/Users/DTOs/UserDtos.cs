namespace routent.AdminAPI.DTOs.Users;

public record UserListQueryDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string? Search { get; set; }
    public string? Status { get; set; }
    public string? Role { get; set; }
    public string? SortBy { get; set; } = "createdAt";
    public string? SortOrder { get; set; } = "desc";
    public DateTime? DateFrom { get; set; }
    public DateTime? DateTo { get; set; }
}

public class UserDetailDto
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName => $"{FirstName} {LastName}";
    public string? Phone { get; set; }
    public string? AvatarUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public bool Is2FAEnabled { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public string? LastLoginIp { get; set; }
    public int TotalOrders { get; set; }
    public int TotalReviews { get; set; }
    public int WarningCount { get; set; }
}

public class UserActivityDto
{
    public Guid UserId { get; set; }
    public List<ActivityItemDto> RecentActivities { get; set; } = new();
    public int TotalReviews { get; set; }
    public int TotalOrders { get; set; }
    public int TotalReports { get; set; }
    public DateTime? LastActiveAt { get; set; }
}

public class ActivityItemDto
{
    public string Type { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class LoginHistoryItemDto
{
    public DateTime LoginAt { get; set; }
    public string IpAddress { get; set; } = string.Empty;
    public string? UserAgent { get; set; }
    public string? Location { get; set; }
    public bool Success { get; set; }
}

public class UpdateStatusRequestDto
{
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
}

public class SuspendUserRequestDto
{
    public string Reason { get; set; } = string.Empty;
    public int? DurationDays { get; set; }
}

public class BanUserRequestDto
{
    public string Reason { get; set; } = string.Empty;
    public bool DeleteContent { get; set; } = false;
}

public class WarnUserRequestDto
{
    public string Message { get; set; } = string.Empty;
    public string Severity { get; set; } = "medium";
}

public class BulkActionRequestDto
{
    public List<Guid> UserIds { get; set; } = new();
    public string Action { get; set; } = string.Empty;  // suspend | ban | activate | deactivate
    public string? Reason { get; set; }
}

public class ConvertRoleRequestDto
{
    public string NewRole { get; set; } = string.Empty;
    public string? Reason { get; set; }
}
