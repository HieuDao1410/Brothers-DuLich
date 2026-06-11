using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;
using VietNamTravelAPI.DTOs;
using VietNamTravelAPI.Models;

namespace VietNamTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ReviewsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Reviews/location/5
        // Lấy danh sách đánh giá của 1 địa danh (kèm tên người đánh giá)
        [HttpGet("location/{locationId}")]
        public async Task<IActionResult> GetReviewsByLocation(int locationId)
        {
            var reviews = await (from r in _context.Reviews
                                 where r.LocationId == locationId
                                 join u in _context.Users on r.UserId equals u.UserId into gj
                                 from u in gj.DefaultIfEmpty()
                                 orderby r.CreatedAt descending
                                 select new
                                 {
                                     reviewId = r.ReviewId,
                                     locationId = r.LocationId,
                                     userId = r.UserId,
                                     userName = u != null ? u.FullName : "Người dùng ẩn danh",
                                     userAvatar = "",
                                     rating = r.Rating,
                                     comment = r.Comment,
                                     createdAt = r.CreatedAt
                                 }).ToListAsync();

            return Ok(reviews);
        }

        // GET: api/Reviews/user/{userId}
        // Lấy toàn bộ đánh giá do 1 người dùng viết (dùng cho "Đánh giá của tôi")
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetReviewsByUser(string userId)
        {
            var reviews = await (from r in _context.Reviews
                                 where r.UserId == userId
                                 join l in _context.Locations on r.LocationId equals l.LocationId into lj
                                 from l in lj.DefaultIfEmpty()
                                 orderby r.CreatedAt descending
                                 select new
                                 {
                                     reviewId = r.ReviewId,
                                     locationId = r.LocationId,
                                     locationName = l != null ? l.Name : "Địa danh",
                                     userId = r.UserId,
                                     rating = r.Rating,
                                     comment = r.Comment,
                                     createdAt = r.CreatedAt
                                 }).ToListAsync();

            return Ok(reviews);
        }

        // GET: api/Reviews
        // Toàn bộ đánh giá trong hệ thống (dùng cho màn Kiểm duyệt của Admin)
        [HttpGet]
        public async Task<IActionResult> GetAllReviews()
        {
            var reviews = await (from r in _context.Reviews
                                 join u in _context.Users on r.UserId equals u.UserId into uj
                                 from u in uj.DefaultIfEmpty()
                                 join l in _context.Locations on r.LocationId equals l.LocationId into lj
                                 from l in lj.DefaultIfEmpty()
                                 orderby r.CreatedAt descending
                                 select new
                                 {
                                     reviewId = r.ReviewId,
                                     locationId = r.LocationId,
                                     locationName = l != null ? l.Name : "Địa danh",
                                     userId = r.UserId,
                                     userName = u != null ? u.FullName : "Người dùng ẩn danh",
                                     userAvatar = "",
                                     rating = r.Rating,
                                     comment = r.Comment,
                                     createdAt = r.CreatedAt
                                 }).ToListAsync();

            return Ok(reviews);
        }

        // POST: api/Reviews
        // Viết một đánh giá mới và cập nhật lại điểm trung bình của địa danh
        [HttpPost]
        public async Task<IActionResult> PostReview([FromBody] CreateReviewRequest request)
        {
            if (request.Rating < 1 || request.Rating > 5)
            {
                return BadRequest(new { message = "Số sao phải nằm trong khoảng 1 đến 5." });
            }

            var review = new Review
            {
                LocationId = request.LocationId,
                UserId = request.UserId,
                Rating = request.Rating,
                Comment = request.Comment ?? string.Empty,
                CreatedAt = DateTime.Now
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            // Tính lại điểm trung bình rồi lưu vào bảng Locations
            await UpdateLocationRating(request.LocationId);

            return Ok(new { message = "Đã gửi đánh giá thành công!", reviewId = review.ReviewId });
        }

        // DELETE: api/Reviews/5
        // Admin gỡ bỏ một đánh giá vi phạm
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReview(int id)
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null)
            {
                return NotFound(new { message = "Không tìm thấy đánh giá này." });
            }

            int locationId = review.LocationId;
            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();

            // Cập nhật lại điểm trung bình sau khi xóa
            await UpdateLocationRating(locationId);

            return Ok(new { message = "Đã gỡ bỏ đánh giá." });
        }

        // Hàm nội bộ: tính trung bình số sao của 1 địa danh và ghi vào Location.Rating
        private async Task UpdateLocationRating(int locationId)
        {
            var location = await _context.Locations.FindAsync(locationId);
            if (location == null) return;

            var ratings = await _context.Reviews
                                        .Where(r => r.LocationId == locationId)
                                        .Select(r => r.Rating)
                                        .ToListAsync();

            location.Rating = ratings.Any() ? Math.Round(ratings.Average(), 1) : 0;
            await _context.SaveChangesAsync();
        }

    }
}
