using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace allonbiz.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserJourneyStats : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "TotalKm",
                table: "Users",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "TotalSaved",
                table: "Users",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<int>(
                name: "TotalTrips",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TotalKm",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TotalSaved",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TotalTrips",
                table: "Users");
        }
    }
}
