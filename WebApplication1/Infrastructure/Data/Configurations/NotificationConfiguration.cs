using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.HasKey(n => n.NotificationId);

        builder.HasOne(n => n.Offer)
            .WithMany()
            .HasForeignKey(n => n.OfferId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(n => n.Shop)
            .WithMany()
            .HasForeignKey(n => n.ShopId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(n => n.User)
            .WithMany()
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(n => n.SentByAdmin)
            .WithMany()
            .HasForeignKey(n => n.SentByAdminAdminId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
