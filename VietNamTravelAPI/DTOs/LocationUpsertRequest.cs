using Microsoft.AspNetCore.Http;

namespace VietNamTravelAPI.DTOs
{
    // Dữ liệu Client gửi lên (multipart/form-data) khi Thêm hoặc Sửa địa danh.
    // Image là tệp ảnh tùy chọn; nếu không gửi thì giữ nguyên ảnh cũ (khi sửa).
    public class LocationUpsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Province { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        // Nhận dạng chuỗi rồi tự parse theo InvariantCulture để tránh lỗi
        // dấu phẩy thập phân trên máy có culture vi-VN/de-DE.
        public string? Latitude { get; set; }
        public string? Longitude { get; set; }

        public IFormFile? Image { get; set; }
    }
}
