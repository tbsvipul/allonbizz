using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class AdminAccountConfiguration : IEntityTypeConfiguration<AdminAccount>
{
    public void Configure(EntityTypeBuilder<AdminAccount> builder)
    {
        builder.ToTable("admin_accounts");
        builder.HasKey(a => a.AdminId);

        builder.Property(a => a.AdminId).HasColumnName("admin_id");
        builder.Property(a => a.Email).HasColumnName("email").HasMaxLength(255).IsRequired();
        builder.Property(a => a.PasswordHash).HasColumnName("password_hash").HasMaxLength(512).IsRequired();
        builder.Property(a => a.FirstName).HasColumnName("first_name").HasMaxLength(100).IsRequired();
        builder.Property(a => a.LastName).HasColumnName("last_name").HasMaxLength(100).IsRequired();
        builder.Property(a => a.Role).HasColumnName("role").HasMaxLength(20).IsRequired();
        builder.Property(a => a.IsActive).HasColumnName("is_active").HasDefaultValue(true);
        builder.Property(a => a.Is2FAEnabled).HasColumnName("is_2fa_enabled").HasDefaultValue(false);
        builder.Property(a => a.TotpSecret).HasColumnName("totp_secret").HasMaxLength(256);
        builder.Property(a => a.Permissions).HasColumnName("Permissions").HasColumnType("text[]");
        builder.Property(a => a.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(a => a.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");
        builder.Property(a => a.LastLoginAt).HasColumnName("last_login_at");
        builder.Property(a => a.LastLoginIp).HasColumnName("last_login_ip").HasMaxLength(50);
        builder.Property(a => a.FailedLoginAttempts).HasColumnName("FailedLoginAttempts").HasDefaultValue(0);
        builder.Property(a => a.LockoutEnd).HasColumnName("LockoutEnd");

        builder.HasIndex(a => a.Email).IsUnique();
    }
}
