using System.Data;
using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Constants;
using routent.AdminAPI.Data;
using routent.AdminAPI.Models.Enums;

namespace routent.AdminAPI.Helpers;

public static class DatabaseMigrationBootstrapper
{
    private const string BaselineMigrationId = "20260514091542_AddRejectionReasonToShop";
    private const string RuntimeWorkflowMigrationId = "20260514115236_PersistRuntimeWorkflowsAndRemoveDemoAuth";
    private const string EfProductVersion = "8.0.0";

    private static readonly string[] BaselineTables =
    {
        "admin_accounts",
        "Users",
        "Shops",
        "Notifications"
    };

    private static readonly string[] RuntimeWorkflowTables =
    {
        "auth_challenges",
        "chat_threads",
        "keeper_audit_schedules",
        "keeper_documents",
        "keeper_review_messages",
        "notification_delivery_jobs",
        "shop_loyalty_programs",
        "chat_messages"
    };

    public static async Task EnsureDatabaseIsReadyAsync(
        AppDbContext db,
        ILogger? logger = null,
        CancellationToken ct = default)
    {
        await RepairMigrationHistoryIfNeededAsync(db, logger, ct);
        await db.Database.MigrateAsync(ct);
    }

    public static async Task<bool> RepairMigrationHistoryIfNeededAsync(
        AppDbContext db,
        ILogger? logger = null,
        CancellationToken ct = default)
    {
        var connection = db.Database.GetDbConnection();
        var shouldClose = connection.State != ConnectionState.Open;

        if (shouldClose)
        {
            await connection.OpenAsync(ct);
        }

        try
        {
            await using var transaction = await connection.BeginTransactionAsync(ct);

            await ExecuteNonQueryAsync(
                connection,
                transaction,
                """
                CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
                    "MigrationId" character varying(150) NOT NULL,
                    "ProductVersion" character varying(32) NOT NULL,
                    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
                );
                """,
                ct);

            var appliedMigrations = await GetAppliedMigrationIdsAsync(connection, transaction, ct);
            var repaired = false;

            if (!appliedMigrations.Contains(BaselineMigrationId, StringComparer.Ordinal))
            {
                if (!await TablesExistAsync(connection, transaction, BaselineTables, ct))
                {
                    await transaction.CommitAsync(ct);
                    return false;
                }

                await InsertMigrationRowAsync(connection, transaction, BaselineMigrationId, ct);
                repaired = true;
            }

            if (!appliedMigrations.Contains(RuntimeWorkflowMigrationId, StringComparer.Ordinal) &&
                await HasRuntimeWorkflowSchemaAsync(connection, transaction, ct))
            {
                await InsertMigrationRowAsync(connection, transaction, RuntimeWorkflowMigrationId, ct);
                repaired = true;
            }

            await transaction.CommitAsync(ct);
            if (repaired)
            {
                logger?.LogWarning(
                    "Repaired EF migration history for an existing database by stamping missing migration entries starting at {BaselineMigrationId}.",
                    BaselineMigrationId);
            }

            return repaired;
        }
        finally
        {
            if (shouldClose)
            {
                await connection.CloseAsync();
            }
        }
    }

    public static async Task RepairLegacyRuntimeDataAsync(
        AppDbContext db,
        ILogger? logger = null,
        CancellationToken ct = default)
    {
        var repairedSuperAdmins = await RepairSuperAdminPermissionsAsync(db, ct);
        var mediaRepair = await StringMediaSchemaRepair.RepairAsync(db, logger, ct);

        var repairedNotifications = await db.Database.ExecuteSqlRawAsync(
            """
            UPDATE "Notifications"
            SET "TargetAudience" = CASE
                WHEN "TargetAudience" IS NULL OR btrim("TargetAudience") = '' THEN 'all'
                WHEN lower("TargetAudience") IN ('customer', 'customers') THEN 'customers'
                WHEN lower("TargetAudience") IN ('keeper', 'keepers') THEN 'keepers'
                WHEN lower("TargetAudience") = 'all' THEN 'all'
                ELSE 'all'
            END,
            "UpdatedAt" = NOW()
            WHERE "TargetAudience" IS NULL
               OR btrim("TargetAudience") = ''
               OR lower("TargetAudience") IN ('customer', 'customers', 'keeper', 'keepers')
               OR "TargetAudience" <> lower("TargetAudience");
            """,
            ct);

        var publishedReviews = await db.Database.ExecuteSqlRawAsync(
            $"""
            UPDATE "Reviews"
            SET "Status" = {(int)ReviewStatus.Published}
            WHERE "Status" = {(int)ReviewStatus.Pending};
            """,
            ct);

        var normalizedShopArrays = await db.Database.ExecuteSqlRawAsync(
            """
            UPDATE "Shops"
            SET "Amenities" = COALESCE("Amenities", ARRAY[]::text[]),
                "Tags" = COALESCE("Tags", ARRAY[]::text[]),
                "ShopImages" = COALESCE("ShopImages", ARRAY[]::bytea[]),
                "UpdatedAt" = NOW()
            WHERE "Amenities" IS NULL
               OR "Tags" IS NULL
               OR "ShopImages" IS NULL;
            """,
            ct);

        var repairedShopsRadius = await db.Database.ExecuteSqlRawAsync(
            """
            UPDATE "Shops"
            SET "NotificationRadius" = 10.0,
                "UpdatedAt" = NOW()
            WHERE "NotificationRadius" IS NULL OR "NotificationRadius" <> 10.0;
            """,
            ct);

        if (repairedSuperAdmins > 0 || mediaRepair.NormalizedColumns > 0 || mediaRepair.FallbackRows > 0 || repairedNotifications > 0 || publishedReviews > 0 || normalizedShopArrays > 0 || repairedShopsRadius > 0)
        {
            logger?.LogWarning(
                "Repaired legacy runtime data. Super admins fixed: {SuperAdminsFixed}, media columns normalized: {NormalizedColumns}, binary fallback rows: {FallbackRows}, notifications fixed: {NotificationsFixed}, pending reviews published: {PublishedReviews}, shop array columns normalized: {NormalizedShopArrays}, shop radius updated: {RepairedShopsRadius}.",
                repairedSuperAdmins,
                mediaRepair.NormalizedColumns,
                mediaRepair.FallbackRows,
                repairedNotifications,
                publishedReviews,
                normalizedShopArrays,
                repairedShopsRadius);
        }
    }

    private static async Task<int> RepairSuperAdminPermissionsAsync(AppDbContext db, CancellationToken ct)
    {
        var expectedPermissions = AdminAccountHelper.ResolvePermissions(Roles.SuperAdmin, null);
        var superAdmins = await db.AdminAccounts
            .Where(admin => EF.Functions.ILike(admin.Role, Roles.SuperAdmin))
            .ToListAsync(ct);

        var repaired = 0;
        foreach (var admin in superAdmins)
        {
            if (HaveSamePermissions(admin.Permissions, expectedPermissions))
            {
                continue;
            }

            admin.Permissions = expectedPermissions.ToList();
            admin.UpdatedAt = DateTime.UtcNow;
            repaired++;
        }

        if (repaired > 0)
        {
            await db.SaveChangesAsync(ct);
        }

        return repaired;
    }

    private static bool HaveSamePermissions(IReadOnlyCollection<string>? current, IReadOnlyCollection<string> expected)
    {
        var currentSet = new HashSet<string>(
            current?.Where(permission => !string.IsNullOrWhiteSpace(permission))
                .Select(permission => permission.Trim()) ?? Array.Empty<string>(),
            StringComparer.OrdinalIgnoreCase);

        var expectedSet = new HashSet<string>(expected, StringComparer.OrdinalIgnoreCase);
        return currentSet.SetEquals(expectedSet);
    }

    private static async Task<bool> HasRuntimeWorkflowSchemaAsync(
        DbConnection connection,
        DbTransaction transaction,
        CancellationToken ct)
    {
        if (!await TablesExistAsync(connection, transaction, RuntimeWorkflowTables, ct))
        {
            return false;
        }

        if (!await ColumnsExistAsync(connection, transaction, "Users", new[] { "Is2FAEnabled", "TotpSecret" }, ct))
        {
            return false;
        }

        return await ColumnsExistAsync(connection, transaction, "Keepers", new[] { "HoldReason", "HoldUntil" }, ct);
    }

    private static async Task<bool> TablesExistAsync(
        DbConnection connection,
        DbTransaction transaction,
        IReadOnlyCollection<string> tableNames,
        CancellationToken ct)
    {
        var quotedNames = string.Join(", ", tableNames.Select(QuoteSqlLiteral));
        var count = await ExecuteScalarIntAsync(
            connection,
            transaction,
            $"""
             SELECT COUNT(*)
             FROM information_schema.tables
             WHERE table_schema = 'public'
               AND table_name IN ({quotedNames});
             """,
            ct);

        return count == tableNames.Count;
    }

    private static async Task<bool> ColumnsExistAsync(
        DbConnection connection,
        DbTransaction transaction,
        string tableName,
        IReadOnlyCollection<string> columnNames,
        CancellationToken ct)
    {
        var quotedColumns = string.Join(", ", columnNames.Select(QuoteSqlLiteral));
        var count = await ExecuteScalarIntAsync(
            connection,
            transaction,
            $"""
             SELECT COUNT(*)
             FROM information_schema.columns
             WHERE table_schema = 'public'
               AND table_name = {QuoteSqlLiteral(tableName)}
               AND column_name IN ({quotedColumns});
             """,
            ct);

        return count == columnNames.Count;
    }

    private static async Task InsertMigrationRowAsync(
        DbConnection connection,
        DbTransaction transaction,
        string migrationId,
        CancellationToken ct)
    {
        await ExecuteNonQueryAsync(
            connection,
            transaction,
            $"""
             INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
             VALUES ({QuoteSqlLiteral(migrationId)}, {QuoteSqlLiteral(EfProductVersion)})
             ON CONFLICT ("MigrationId") DO NOTHING;
             """,
            ct);
    }

    private static async Task<List<string>> GetAppliedMigrationIdsAsync(
        DbConnection connection,
        DbTransaction transaction,
        CancellationToken ct)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = """SELECT "MigrationId" FROM "__EFMigrationsHistory";""";

        var migrationIds = new List<string>();
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            if (!reader.IsDBNull(0))
            {
                migrationIds.Add(reader.GetString(0));
            }
        }

        return migrationIds;
    }

    private static async Task ExecuteNonQueryAsync(
        DbConnection connection,
        DbTransaction transaction,
        string sql,
        CancellationToken ct)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync(ct);
    }

    private static async Task<int> ExecuteScalarIntAsync(
        DbConnection connection,
        DbTransaction transaction,
        string sql,
        CancellationToken ct)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = sql;
        var value = await command.ExecuteScalarAsync(ct);
        return Convert.ToInt32(value);
    }

    private static string QuoteSqlLiteral(string value)
    {
        return $"'{value.Replace("'", "''")}'";
    }
}
