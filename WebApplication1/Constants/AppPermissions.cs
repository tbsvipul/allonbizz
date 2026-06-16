using routent.AdminAPI.Models.Enums;

namespace routent.AdminAPI.Constants;

public static class Permissions
{
    // Users
    public const string UsersView    = "Users.View";
    public const string UsersEdit    = "Users.Edit";
    public const string UsersSuspend = "Users.Suspend";
    public const string UsersBan     = "Users.Ban";
    public const string UsersExport  = "Users.Export";

    // Keepers
    public const string KeepersView    = "Keepers.View";
    public const string KeepersApprove = "Keepers.Approve";
    public const string KeepersReject  = "Keepers.Reject";
    public const string KeepersSuspend = "Keepers.Suspend";

    // Shops
    public const string ShopsView    = "Shops.View";
    public const string ShopsCreate  = "Shops.Create";
    public const string ShopsEdit    = "Shops.Edit";
    public const string ShopsDelete  = "Shops.Delete";
    public const string ShopsApprove = "Shops.Approve";
    public const string ShopsReject  = "Shops.Reject";

    // Categories
    public const string CategoriesView   = "Categories.View";
    public const string CategoriesCreate = "Categories.Create";
    public const string CategoriesEdit   = "Categories.Edit";
    public const string CategoriesDelete = "Categories.Delete";

    // Tags
    public const string TagsView   = "Tags.View";
    public const string TagsCreate = "Tags.Create";
    public const string TagsEdit   = "Tags.Edit";
    public const string TagsDelete = "Tags.Delete";

    // Offers
    public const string OffersView    = "Offers.View";
    public const string OffersCreate  = "Offers.Create";
    public const string OffersEdit    = "Offers.Edit";
    public const string OffersDelete  = "Offers.Delete";
    public const string OffersApprove = "Offers.Approve";

    // Routes
    public const string RoutesView = "Routes.View";

    // Reviews
    public const string ReviewsView  = "Reviews.View";
    public const string ReviewsReply = "Reviews.Reply";



    // Rules & Journeys
    public const string RulesView    = "Rules.View";
    public const string RulesEdit    = "Rules.Edit";
    public const string JourneysView = "Journeys.View";
    public const string JourneysDelete = "Journeys.Delete";

    // Moderation
    public const string ModerationView    = "Moderation.View";
    public const string ModerationApprove = "Moderation.Approve";
    public const string ModerationReject  = "Moderation.Reject";
    public const string ModerationEdit    = "Moderation.Edit";
    public const string ModerationEscalate = "Moderation.Escalate";

    // Analytics & Reports
    public const string AnalyticsView   = "Analytics.View";
    public const string ReportsGenerate = "Reports.Generate";

    // System
    public const string SystemView   = "System.View";
    public const string SystemEdit   = "System.Edit";
    public const string SettingsEdit = "Settings.Edit";
    public const string AdminsManage       = "Admins.Manage";
    public const string NotificationsView = "Notifications.View";
    public const string NotificationsSend = "Notifications.Send";
}

public static class Roles
{
    public const string SuperAdmin = "super_admin";
    public const string Admin      = "admin";
    public const string Keeper     = "keeper";
    public const string Customer   = "customer";
}

public static class AppPermissions
{
    public static readonly Dictionary<string, List<string>> RoleDefaults = new()
    {
        [Roles.SuperAdmin] = new List<string>
        {
            Permissions.UsersView, Permissions.UsersEdit, Permissions.UsersSuspend, Permissions.UsersBan, Permissions.UsersExport,
            Permissions.KeepersView, Permissions.KeepersApprove, Permissions.KeepersReject, Permissions.KeepersSuspend,
            Permissions.CategoriesView, Permissions.CategoriesCreate, Permissions.CategoriesEdit, Permissions.CategoriesDelete,
            Permissions.ShopsView, Permissions.ShopsCreate, Permissions.ShopsEdit, Permissions.ShopsDelete,
            Permissions.ShopsApprove, Permissions.ShopsReject,
            Permissions.TagsView, Permissions.TagsCreate, Permissions.TagsEdit, Permissions.TagsDelete,
            Permissions.OffersView, Permissions.OffersCreate, Permissions.OffersEdit, Permissions.OffersDelete, Permissions.OffersApprove,
            Permissions.RoutesView, Permissions.ReviewsView, Permissions.ReviewsReply,
            Permissions.RulesView, Permissions.RulesEdit, Permissions.JourneysView, Permissions.JourneysDelete,
            Permissions.ModerationView, Permissions.ModerationApprove, Permissions.ModerationReject, Permissions.ModerationEdit, Permissions.ModerationEscalate,
            Permissions.AnalyticsView, Permissions.ReportsGenerate,
            Permissions.SystemView, Permissions.SystemEdit, Permissions.SettingsEdit, Permissions.AdminsManage,
            Permissions.NotificationsView, Permissions.NotificationsSend
        },

        [Roles.Admin] = new List<string>
        {
            Permissions.UsersView, Permissions.UsersEdit, Permissions.UsersSuspend, Permissions.UsersBan, Permissions.UsersExport,
            Permissions.KeepersView, Permissions.KeepersApprove, Permissions.KeepersReject, Permissions.KeepersSuspend,
            Permissions.CategoriesView, Permissions.CategoriesCreate, Permissions.CategoriesEdit, Permissions.CategoriesDelete,
            Permissions.ShopsView, Permissions.ShopsCreate, Permissions.ShopsEdit, Permissions.ShopsDelete,
            Permissions.ShopsApprove, Permissions.ShopsReject,
            Permissions.TagsView, Permissions.TagsCreate, Permissions.TagsEdit, Permissions.TagsDelete,
            Permissions.OffersView, Permissions.OffersApprove,
            Permissions.RoutesView, Permissions.ReviewsView,
            Permissions.JourneysView, Permissions.JourneysDelete,
            Permissions.ModerationView, Permissions.ModerationApprove, Permissions.ModerationReject, Permissions.ModerationEdit, Permissions.ModerationEscalate,
            Permissions.AnalyticsView, Permissions.ReportsGenerate,
            Permissions.SystemView, Permissions.SystemEdit,
            Permissions.NotificationsView, Permissions.NotificationsSend
        },

        [AdminRoles.Moderator] = new List<string>
        {
            Permissions.UsersView,
            Permissions.KeepersView,
            Permissions.ShopsView,
            Permissions.OffersView,
            Permissions.ReviewsView,
            Permissions.ModerationView,
            Permissions.ModerationApprove,
            Permissions.ModerationReject,
            Permissions.ModerationEdit,
            Permissions.ModerationEscalate,
            Permissions.NotificationsView
        },

        [AdminRoles.Analyst] = new List<string>
        {
            Permissions.AnalyticsView,
            Permissions.ReportsGenerate,
            Permissions.JourneysView,
            Permissions.UsersView,
            Permissions.ShopsView,
            Permissions.OffersView,
            Permissions.RoutesView
        },

        [Roles.Keeper] = new List<string>
        {
            Permissions.ShopsView,
            Permissions.ShopsCreate,
            Permissions.ShopsEdit,
            Permissions.OffersView, Permissions.OffersCreate, Permissions.OffersEdit, Permissions.OffersDelete,
            Permissions.ReviewsView, Permissions.ReviewsReply,

            Permissions.TagsView,
            Permissions.AnalyticsView
        },

        [Roles.Customer] = new List<string>
        {
            Permissions.ShopsView,
            Permissions.CategoriesView,
            Permissions.OffersView,
            Permissions.RoutesView,
            Permissions.ReviewsView,
            Permissions.TagsView
        }
    };
}
