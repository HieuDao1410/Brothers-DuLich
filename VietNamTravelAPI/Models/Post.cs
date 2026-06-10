using System.ComponentModel.DataAnnotations;

namespace VietNamTravelAPI.Models
{
    // Bài đăng mạng xã hội du lịch
    public class Post
    {
        [Key]
        public int PostId { get; set; }

        // FK tới Users (UID Firebase)
        [Required]
        public string UserId { get; set; } = string.Empty;

        // FK tới Locations (địa danh check-in) - có thể null
        public int? LocationId { get; set; }

        public string Content { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public int LikesCount { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
