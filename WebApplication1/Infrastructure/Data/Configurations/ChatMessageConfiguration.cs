using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class ChatMessageConfiguration : IEntityTypeConfiguration<ChatMessage>
{
    public void Configure(EntityTypeBuilder<ChatMessage> builder)
    {
        builder.ToTable("chat_messages");
        builder.HasKey(message => message.MessageId);

        builder.Property(message => message.SenderType).HasMaxLength(20).IsRequired();
        builder.Property(message => message.Message).IsRequired();

        builder.HasOne(message => message.Thread)
            .WithMany(thread => thread.Messages)
            .HasForeignKey(message => message.ThreadId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
