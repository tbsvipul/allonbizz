using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace allonbiz.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveLoyaltyProgram : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "loyalty_wallets");

            migrationBuilder.DropTable(
                name: "shop_loyalty_programs");

            migrationBuilder.DropColumn(
                name: "LoyaltyPointsEarned",
                table: "Redemptions");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "LoyaltyPointsEarned",
                table: "Redemptions",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "loyalty_wallets",
                columns: table => new
                {
                    wallet_id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    RedeemedPoints = table.Column<int>(type: "integer", nullable: false),
                    Tier = table.Column<string>(type: "text", nullable: false),
                    TotalPoints = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_loyalty_wallets", x => x.wallet_id);
                    table.ForeignKey(
                        name: "FK_loyalty_wallets_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "shop_loyalty_programs",
                columns: table => new
                {
                    ProgramId = table.Column<Guid>(type: "uuid", nullable: false),
                    ShopId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    MinimumPointsToRedeem = table.Column<int>(type: "integer", nullable: false),
                    PointsPerRedemption = table.Column<int>(type: "integer", nullable: false),
                    ProgramName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    RewardDescription = table.Column<string>(type: "text", nullable: true),
                    TermsAndConditions = table.Column<string>(type: "text", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_shop_loyalty_programs", x => x.ProgramId);
                    table.ForeignKey(
                        name: "FK_shop_loyalty_programs_Shops_ShopId",
                        column: x => x.ShopId,
                        principalTable: "Shops",
                        principalColumn: "ShopId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_loyalty_wallets_UserId",
                table: "loyalty_wallets",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_shop_loyalty_programs_ShopId",
                table: "shop_loyalty_programs",
                column: "ShopId",
                unique: true);
        }
    }
}
