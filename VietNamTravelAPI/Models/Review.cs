using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VietNamTravelAPI.Models
{
    public class Review
    {
        [Key]
        public int ReviewId { get; set; }

        // FK tới bảng Locations
        public int LocationId { get; set; }

        // FK tới bảng Users (UID Firebase dạng chuỗi)
        [Required]
        public string UserId { get; set; } = string.Empty;

        // Số sao đánh giá (1 -> 5)
        public int Rating { get; set; }

        public string Comment { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
