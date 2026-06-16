using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.HasKey(r => r.ReviewId);

        builder.HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.Shop)
            .WithMany(s => s.Reviews)
            .HasForeignKey(r => r.ShopId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.Offer)
            .WithMany()
            .HasForeignKey(r => r.OfferId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
