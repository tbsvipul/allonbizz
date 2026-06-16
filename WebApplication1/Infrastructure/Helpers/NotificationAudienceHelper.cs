namespace routent.AdminAPI.Helpers;

public static class NotificationAudienceHelper
{
    public static string Normalize(string? targetAudience)
    {
        var normalized = targetAudience?.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(normalized)) return "all";

        if (Guid.TryParse(normalized, out _))
        {
            return normalized;
        }

        return normalized switch
        {
            "customer" or "customers" => "customers",
            "keeper" or "keepers" => "keepers",
            "admin" or "admins" => "admins",
            "all" => "all",
            _ => "all"
        };
    }
}
