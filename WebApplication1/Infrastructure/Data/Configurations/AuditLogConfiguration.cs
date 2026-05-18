using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class AuditLogConfiguration : IEntityTypeConfiguration<AuditLog>
{
    public void Configure(EntityTypeBuilder<AuditLog> builder)
    {
        builder.ToTable("audit_logs");
        builder.HasKey(a => a.AuditId);

        builder.Property(a => a.AuditId).HasColumnName("audit_id");
        builder.Property(a => a.AdminId).HasColumnName("admin_id").IsRequired();
        builder.Property(a => a.Action).HasColumnName("action").HasMaxLength(100).IsRequired();
        builder.Property(a => a.TargetEntity).HasColumnName("target_entity").HasMaxLength(100).IsRequired();
        builder.Property(a => a.TargetId).HasColumnName("target_id").HasMaxLength(255).IsRequired();
        builder.Property(a => a.Changes).HasColumnName("changes").HasColumnType("jsonb");
        builder.Property(a => a.Timestamp).HasColumnName("timestamp").HasDefaultValueSql("NOW()");
        builder.Property(a => a.IpAddress).HasColumnName("ip_address").HasMaxLength(50);
        builder.Property(a => a.UserAgent).HasColumnName("user_agent");

        builder.HasOne(a => a.Admin).WithMany().HasForeignKey(a => a.AdminId);
        builder.HasIndex(a => a.AdminId);
        builder.HasIndex(a => a.Timestamp).IsDescending();
    }
}
