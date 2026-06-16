using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

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
