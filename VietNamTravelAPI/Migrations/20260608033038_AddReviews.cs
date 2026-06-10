using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VietNamTravelAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddReviews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Dùng CREATE TABLE IF NOT EXISTS để an toàn: bảng "Reviews" có thể đã
            // tồn tại sẵn trong DB hiện tại; với DB mới thì lệnh này sẽ tạo bảng.
            // (Bảng "Users" đã được tạo thủ công từ trước nên không xử lý ở đây.)
            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS `Reviews` (
                    `ReviewId` int NOT NULL AUTO_INCREMENT,
                    `LocationId` int NOT NULL,
                    `UserId` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `Rating` int NOT NULL,
                    `Comment` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `CreatedAt` datetime(6) NOT NULL,
                    CONSTRAINT `PK_Reviews` PRIMARY KEY (`ReviewId`)
                ) CHARACTER SET=utf8mb4;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Reviews");
        }
    }
}
