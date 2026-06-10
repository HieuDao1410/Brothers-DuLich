using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VietNamTravelAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddSchedules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Dùng CREATE TABLE IF NOT EXISTS để an toàn với DB hiện tại lẫn DB mới.
            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS `Schedules` (
                    `ScheduleId` int NOT NULL AUTO_INCREMENT,
                    `UserId` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `Title` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `StartDate` datetime(6) NULL,
                    `EndDate` datetime(6) NULL,
                    CONSTRAINT `PK_Schedules` PRIMARY KEY (`ScheduleId`)
                ) CHARACTER SET=utf8mb4;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Schedules");
        }
    }
}
