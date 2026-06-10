using System.ComponentModel.DataAnnotations;

namespace VietNamTravelAPI.Models
{
    // Lưu lượt thích của từng người dùng cho từng bài (để bật/tắt Like)
    public class PostLike
    {
        [Key]
        public int PostLikeId { get; set; }

        public int PostId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;
    }
}
