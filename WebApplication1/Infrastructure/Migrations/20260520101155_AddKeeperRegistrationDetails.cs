using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddKeeperRegistrationDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<List<string>>(
                name: "Tags",
                table: "Shops",
                type: "text[]",
                nullable: false,
                defaultValueSql: "ARRAY[]::text[]",
                oldClrType: typeof(List<string>),
                oldType: "text[]");

            migrationBuilder.AlterColumn<byte[]>(
                name: "ImageData",
                table: "Shops",
                type: "bytea",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<List<string>>(
                name: "Amenities",
                table: "Shops",
                type: "text[]",
                nullable: false,
                defaultValueSql: "ARRAY[]::text[]",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            // migrationBuilder.AddColumn<string>(
            //     name: "ImageUrl",
            //     table: "Shops",
            //     type: "text",
            //     nullable: true);

            migrationBuilder.AlterColumn<byte[]>(
                name: "ImageData",
                table: "Offers",
                type: "bytea",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            // migrationBuilder.AddColumn<string>(
            //     name: "ImageUrl",
            //     table: "Offers",
            //     type: "text",
            //     nullable: true);

            // migrationBuilder.AddColumn<string>(
            //     name: "AddressProofImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "AddressProofType",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "BusinessLicenseImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "BusinessLicenseNumber",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<DateTime>(
            //     name: "DeletedAt",
            //     table: "Keepers",
            //     type: "timestamp with time zone",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "GstCertificateImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "IdentityProofImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "IdentityProofNumber",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "IdentityProofType",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<bool>(
            //     name: "IsVerified",
            //     table: "Keepers",
            //     type: "boolean",
            //     nullable: false,
            //     defaultValue: false);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "PanCardImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "ShopFrontImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "ShopInsideImage",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
            //
            // migrationBuilder.AddColumn<string>(
            //     name: "VerificationNotes",
            //     table: "Keepers",
            //     type: "text",
            //     nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Offers");

            migrationBuilder.DropColumn(
                name: "AddressProofImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "AddressProofType",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "BusinessLicenseImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "BusinessLicenseNumber",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "GstCertificateImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "IdentityProofImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "IdentityProofNumber",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "IdentityProofType",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "IsVerified",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "PanCardImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "ShopFrontImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "ShopInsideImage",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "VerificationNotes",
                table: "Keepers");

            migrationBuilder.AlterColumn<List<string>>(
                name: "Tags",
                table: "Shops",
                type: "text[]",
                nullable: false,
                oldClrType: typeof(List<string>),
                oldType: "text[]",
                oldDefaultValueSql: "ARRAY[]::text[]");

            migrationBuilder.AlterColumn<string>(
                name: "ImageData",
                table: "Shops",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Amenities",
                table: "Shops",
                type: "text",
                nullable: true,
                oldClrType: typeof(List<string>),
                oldType: "text[]",
                oldDefaultValueSql: "ARRAY[]::text[]");

            migrationBuilder.AlterColumn<string>(
                name: "ImageData",
                table: "Offers",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);
        }
    }
}
