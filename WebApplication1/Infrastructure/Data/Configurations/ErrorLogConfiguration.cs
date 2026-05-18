using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class ErrorLogConfiguration : IEntityTypeConfiguration<ErrorLog>
{
    public void Configure(EntityTypeBuilder<ErrorLog> builder)
    {
        builder.ToTable("error_logs");
        builder.HasKey(e => e.LogId);

        builder.Property(e => e.LogId).HasColumnName("log_id");
        builder.Property(e => e.Timestamp).HasColumnName("timestamp").HasDefaultValueSql("NOW()");
        builder.Property(e => e.ErrorType).HasColumnName("error_type").HasMaxLength(100).IsRequired();
        builder.Property(e => e.Message).HasColumnName("message").IsRequired();
        builder.Property(e => e.StackTrace).HasColumnName("stack_trace");
        builder.Property(e => e.UserId).HasColumnName("user_id");
        builder.Property(e => e.Endpoint).HasColumnName("endpoint").HasMaxLength(500);
        builder.Property(e => e.HttpMethod).HasColumnName("http_method").HasMaxLength(10);
        builder.Property(e => e.Severity).HasColumnName("severity").HasMaxLength(10).IsRequired();
        builder.Property(e => e.Resolved).HasColumnName("resolved").HasDefaultValue(false);
        builder.Property(e => e.ResolvedBy).HasColumnName("resolved_by");
        builder.Property(e => e.ResolvedAt).HasColumnName("resolved_at");

        builder.HasIndex(e => e.Severity);
        builder.HasIndex(e => e.Resolved);

        builder.HasOne(e => e.Resolver).WithMany().HasForeignKey(e => e.ResolvedBy);
    }
}
