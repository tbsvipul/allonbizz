using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Data.Configurations;

public class RouteRecordConfiguration : IEntityTypeConfiguration<RouteRecord>
{
    public void Configure(EntityTypeBuilder<RouteRecord> builder)
    {
        builder.ToTable("route_records");
        builder.HasKey(r => r.RouteId);
        builder.Property(r => r.RouteId).HasColumnName("route_id");
    }
}
