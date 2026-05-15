using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class KeeperAuditScheduleConfiguration : IEntityTypeConfiguration<KeeperAuditSchedule>
{
    public void Configure(EntityTypeBuilder<KeeperAuditSchedule> builder)
    {
        builder.ToTable("keeper_audit_schedules");
        builder.HasKey(schedule => schedule.AuditScheduleId);

        builder.Property(schedule => schedule.Status).HasMaxLength(30).IsRequired();

        builder.HasOne(schedule => schedule.Keeper)
            .WithMany(keeper => keeper.AuditSchedules)
            .HasForeignKey(schedule => schedule.KeeperId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(schedule => schedule.RequestedByAdmin)
            .WithMany()
            .HasForeignKey(schedule => schedule.RequestedByAdminId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
