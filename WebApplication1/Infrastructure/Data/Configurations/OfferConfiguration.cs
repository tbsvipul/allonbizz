using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class OfferConfiguration : IEntityTypeConfiguration<Offer>
{
    public void Configure(EntityTypeBuilder<Offer> builder)
    {
        builder.HasKey(o => o.OfferId);

        // Explicitly map List<string> to text[] for PostgreSQL
        builder.Property(o => o.Tags)
            .HasColumnType("text[]")
            .IsRequired();

        builder.HasOne(o => o.Shop)
            .WithMany(s => s.Offers)
            .HasForeignKey(o => o.ShopId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(o => o.Keeper)
            .WithMany()
            .HasForeignKey(o => o.KeeperId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(o => o.Category)
            .WithMany()
            .HasForeignKey(o => o.CategoryId)
            .IsRequired(false);
    }
}
