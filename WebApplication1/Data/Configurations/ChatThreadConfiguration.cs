using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class ChatThreadConfiguration : IEntityTypeConfiguration<ChatThread>
{
    public void Configure(EntityTypeBuilder<ChatThread> builder)
    {
        builder.ToTable("chat_threads");
        builder.HasKey(thread => thread.ThreadId);

        builder.Property(thread => thread.Status).HasMaxLength(30).IsRequired();
        builder.HasIndex(thread => new { thread.UserId, thread.KeeperId }).IsUnique();

        builder.HasOne(thread => thread.User)
            .WithMany()
            .HasForeignKey(thread => thread.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(thread => thread.Keeper)
            .WithMany()
            .HasForeignKey(thread => thread.KeeperId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
