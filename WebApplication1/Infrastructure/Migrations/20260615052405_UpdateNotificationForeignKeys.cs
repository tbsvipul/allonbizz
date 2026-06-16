using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateNotificationForeignKeys : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Offers_OfferId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Shops_ShopId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Users_UserId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_admin_accounts_SentByAdminAdminId",
                table: "Notifications");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Offers_OfferId",
                table: "Notifications",
                column: "OfferId",
                principalTable: "Offers",
                principalColumn: "OfferId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Shops_ShopId",
                table: "Notifications",
                column: "ShopId",
                principalTable: "Shops",
                principalColumn: "ShopId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Users_UserId",
                table: "Notifications",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "UserId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_admin_accounts_SentByAdminAdminId",
                table: "Notifications",
                column: "SentByAdminAdminId",
                principalTable: "admin_accounts",
                principalColumn: "admin_id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Offers_OfferId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Shops_ShopId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Users_UserId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_admin_accounts_SentByAdminAdminId",
                table: "Notifications");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Offers_OfferId",
                table: "Notifications",
                column: "OfferId",
                principalTable: "Offers",
                principalColumn: "OfferId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Shops_ShopId",
                table: "Notifications",
                column: "ShopId",
                principalTable: "Shops",
                principalColumn: "ShopId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Users_UserId",
                table: "Notifications",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_admin_accounts_SentByAdminAdminId",
                table: "Notifications",
                column: "SentByAdminAdminId",
                principalTable: "admin_accounts",
                principalColumn: "admin_id");
        }
    }
}
