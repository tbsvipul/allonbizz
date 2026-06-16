using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class ModerationQueueConfiguration : IEntityTypeConfiguration<ModerationQueueItem>
{
    public void Configure(EntityTypeBuilder<ModerationQueueItem> builder)
    {
        builder.ToTable("moderation_queue");
        builder.HasKey(m => m.ItemId);

        builder.Property(m => m.ItemId).HasColumnName("item_id");
        builder.Property(m => m.ContentType).HasColumnName("content_type").HasMaxLength(20).IsRequired();
        builder.Property(m => m.Title).HasColumnName("title").HasMaxLength(500).IsRequired();
        builder.Property(m => m.Preview).HasColumnName("preview");
        builder.Property(m => m.ReferenceId).HasColumnName("reference_id").IsRequired();
        builder.Property(m => m.SubmittedBy).HasColumnName("submitted_by").IsRequired();
        builder.Property(m => m.SubmittedAt).HasColumnName("submitted_at").HasDefaultValueSql("NOW()");
        builder.Property(m => m.Status).HasColumnName("status").HasMaxLength(20).HasDefaultValue("pending");
        builder.Property(m => m.ReportCount).HasColumnName("report_count").HasDefaultValue(0);
        builder.Property(m => m.ReviewedBy).HasColumnName("reviewed_by");
        builder.Property(m => m.ReviewedAt).HasColumnName("reviewed_at");
        builder.Property(m => m.RejectionReason).HasColumnName("rejection_reason");

        builder.HasIndex(m => m.Status);
        builder.HasIndex(m => m.ContentType);

        builder.HasOne(m => m.Reviewer).WithMany().HasForeignKey(m => m.ReviewedBy);
    }
}
