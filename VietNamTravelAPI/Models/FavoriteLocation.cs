using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VietNamTravelAPI.Models
{
    public class FavoriteLocation
    {
        [Key]
        public int FavoriteId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        public int LocationId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [ForeignKey("LocationId")]
        public Location? Location { get; set; }
    }
}