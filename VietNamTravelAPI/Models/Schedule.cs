using System.ComponentModel.DataAnnotations;

namespace VietNamTravelAPI.Models
{
    // Lịch trình chuyến đi - đồng bộ từ SQLite cục bộ của thiết bị lên Server
    public class Schedule
    {
        [Key]
        public int ScheduleId { get; set; }

        // FK tới bảng Users (UID Firebase)
        [Required]
        public string UserId { get; set; } = string.Empty;

        public string Title { get; set; } = string.Empty;

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}
