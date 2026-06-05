namespace allonbiz.AdminAPI.Models.Enums;

public enum NotificationType
{
    OfferAlert,
    RouteUpdate,
    Redemption,

    SystemMessage,
    Chat,
    Review,
    Promotion,
    PromoAnnouncement,
    AccountUpdate,
    JourneyUpdate
}

public enum NotificationPriority
{
    Low,
    Normal,
    High,
    Critical
}

public enum NotificationStatus
{
    Draft,
    Scheduled,
    Queued,
    Sent,
    Failed,
    Cancelled
}
