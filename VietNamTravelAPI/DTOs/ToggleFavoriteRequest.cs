namespace VietNamTravelAPI.DTOs
{
    // Dữ liệu gửi lên khi thả tim: kèm đủ thông tin địa danh để server có thể
    // tự thêm vào CSDL nếu đó là địa điểm ngoài (tab Lân cận/OpenStreetMap).
    public class ToggleFavoriteRequest
    {
        public string UserId { get; set; } = string.Empty;
        public int LocationId { get; set; }
        public string? Name { get; set; }
        public string? Province { get; set; }
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public double Rating { get; set; }
        public string? Category { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
