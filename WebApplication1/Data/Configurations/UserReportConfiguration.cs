using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class UserReportConfiguration : IEntityTypeConfiguration<UserReport>
{
    public void Configure(EntityTypeBuilder<UserReport> builder)
    {
        builder.ToTable("user_reports");
        builder.HasKey(r => r.ReportId);

        builder.Property(r => r.ReportId).HasColumnName("report_id");
        builder.Property(r => r.ReportedItemId).HasColumnName("reported_item_id").HasMaxLength(255).IsRequired();
        builder.Property(r => r.ItemType).HasColumnName("item_type").HasMaxLength(20).IsRequired();
        builder.Property(r => r.ReportedBy).HasColumnName("reported_by").IsRequired();
        builder.Property(r => r.Reason).HasColumnName("reason").HasMaxLength(30).IsRequired();
        builder.Property(r => r.Comments).HasColumnName("comments");
        builder.Property(r => r.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(r => r.Status).HasColumnName("status").HasMaxLength(20).HasDefaultValue("pending");
        builder.Property(r => r.HandledBy).HasColumnName("handled_by");
        builder.Property(r => r.ResolutionNote).HasColumnName("resolution_note");
        builder.Property(r => r.ResolvedAt).HasColumnName("resolved_at");

        builder.HasOne(r => r.Handler).WithMany().HasForeignKey(r => r.HandledBy);
    }
}
