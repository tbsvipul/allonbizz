using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class MediaAssetConfiguration : IEntityTypeConfiguration<MediaAsset>
{
    public void Configure(EntityTypeBuilder<MediaAsset> builder)
    {
        builder.ToTable("MediaAssets");
        builder.HasKey(x => x.AssetId);

        builder.Property(x => x.AssetId).HasColumnName("AssetId");
        builder.Property(x => x.FileName).HasColumnName("FileName").HasMaxLength(255).IsRequired();
        builder.Property(x => x.ContentType).HasColumnName("ContentType").HasMaxLength(255).IsRequired();
        builder.Property(x => x.Data).HasColumnName("Data");
        builder.Property(x => x.RelatedId).HasColumnName("RelatedId");
        builder.Property(x => x.AssetType).HasColumnName("AssetType").HasMaxLength(100).IsRequired();
        builder.Property(x => x.CreatedAt).HasColumnName("CreatedAt");
    }
}
