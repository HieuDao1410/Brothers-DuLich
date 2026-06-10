using System.ComponentModel.DataAnnotations;

namespace VietNamTravelAPI.Models
{
    // Bình luận dưới một bài đăng
    public class Comment
    {
        [Key]
        public int CommentId { get; set; }

        public int PostId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
