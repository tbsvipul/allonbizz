namespace routent.AdminAPI.Models.Enums;

public enum NotificationType
{
    OfferAlert,
    RouteUpdate,

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
