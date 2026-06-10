using Microsoft.AspNetCore.Http;

namespace VietNamTravelAPI.DTOs
{
    // Tạo bài đăng mới (multipart/form-data, có thể kèm ảnh)
    public class CreatePostRequest
    {
        public string UserId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? LocationId { get; set; } // chuỗi để parse an toàn, null nếu không check-in
        public IFormFile? Image { get; set; }
    }

    // Thêm bình luận
    public class CreateCommentRequest
    {
        public string UserId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }

    // Bật/tắt thích
    public class LikeRequest
    {
        public string UserId { get; set; } = string.Empty;
    }
}
