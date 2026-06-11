using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Models;

namespace VietNamTravelAPI.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Location> Locations { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Schedule> Schedules { get; set; }
        public DbSet<Post> Posts { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<PostLike> PostLikes { get; set; }
        public DbSet<FavoriteLocation> FavoriteLocations { get; set; }
        public DbSet<ScheduleDetail> ScheduleDetails { get; set; }
    }
}