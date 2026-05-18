using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class ShopLoyaltyProgramConfiguration : IEntityTypeConfiguration<ShopLoyaltyProgram>
{
    public void Configure(EntityTypeBuilder<ShopLoyaltyProgram> builder)
    {
        builder.ToTable("shop_loyalty_programs");
        builder.HasKey(program => program.ProgramId);

        builder.Property(program => program.ProgramName).HasMaxLength(200);
        builder.HasIndex(program => program.ShopId).IsUnique();

        builder.HasOne(program => program.Shop)
            .WithMany()
            .HasForeignKey(program => program.ShopId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
