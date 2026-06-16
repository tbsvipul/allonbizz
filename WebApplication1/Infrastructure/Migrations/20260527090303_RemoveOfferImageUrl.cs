using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveOfferImageUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("ALTER TABLE \"Offers\" DROP COLUMN IF EXISTS \"ImageUrl\";");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "Offers",
                type: "text",
                nullable: true);
        }
    }
}
