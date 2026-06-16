using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeactivatedShopStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Shops_VerifyStatus",
                table: "Shops");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Shops_VerifyStatus",
                table: "Shops",
                sql: "\"VerifyStatus\" IN ('Pending', 'Verified', 'Rejected', 'Deactivated')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Shops_VerifyStatus",
                table: "Shops");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Shops_VerifyStatus",
                table: "Shops",
                sql: "\"VerifyStatus\" IN ('Pending', 'Verified', 'Rejected')");
        }
    }
}
