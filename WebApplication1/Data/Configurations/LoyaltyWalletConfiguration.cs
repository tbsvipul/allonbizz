using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class LoyaltyWalletConfiguration : IEntityTypeConfiguration<LoyaltyWallet>
{
    public void Configure(EntityTypeBuilder<LoyaltyWallet> builder)
    {
        builder.ToTable("loyalty_wallets");
        builder.HasKey(w => w.WalletId);
        builder.Property(w => w.WalletId).HasColumnName("wallet_id");
    }
}
