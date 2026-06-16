using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class FavouriteConfiguration : IEntityTypeConfiguration<Favourite>
{
    public void Configure(EntityTypeBuilder<Favourite> builder)
    {
        builder.HasKey(f => f.FavouriteId);

        builder.HasOne(f => f.User)
            .WithMany()
            .HasForeignKey(f => f.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(f => f.Shop)
            .WithMany()
            .HasForeignKey(f => f.ShopId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(f => f.Offer)
            .WithMany()
            .HasForeignKey(f => f.OfferId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
