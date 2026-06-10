using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using System.Text.Json;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<AdminAccount> AdminAccounts { get; set; } = null!;
    public DbSet<Category> Categories { get; set; } = null!;
    public DbSet<AuditLog> AuditLogs { get; set; } = null!;
    public DbSet<ModerationQueueItem> ModerationQueueItems { get; set; } = null!;
    public DbSet<ErrorLog> ErrorLogs { get; set; } = null!;
    public DbSet<UserReport> UserReports { get; set; } = null!;
    public DbSet<AuthChallenge> AuthChallenges { get; set; } = null!;

    public DbSet<Shop> Shops { get; set; } = null!;
    public DbSet<Tag> Tags { get; set; } = null!;
    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Keeper> Keepers { get; set; } = null!;
    public DbSet<KeeperDocument> KeeperDocuments { get; set; } = null!;
    public DbSet<KeeperReviewMessage> KeeperReviewMessages { get; set; } = null!;
    public DbSet<KeeperAuditSchedule> KeeperAuditSchedules { get; set; } = null!;
    public DbSet<Offer> Offers { get; set; } = null!;
    public DbSet<RouteRecord> Routes { get; set; } = null!;
    public DbSet<Favourite> Favourites { get; set; } = null!;
    public DbSet<Review> Reviews { get; set; } = null!;

    public DbSet<Notification> Notifications { get; set; } = null!;
    public DbSet<UserNotification> UserNotifications { get; set; } = null!;
    public DbSet<ShopNotificationSetting> ShopNotificationSettings { get; set; } = null!;
    public DbSet<NotificationLog> NotificationLogs { get; set; } = null!;
    public DbSet<NotificationDeliveryJob> NotificationDeliveryJobs { get; set; } = null!;
    public DbSet<PlatformRule> PlatformRules { get; set; } = null!;
    public DbSet<Journey> Journeys { get; set; } = null!;
    public DbSet<RefreshToken> RefreshTokens { get; set; } = null!;
    public DbSet<MediaAsset> MediaAssets { get; set; } = null!;
    public DbSet<ChatThread> ChatThreads { get; set; } = null!;
    public DbSet<ChatMessage> ChatMessages { get; set; } = null!;
    public DbSet<SupportTicket> SupportTickets { get; set; } = null!;
    public DbSet<SupportTicketMessage> SupportTicketMessages { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // Entity configurations are applied from the assembly (Data/Configurations/*.cs)

        // Keep JsonDocument compatible with the EF in-memory provider without taking a runtime package dependency on it.
        if (string.Equals(Database.ProviderName, "Microsoft.EntityFrameworkCore.InMemory", StringComparison.Ordinal))
        {
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                foreach (var property in entityType.GetProperties())
                {
                    if (property.ClrType == typeof(JsonDocument))
                    {
                        property.SetValueConverter(new ValueConverter<JsonDocument?, string>(
                            v => v == null ? "{}" : v.RootElement.ToString(),
                            v => JsonDocument.Parse(v ?? "{}", default)));
                        
                        // Also clear column type since in-memory doesn't support 'jsonb'
                        property.SetColumnType(null);
                    }
                }
            }
        }
    }
}
