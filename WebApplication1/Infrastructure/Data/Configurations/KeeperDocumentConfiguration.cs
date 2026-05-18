using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class KeeperDocumentConfiguration : IEntityTypeConfiguration<KeeperDocument>
{
    public void Configure(EntityTypeBuilder<KeeperDocument> builder)
    {
        builder.ToTable("keeper_documents");
        builder.HasKey(document => document.DocumentId);

        builder.Property(document => document.Name).HasMaxLength(200).IsRequired();
        builder.Property(document => document.DocumentType).HasMaxLength(100).IsRequired();
        builder.Property(document => document.DocumentReference).IsRequired();
        builder.Property(document => document.Status).HasMaxLength(30).IsRequired();

        builder.HasOne(document => document.Keeper)
            .WithMany(keeper => keeper.Documents)
            .HasForeignKey(document => document.KeeperId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(document => document.ReviewedByAdmin)
            .WithMany()
            .HasForeignKey(document => document.ReviewedByAdminId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
