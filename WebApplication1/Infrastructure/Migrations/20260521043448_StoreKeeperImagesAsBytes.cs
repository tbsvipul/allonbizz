using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace allonbiz.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class StoreKeeperImagesAsBytes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "ShopInsideImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "ShopInsideImage", table: "Keepers", type: "bytea", nullable: true);

            migrationBuilder.DropColumn(name: "ShopFrontImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "ShopFrontImage", table: "Keepers", type: "bytea", nullable: true);

            migrationBuilder.DropColumn(name: "PanCardImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "PanCardImage", table: "Keepers", type: "bytea", nullable: true);

            migrationBuilder.DropColumn(name: "IdentityProofImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "IdentityProofImage", table: "Keepers", type: "bytea", nullable: true);

            migrationBuilder.DropColumn(name: "GstCertificateImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "GstCertificateImage", table: "Keepers", type: "bytea", nullable: true);

            migrationBuilder.DropColumn(name: "BusinessLicenseImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "BusinessLicenseImage", table: "Keepers", type: "bytea", nullable: true);

            migrationBuilder.DropColumn(name: "AddressProofImage", table: "Keepers");
            migrationBuilder.AddColumn<byte[]>(name: "AddressProofImage", table: "Keepers", type: "bytea", nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "ShopInsideImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ShopFrontImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PanCardImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "IdentityProofImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "GstCertificateImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "BusinessLicenseImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "AddressProofImage",
                table: "Keepers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);
        }
    }
}
