namespace routent.AdminAPI.Constants;

public static class CacheKeys
{
    public const string DashboardMetrics = "dashboard:metrics";
    public const string RealtimeMetrics = "realtime:metrics";
    public const string CategoryTree = "categories:tree";
    public const string ModerationStats = "moderation:stats";
    public const string UserCount = "users:count";
    public const string KeeperCount = "keepers:count";

    public static string UserDetail(Guid userId) => $"users:{userId}:detail";
    public static string KeeperDetail(Guid keeperId) => $"keepers:{keeperId}:detail";
    public static string CategoryDetail(Guid categoryId) => $"categories:{categoryId}:detail";
}
