using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace allonbiz.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateShopAndOfferImages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Use IF NOT EXISTS to prevent errors since columns may already exist in the database
            migrationBuilder.Sql("ALTER TABLE \"Shops\" ADD COLUMN IF NOT EXISTS \"ShopProfileImage\" text;");
            migrationBuilder.Sql("ALTER TABLE \"Shops\" ADD COLUMN IF NOT EXISTS \"ShopImages\" text[] NOT NULL DEFAULT ARRAY[]::text[];");
            
            // Ensure Offers table also has its missing ImageUrl column
            migrationBuilder.Sql("ALTER TABLE \"Offers\" ADD COLUMN IF NOT EXISTS \"ImageUrl\" text;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ShopProfileImage",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "ShopImages",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Offers");
        }
    }
}
