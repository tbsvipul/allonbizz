namespace allonbiz.AdminAPI.Helpers;

public static class NotificationAudienceHelper
{
    public static string Normalize(string? targetAudience)
    {
        return targetAudience?.Trim().ToLowerInvariant() switch
        {
            "customer" or "customers" => "customers",
            "keeper" or "keepers" => "keepers",
            "all" => "all",
            _ => "all"
        };
    }
}
