using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VietNamTravelAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddCommunity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Dùng CREATE TABLE IF NOT EXISTS để an toàn với DB hiện tại lẫn DB mới.
            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS `Posts` (
                    `PostId` int NOT NULL AUTO_INCREMENT,
                    `UserId` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `LocationId` int NULL,
                    `Content` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `ImageUrl` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `LikesCount` int NOT NULL,
                    `CreatedAt` datetime(6) NOT NULL,
                    CONSTRAINT `PK_Posts` PRIMARY KEY (`PostId`)
                ) CHARACTER SET=utf8mb4;
            ");

            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS `Comments` (
                    `CommentId` int NOT NULL AUTO_INCREMENT,
                    `PostId` int NOT NULL,
                    `UserId` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `Content` longtext CHARACTER SET utf8mb4 NOT NULL,
                    `CreatedAt` datetime(6) NOT NULL,
                    CONSTRAINT `PK_Comments` PRIMARY KEY (`CommentId`)
                ) CHARACTER SET=utf8mb4;
            ");

            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS `PostLikes` (
                    `PostLikeId` int NOT NULL AUTO_INCREMENT,
                    `PostId` int NOT NULL,
                    `UserId` longtext CHARACTER SET utf8mb4 NOT NULL,
                    CONSTRAINT `PK_PostLikes` PRIMARY KEY (`PostLikeId`)
                ) CHARACTER SET=utf8mb4;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Comments");

            migrationBuilder.DropTable(
                name: "PostLikes");

            migrationBuilder.DropTable(
                name: "Posts");
        }
    }
}
