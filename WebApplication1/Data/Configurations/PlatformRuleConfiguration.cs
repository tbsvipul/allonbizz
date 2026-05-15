using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class PlatformRuleConfiguration : IEntityTypeConfiguration<PlatformRule>
{
    public void Configure(EntityTypeBuilder<PlatformRule> builder)
    {
        builder.ToTable("platform_rules");
        builder.HasKey(r => r.RuleId);
        builder.Property(r => r.RuleId).HasColumnName("rule_id");
    }
}
