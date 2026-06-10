namespace VietNamTravelAPI.DTOs
{
    // Dữ liệu Client (SQLite cục bộ) gửi lên khi đồng bộ lịch trình
    public class CreateScheduleRequest
    {
        public string UserId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;

        // Ngày dạng chuỗi ISO "yyyy-MM-dd" để parse theo InvariantCulture
        public string? StartDate { get; set; }
        public string? EndDate { get; set; }
    }
}
