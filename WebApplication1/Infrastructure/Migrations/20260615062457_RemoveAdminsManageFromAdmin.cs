using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace routent.AdminAPI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveAdminsManageFromAdmin : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("UPDATE admin_accounts SET \"Permissions\" = array_remove(\"Permissions\", 'Admins.Manage') WHERE role = 'admin';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
