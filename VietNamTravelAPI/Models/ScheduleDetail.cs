using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VietNamTravelAPI.Models
{
    public class ScheduleDetail
    {
        [Key]
        public int ScheduleDetailId { get; set; }

        [Required]
        public int ScheduleId { get; set; }

        [Required]
        public int LocationId { get; set; }

        public string Note { get; set; } = string.Empty;
        public DateTime? VisitDate { get; set; }

        [ForeignKey("ScheduleId")]
        public Schedule? Schedule { get; set; }

        [ForeignKey("LocationId")]
        public Location? Location { get; set; }
    }
}