using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace allonbiz.AdminAPI.Migrations
{
    /// <inheritdoc />
    public partial class PersistRuntimeWorkflowsAndRemoveDemoAuth : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "Is2FAEnabled",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "TotpSecret",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HoldReason",
                table: "Keepers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "HoldUntil",
                table: "Keepers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "auth_challenges",
                columns: table => new
                {
                    ChallengeId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    ChallengeType = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    SecretHash = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ConsumedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_auth_challenges", x => x.ChallengeId);
                });

            migrationBuilder.CreateTable(
                name: "chat_threads",
                columns: table => new
                {
                    ThreadId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    KeeperId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastMessageAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_chat_threads", x => x.ThreadId);
                    table.ForeignKey(
                        name: "FK_chat_threads_Keepers_KeeperId",
                        column: x => x.KeeperId,
                        principalTable: "Keepers",
                        principalColumn: "KeeperId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_chat_threads_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "keeper_audit_schedules",
                columns: table => new
                {
                    AuditScheduleId = table.Column<Guid>(type: "uuid", nullable: false),
                    KeeperId = table.Column<Guid>(type: "uuid", nullable: false),
                    RequestedByAdminId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuditDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_keeper_audit_schedules", x => x.AuditScheduleId);
                    table.ForeignKey(
                        name: "FK_keeper_audit_schedules_Keepers_KeeperId",
                        column: x => x.KeeperId,
                        principalTable: "Keepers",
                        principalColumn: "KeeperId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_keeper_audit_schedules_admin_accounts_RequestedByAdminId",
                        column: x => x.RequestedByAdminId,
                        principalTable: "admin_accounts",
                        principalColumn: "admin_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "keeper_documents",
                columns: table => new
                {
                    DocumentId = table.Column<Guid>(type: "uuid", nullable: false),
                    KeeperId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    DocumentType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    DocumentReference = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    ReviewNotes = table.Column<string>(type: "text", nullable: true),
                    ReviewedByAdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReviewedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_keeper_documents", x => x.DocumentId);
                    table.ForeignKey(
                        name: "FK_keeper_documents_Keepers_KeeperId",
                        column: x => x.KeeperId,
                        principalTable: "Keepers",
                        principalColumn: "KeeperId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_keeper_documents_admin_accounts_ReviewedByAdminId",
                        column: x => x.ReviewedByAdminId,
                        principalTable: "admin_accounts",
                        principalColumn: "admin_id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "keeper_review_messages",
                columns: table => new
                {
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    KeeperId = table.Column<Guid>(type: "uuid", nullable: false),
                    AdminId = table.Column<Guid>(type: "uuid", nullable: false),
                    MessageType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Message = table.Column<string>(type: "text", nullable: false),
                    IsReadByKeeper = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_keeper_review_messages", x => x.MessageId);
                    table.ForeignKey(
                        name: "FK_keeper_review_messages_Keepers_KeeperId",
                        column: x => x.KeeperId,
                        principalTable: "Keepers",
                        principalColumn: "KeeperId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_keeper_review_messages_admin_accounts_AdminId",
                        column: x => x.AdminId,
                        principalTable: "admin_accounts",
                        principalColumn: "admin_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "notification_delivery_jobs",
                columns: table => new
                {
                    JobId = table.Column<Guid>(type: "uuid", nullable: false),
                    NotificationId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    ScheduledFor = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EnqueuedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    FailedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    FailureReason = table.Column<string>(type: "text", nullable: true),
                    AttemptCount = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notification_delivery_jobs", x => x.JobId);
                    table.ForeignKey(
                        name: "FK_notification_delivery_jobs_Notifications_NotificationId",
                        column: x => x.NotificationId,
                        principalTable: "Notifications",
                        principalColumn: "NotificationId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "shop_loyalty_programs",
                columns: table => new
                {
                    ProgramId = table.Column<Guid>(type: "uuid", nullable: false),
                    ShopId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    ProgramName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    PointsPerRedemption = table.Column<int>(type: "integer", nullable: false),
                    MinimumPointsToRedeem = table.Column<int>(type: "integer", nullable: false),
                    RewardDescription = table.Column<string>(type: "text", nullable: true),
                    TermsAndConditions = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
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

            migrationBuilder.CreateTable(
                name: "chat_messages",
                columns: table => new
                {
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    ThreadId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: true),
                    Message = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_chat_messages", x => x.MessageId);
                    table.ForeignKey(
                        name: "FK_chat_messages_chat_threads_ThreadId",
                        column: x => x.ThreadId,
                        principalTable: "chat_threads",
                        principalColumn: "ThreadId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_auth_challenges_Email_ChallengeType_ConsumedAt",
                table: "auth_challenges",
                columns: new[] { "Email", "ChallengeType", "ConsumedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_auth_challenges_ExpiresAt",
                table: "auth_challenges",
                column: "ExpiresAt");

            migrationBuilder.CreateIndex(
                name: "IX_chat_messages_ThreadId",
                table: "chat_messages",
                column: "ThreadId");

            migrationBuilder.CreateIndex(
                name: "IX_chat_threads_KeeperId",
                table: "chat_threads",
                column: "KeeperId");

            migrationBuilder.CreateIndex(
                name: "IX_chat_threads_UserId_KeeperId",
                table: "chat_threads",
                columns: new[] { "UserId", "KeeperId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_keeper_audit_schedules_KeeperId",
                table: "keeper_audit_schedules",
                column: "KeeperId");

            migrationBuilder.CreateIndex(
                name: "IX_keeper_audit_schedules_RequestedByAdminId",
                table: "keeper_audit_schedules",
                column: "RequestedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_keeper_documents_KeeperId",
                table: "keeper_documents",
                column: "KeeperId");

            migrationBuilder.CreateIndex(
                name: "IX_keeper_documents_ReviewedByAdminId",
                table: "keeper_documents",
                column: "ReviewedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_keeper_review_messages_AdminId",
                table: "keeper_review_messages",
                column: "AdminId");

            migrationBuilder.CreateIndex(
                name: "IX_keeper_review_messages_KeeperId",
                table: "keeper_review_messages",
                column: "KeeperId");

            migrationBuilder.CreateIndex(
                name: "IX_notification_delivery_jobs_NotificationId_Status",
                table: "notification_delivery_jobs",
                columns: new[] { "NotificationId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_notification_delivery_jobs_ScheduledFor",
                table: "notification_delivery_jobs",
                column: "ScheduledFor");

            migrationBuilder.CreateIndex(
                name: "IX_shop_loyalty_programs_ShopId",
                table: "shop_loyalty_programs",
                column: "ShopId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "auth_challenges");

            migrationBuilder.DropTable(
                name: "chat_messages");

            migrationBuilder.DropTable(
                name: "keeper_audit_schedules");

            migrationBuilder.DropTable(
                name: "keeper_documents");

            migrationBuilder.DropTable(
                name: "keeper_review_messages");

            migrationBuilder.DropTable(
                name: "notification_delivery_jobs");

            migrationBuilder.DropTable(
                name: "shop_loyalty_programs");

            migrationBuilder.DropTable(
                name: "chat_threads");

            migrationBuilder.DropColumn(
                name: "Is2FAEnabled",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TotpSecret",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HoldReason",
                table: "Keepers");

            migrationBuilder.DropColumn(
                name: "HoldUntil",
                table: "Keepers");
        }
    }
}
