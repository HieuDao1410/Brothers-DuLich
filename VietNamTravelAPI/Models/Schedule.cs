using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VietNamTravelAPI.Models
{
    public class Schedule
    {
        [Key]
        public int ScheduleId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        // Bổ sung danh sách chi tiết địa danh
        public ICollection<ScheduleDetail>? ScheduleDetails { get; set; }
    }
}