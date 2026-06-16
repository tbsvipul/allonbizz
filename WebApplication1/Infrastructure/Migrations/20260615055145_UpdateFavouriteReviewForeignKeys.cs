using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateFavouriteReviewForeignKeys : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Favourites_Offers_OfferId",
                table: "Favourites");

            migrationBuilder.DropForeignKey(
                name: "FK_Favourites_Shops_ShopId",
                table: "Favourites");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Offers_OfferId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Shops_ShopId",
                table: "Reviews");

            migrationBuilder.AddForeignKey(
                name: "FK_Favourites_Offers_OfferId",
                table: "Favourites",
                column: "OfferId",
                principalTable: "Offers",
                principalColumn: "OfferId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Favourites_Shops_ShopId",
                table: "Favourites",
                column: "ShopId",
                principalTable: "Shops",
                principalColumn: "ShopId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Offers_OfferId",
                table: "Reviews",
                column: "OfferId",
                principalTable: "Offers",
                principalColumn: "OfferId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Shops_ShopId",
                table: "Reviews",
                column: "ShopId",
                principalTable: "Shops",
                principalColumn: "ShopId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Favourites_Offers_OfferId",
                table: "Favourites");

            migrationBuilder.DropForeignKey(
                name: "FK_Favourites_Shops_ShopId",
                table: "Favourites");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Offers_OfferId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Shops_ShopId",
                table: "Reviews");

            migrationBuilder.AddForeignKey(
                name: "FK_Favourites_Offers_OfferId",
                table: "Favourites",
                column: "OfferId",
                principalTable: "Offers",
                principalColumn: "OfferId");

            migrationBuilder.AddForeignKey(
                name: "FK_Favourites_Shops_ShopId",
                table: "Favourites",
                column: "ShopId",
                principalTable: "Shops",
                principalColumn: "ShopId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Offers_OfferId",
                table: "Reviews",
                column: "OfferId",
                principalTable: "Offers",
                principalColumn: "OfferId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Shops_ShopId",
                table: "Reviews",
                column: "ShopId",
                principalTable: "Shops",
                principalColumn: "ShopId");
        }
    }
}
