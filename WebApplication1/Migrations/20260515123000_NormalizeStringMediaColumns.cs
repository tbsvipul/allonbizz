using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Helpers;

#nullable disable

namespace allonbiz.AdminAPI.Migrations
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
