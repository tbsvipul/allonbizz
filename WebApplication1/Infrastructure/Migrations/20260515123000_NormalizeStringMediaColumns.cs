using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using routent.AdminAPI.Data;
using routent.AdminAPI.Helpers;

#nullable disable

namespace routent.AdminAPI.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20260515123000_NormalizeStringMediaColumns")]
    public partial class NormalizeStringMediaColumns : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(StringMediaSchemaRepair.BuildMigrationSql());
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(StringMediaSchemaRepair.BuildRollbackSql());
        }
    }
}
