using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class ShopConfiguration : IEntityTypeConfiguration<Shop>
{
    public void Configure(EntityTypeBuilder<Shop> builder)
    {
        builder.HasKey(s => s.ShopId);

        // Explicitly map List<string> to text[] for PostgreSQL
        builder.Property(s => s.Tags)
            .HasColumnType("text[]")
            .HasDefaultValueSql("ARRAY[]::text[]")
            .IsRequired();

        builder.Property(s => s.Amenities)
            .HasColumnType("text[]")
            .HasDefaultValueSql("ARRAY[]::text[]")
            .IsRequired();

        // Handle other specific mappings if necessary
        builder.HasOne(s => s.Keeper)
            .WithMany(k => k.Shops)
            .HasForeignKey(s => s.KeeperId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Category)
            .WithMany()
            .HasForeignKey(s => s.CategoryId)
            .IsRequired(false);
    }
}
