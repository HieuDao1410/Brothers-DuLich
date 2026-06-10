namespace VietNamTravelAPI.DTOs
{
    // Dữ liệu Client gửi lên khi viết một đánh giá mới
    public class CreateReviewRequest
    {
        public int LocationId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
    }
}
