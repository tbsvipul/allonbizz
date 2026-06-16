using System.Data;
using System.Data.Common;
using System.Text;
using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Data;

namespace routent.AdminAPI.Helpers;

public static class StringMediaSchemaRepair
{
    private const string Utf8ProbeFunctionName = "routent_try_convert_utf8";

    private static readonly MediaColumnTarget[] Targets =
    {
        new("Keepers", "DocumentData", "KeeperId"),
        new("Categories", "IconData", "CategoryId"),
        new("Tags", "IconData", "TagId"),
        new("Users", "ProfilePhotoData", "UserId"),
        new("Keepers", "IdentityProofImage", "KeeperId"),
        new("Keepers", "BusinessLicenseImage", "KeeperId"),
        new("Keepers", "GstCertificateImage", "KeeperId"),
        new("Keepers", "PanCardImage", "KeeperId"),
        new("Keepers", "AddressProofImage", "KeeperId"),
        new("Keepers", "ShopFrontImage", "KeeperId"),
        new("Keepers", "ShopInsideImage", "KeeperId")
    };

    public static async Task<MediaRepairSummary> RepairAsync(
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
            await ExecuteNonQueryAsync(connection, BuildCreateUtf8ProbeFunctionSql(), ct);

            var normalizedColumns = 0;
            var fallbackRows = 0;

            foreach (var target in Targets)
            {
                if (!await IsByteaColumnAsync(connection, target, ct))
                {
                    continue;
                }

                var invalidIds = await GetInvalidRowIdsAsync(connection, target, ct);
                if (invalidIds.Count > 0)
                {
                    fallbackRows += invalidIds.Count;
                    logger?.LogWarning(
                        "Converting non-text binary data in {Table}.{Column} for rows: {RowIds}",
                        target.TableName,
                        target.ColumnName,
                        string.Join(", ", invalidIds));

                    await ExecuteNonQueryAsync(connection, BuildFallbackUpdateSql(target), ct);
                }

                await ExecuteNonQueryAsync(connection, BuildAlterColumnToTextSql(target), ct);
                normalizedColumns++;

                logger?.LogWarning(
                    "Normalized column {Table}.{Column} from bytea to text.",
                    target.TableName,
                    target.ColumnName);
            }

            return new MediaRepairSummary(normalizedColumns, fallbackRows);
        }
        finally
        {
            if (connection.State == ConnectionState.Open)
            {
                try
                {
                    await ExecuteNonQueryAsync(connection, $"DROP FUNCTION IF EXISTS {Utf8ProbeFunctionName}(bytea);", ct);
                }
                catch
                {
                    // Best effort cleanup for a transient helper function.
                }
            }

            if (shouldClose && connection.State != ConnectionState.Closed)
            {
                await connection.CloseAsync();
            }
        }
    }

    public static string BuildMigrationSql()
    {
        var builder = new StringBuilder();
        builder.AppendLine(BuildCreateUtf8ProbeFunctionSql());

        foreach (var target in Targets)
        {
            builder.AppendLine(BuildMigrationRepairBlockSql(target));
        }

        builder.AppendLine($"DROP FUNCTION IF EXISTS {Utf8ProbeFunctionName}(bytea);");
        return builder.ToString();
    }

    public static string BuildRollbackSql()
    {
        var builder = new StringBuilder();

        foreach (var target in Targets)
        {
            builder.AppendLine(
                $"""
                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1
                        FROM information_schema.columns
                        WHERE table_schema = 'public'
                          AND table_name = {QuoteSqlLiteral(target.TableName)}
                          AND column_name = {QuoteSqlLiteral(target.ColumnName)}
                          AND data_type = 'text'
                    ) THEN
                        ALTER TABLE {QuoteIdentifier(target.TableName)}
                        ALTER COLUMN {QuoteIdentifier(target.ColumnName)} TYPE bytea
                        USING CASE
                            WHEN {QuoteIdentifier(target.ColumnName)} IS NULL THEN NULL
                            ELSE convert_to({QuoteIdentifier(target.ColumnName)}, 'UTF8')
                        END;
                    END IF;
                END $$;
                """);
        }

        return builder.ToString();
    }

    private static string BuildMigrationRepairBlockSql(MediaColumnTarget target)
    {
        return
            $"""
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = {QuoteSqlLiteral(target.TableName)}
                      AND column_name = {QuoteSqlLiteral(target.ColumnName)}
                      AND udt_name = 'bytea'
                ) THEN
                    {BuildFallbackUpdateSql(target)}

                    {BuildAlterColumnToTextSql(target)}
                END IF;
            END $$;
            """;
    }

    private static string BuildCreateUtf8ProbeFunctionSql()
    {
        return
            $"""
            CREATE OR REPLACE FUNCTION {Utf8ProbeFunctionName}(input bytea)
            RETURNS text
            LANGUAGE plpgsql
            AS $$
            BEGIN
                RETURN convert_from(input, 'UTF8');
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN NULL;
            END;
            $$;
            """;
    }

    private static async Task<bool> IsByteaColumnAsync(
        DbConnection connection,
        MediaColumnTarget target,
        CancellationToken ct)
    {
        var sql =
            $"""
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = {QuoteSqlLiteral(target.TableName)}
                  AND column_name = {QuoteSqlLiteral(target.ColumnName)}
                  AND udt_name = 'bytea'
            ) THEN 1 ELSE 0 END;
            """;

        return await ExecuteScalarIntAsync(connection, sql, ct) == 1;
    }

    private static async Task<List<string>> GetInvalidRowIdsAsync(
        DbConnection connection,
        MediaColumnTarget target,
        CancellationToken ct)
    {
        var sql =
            $"""
            SELECT {QuoteIdentifier(target.KeyColumnName)}::text
            FROM {QuoteIdentifier(target.TableName)}
            WHERE {QuoteIdentifier(target.ColumnName)} IS NOT NULL
              AND octet_length({QuoteIdentifier(target.ColumnName)}) > 0
              AND {Utf8ProbeFunctionName}({QuoteIdentifier(target.ColumnName)}) IS NULL;
            """;

        await using var command = connection.CreateCommand();
        command.CommandText = sql;

        var rowIds = new List<string>();
        await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            if (!reader.IsDBNull(0))
            {
                rowIds.Add(reader.GetString(0));
            }
        }

        return rowIds;
    }

    private static string BuildFallbackUpdateSql(MediaColumnTarget target)
    {
        return
            $"""
            UPDATE {QuoteIdentifier(target.TableName)}
            SET {QuoteIdentifier(target.ColumnName)} =
                convert_to(
                    'data:application/octet-stream;base64,' || encode({QuoteIdentifier(target.ColumnName)}, 'base64'),
                    'UTF8')
            WHERE {QuoteIdentifier(target.ColumnName)} IS NOT NULL
              AND octet_length({QuoteIdentifier(target.ColumnName)}) > 0
              AND {Utf8ProbeFunctionName}({QuoteIdentifier(target.ColumnName)}) IS NULL;
            """;
    }

    private static string BuildAlterColumnToTextSql(MediaColumnTarget target)
    {
        return
            $"""
            ALTER TABLE {QuoteIdentifier(target.TableName)}
            ALTER COLUMN {QuoteIdentifier(target.ColumnName)} TYPE text
            USING CASE
                WHEN {QuoteIdentifier(target.ColumnName)} IS NULL THEN NULL
                ELSE convert_from({QuoteIdentifier(target.ColumnName)}, 'UTF8')
            END;
            """;
    }

    private static async Task ExecuteNonQueryAsync(
        DbConnection connection,
        string sql,
        CancellationToken ct)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync(ct);
    }

    private static async Task<int> ExecuteScalarIntAsync(
        DbConnection connection,
        string sql,
        CancellationToken ct)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        var result = await command.ExecuteScalarAsync(ct);
        return Convert.ToInt32(result);
    }

    private static string QuoteIdentifier(string identifier)
    {
        return $"\"{identifier.Replace("\"", "\"\"")}\"";
    }

    private static string QuoteSqlLiteral(string value)
    {
        return $"'{value.Replace("'", "''")}'";
    }

    private sealed record MediaColumnTarget(string TableName, string ColumnName, string KeyColumnName);
}

public readonly record struct MediaRepairSummary(int NormalizedColumns, int FallbackRows);
