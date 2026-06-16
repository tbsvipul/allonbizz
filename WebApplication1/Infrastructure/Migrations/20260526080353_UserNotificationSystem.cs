using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UserNotificationSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<byte[]>(
                name: "ShopProfileImage",
                table: "Shops",
                type: "bytea",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<List<byte[]>>(
                name: "ShopImages",
                table: "Shops",
                type: "bytea[]",
                nullable: false,
                defaultValueSql: "ARRAY[]::bytea[]",
                oldClrType: typeof(List<string>),
                oldType: "text[]",
                oldDefaultValueSql: "ARRAY[]::text[]");

            /*
            migrationBuilder.AddColumn<string>(
                name: "DeactivateReason",
                table: "Shops",
                type: "text",
                nullable: true);
            */

            /*
            migrationBuilder.AddColumn<string>(
                name: "VerifyStatus",
                table: "Shops",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "Pending");
            */

            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "Notifications",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Notifications",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsGlobal",
                table: "Notifications",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "Latitude",
                table: "Notifications",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Longitude",
                table: "Notifications",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OfferId",
                table: "Notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "RadiusKm",
                table: "Notifications",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SenderId",
                table: "Notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SenderType",
                table: "Notifications",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "ShopId",
                table: "Notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "NotificationLogs",
                columns: table => new
                {
                    LogId = table.Column<Guid>(type: "uuid", nullable: false),
                    NotificationId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    FailureReason = table.Column<string>(type: "text", nullable: true),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DeliveredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationLogs", x => x.LogId);
                    table.ForeignKey(
                        name: "FK_NotificationLogs_Notifications_NotificationId",
                        column: x => x.NotificationId,
                        principalTable: "Notifications",
                        principalColumn: "NotificationId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_NotificationLogs_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "ShopNotificationSettings",
                columns: table => new
                {
                    SettingId = table.Column<Guid>(type: "uuid", nullable: false),
                    ShopId = table.Column<Guid>(type: "uuid", nullable: false),
                    AutoRadiusNotification = table.Column<bool>(type: "boolean", nullable: false),
                    RadiusKm = table.Column<decimal>(type: "numeric", nullable: false),
                    CooldownHours = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShopNotificationSettings", x => x.SettingId);
                    table.ForeignKey(
                        name: "FK_ShopNotificationSettings_Shops_ShopId",
                        column: x => x.ShopId,
                        principalTable: "Shops",
                        principalColumn: "ShopId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserNotifications",
                columns: table => new
                {
                    UserNotificationId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    NotificationId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DeliveryStatus = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserNotifications", x => x.UserNotificationId);
                    table.ForeignKey(
                        name: "FK_UserNotifications_Notifications_NotificationId",
                        column: x => x.NotificationId,
                        principalTable: "Notifications",
                        principalColumn: "NotificationId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserNotifications_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddCheckConstraint(
                name: "CK_Shops_VerifyStatus",
                table: "Shops",
                sql: "\"VerifyStatus\" IN ('Pending', 'Verified', 'Rejected')");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_OfferId",
                table: "Notifications",
                column: "OfferId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_ShopId",
                table: "Notifications",
                column: "ShopId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationLogs_NotificationId",
                table: "NotificationLogs",
                column: "NotificationId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationLogs_UserId",
                table: "NotificationLogs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ShopNotificationSettings_ShopId",
                table: "ShopNotificationSettings",
                column: "ShopId");

            migrationBuilder.CreateIndex(
                name: "IX_UserNotifications_NotificationId",
                table: "UserNotifications",
                column: "NotificationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserNotifications_UserId",
                table: "UserNotifications",
                column: "UserId");

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

            migrationBuilder.DropTable(
                name: "NotificationLogs");

            migrationBuilder.DropTable(
                name: "ShopNotificationSettings");

            migrationBuilder.DropTable(
                name: "UserNotifications");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Shops_VerifyStatus",
                table: "Shops");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_OfferId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_ShopId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "DeactivateReason",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "VerifyStatus",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "IsGlobal",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "OfferId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "RadiusKm",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "SenderId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "SenderType",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "ShopId",
                table: "Notifications");

            migrationBuilder.AlterColumn<string>(
                name: "ShopProfileImage",
                table: "Shops",
                type: "text",
                nullable: true,
                oldClrType: typeof(byte[]),
                oldType: "bytea",
                oldNullable: true);

            migrationBuilder.AlterColumn<List<string>>(
                name: "ShopImages",
                table: "Shops",
                type: "text[]",
                nullable: false,
                defaultValueSql: "ARRAY[]::text[]",
                oldClrType: typeof(List<byte[]>),
                oldType: "bytea[]",
                oldDefaultValueSql: "ARRAY[]::bytea[]");
        }
    }
}
