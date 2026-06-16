using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class KeeperReviewMessageConfiguration : IEntityTypeConfiguration<KeeperReviewMessage>
{
    public void Configure(EntityTypeBuilder<KeeperReviewMessage> builder)
    {
        builder.ToTable("keeper_review_messages");
        builder.HasKey(message => message.MessageId);

        builder.Property(message => message.MessageType).HasMaxLength(50).IsRequired();
        builder.Property(message => message.Message).IsRequired();

        builder.HasOne(message => message.Keeper)
            .WithMany(keeper => keeper.ReviewMessages)
            .HasForeignKey(message => message.KeeperId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(message => message.Admin)
            .WithMany()
            .HasForeignKey(message => message.AdminId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
