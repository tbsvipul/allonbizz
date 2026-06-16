using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class AuthChallengeConfiguration : IEntityTypeConfiguration<AuthChallenge>
{
    public void Configure(EntityTypeBuilder<AuthChallenge> builder)
    {
        builder.ToTable("auth_challenges");
        builder.HasKey(challenge => challenge.ChallengeId);

        builder.Property(challenge => challenge.Email).HasMaxLength(255).IsRequired();
        builder.Property(challenge => challenge.AccountType).HasMaxLength(20).IsRequired();
        builder.Property(challenge => challenge.ChallengeType).HasMaxLength(40).IsRequired();
        builder.Property(challenge => challenge.SecretHash).HasMaxLength(128).IsRequired();

        builder.HasIndex(challenge => new { challenge.Email, challenge.ChallengeType, challenge.ConsumedAt });
        builder.HasIndex(challenge => challenge.ExpiresAt);
    }
}
