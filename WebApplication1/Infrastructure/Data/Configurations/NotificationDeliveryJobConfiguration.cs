using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class NotificationDeliveryJobConfiguration : IEntityTypeConfiguration<NotificationDeliveryJob>
{
    public void Configure(EntityTypeBuilder<NotificationDeliveryJob> builder)
    {
        builder.ToTable("notification_delivery_jobs");
        builder.HasKey(job => job.JobId);

        builder.Property(job => job.Status).HasMaxLength(30).IsRequired();
        builder.HasIndex(job => new { job.NotificationId, job.Status });
        builder.HasIndex(job => job.ScheduledFor);

        builder.HasOne(job => job.Notification)
            .WithMany()
            .HasForeignKey(job => job.NotificationId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
