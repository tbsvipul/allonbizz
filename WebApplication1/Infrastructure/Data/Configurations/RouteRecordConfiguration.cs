using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Data.Configurations;

public class RouteRecordConfiguration : IEntityTypeConfiguration<RouteRecord>
{
    public void Configure(EntityTypeBuilder<RouteRecord> builder)
    {
        builder.ToTable("route_records");
        builder.HasKey(r => r.RouteId);
        builder.Property(r => r.RouteId).HasColumnName("route_id");
    }
}
