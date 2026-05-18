using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("refresh_tokens");
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Token).HasMaxLength(255).IsRequired();
        builder.Property(t => t.Role).HasMaxLength(20).IsRequired();
        builder.Property(t => t.CreatedByIp).HasMaxLength(50);
        builder.Property(t => t.ReplacedByToken).HasMaxLength(255);
    }
}
