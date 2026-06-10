using System.ComponentModel.DataAnnotations;

namespace VietNamTravelAPI.Models
{
    public class Location
    {
        [Key]
        public int LocationId { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        public string Category { get; set; } = string.Empty;
        public string Province { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;

        // Dùng double cho tọa độ GPS trong C# (tương ứng DECIMAL trong DB)
        public double Latitude { get; set; }
        public double Longitude { get; set; }

        // Trường mở rộng để hứng điểm đánh giá trung bình
        public double Rating { get; set; } = 5.0;
    }
}