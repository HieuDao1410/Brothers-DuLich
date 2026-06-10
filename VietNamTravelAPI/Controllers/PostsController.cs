using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;
using VietNamTravelAPI.DTOs;
using VietNamTravelAPI.Models;

namespace VietNamTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PostsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;

        public PostsController(AppDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // GET: api/Posts?userId={uid}
        // News Feed: danh sách bài đăng kèm tên tác giả, địa danh check-in, số like/comment, đã like chưa
        [HttpGet]
        public async Task<IActionResult> GetFeed([FromQuery] string? userId)
        {
            var likedIds = string.IsNullOrEmpty(userId)
                ? new List<int>()
                : await _context.PostLikes.Where(l => l.UserId == userId).Select(l => l.PostId).ToListAsync();

            var raw = await (from p in _context.Posts
                             orderby p.CreatedAt descending
                             select new
                             {
                                 p.PostId,
                                 p.UserId,
                                 p.LocationId,
                                 p.Content,
                                 p.ImageUrl,
                                 p.LikesCount,
                                 p.CreatedAt,
                                 UserName = _context.Users.Where(u => u.UserId == p.UserId).Select(u => u.FullName).FirstOrDefault(),
                                 LocationName = p.LocationId == null
                                     ? null
                                     : _context.Locations.Where(l => l.LocationId == p.LocationId).Select(l => l.Name).FirstOrDefault(),
                                 CommentsCount = _context.Comments.Count(c => c.PostId == p.PostId)
                             }).ToListAsync();

            var result = raw.Select(x => new
            {
                postId = x.PostId,
                userId = x.UserId,
                userName = x.UserName ?? "Người dùng",
                userAvatar = "",
                locationId = x.LocationId,
                locationName = x.LocationName,
                content = x.Content,
                imageUrl = x.ImageUrl,
                likesCount = x.LikesCount,
                commentsCount = x.CommentsCount,
                createdAt = x.CreatedAt,
                isLiked = likedIds.Contains(x.PostId)
            });

            return Ok(result);
        }

        // POST: api/Posts  (multipart/form-data)
        [HttpPost]
        public async Task<IActionResult> CreatePost([FromForm] CreatePostRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.UserId))
            {
                return BadRequest(new { message = "Thiếu UserId." });
            }
            if (string.IsNullOrWhiteSpace(req.Content) && (req.Image == null || req.Image.Length == 0))
            {
                return BadRequest(new { message = "Bài đăng phải có nội dung hoặc hình ảnh." });
            }

            int? locationId = null;
            if (!string.IsNullOrWhiteSpace(req.LocationId) && int.TryParse(req.LocationId, out var lid))
            {
                locationId = lid;
            }

            var post = new Post
            {
                UserId = req.UserId,
                Content = req.Content ?? string.Empty,
                LocationId = locationId,
                LikesCount = 0,
                CreatedAt = DateTime.Now,
                ImageUrl = string.Empty
            };

            if (req.Image != null && req.Image.Length > 0)
            {
                post.ImageUrl = await SaveImageAsync(req.Image);
            }

            _context.Posts.Add(post);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã đăng bài thành công!", postId = post.PostId });
        }

        // POST: api/Posts/5/like  (body: { userId })
        [HttpPost("{id}/like")]
        public async Task<IActionResult> ToggleLike(int id, [FromBody] LikeRequest req)
        {
            var post = await _context.Posts.FindAsync(id);
            if (post == null) return NotFound(new { message = "Không tìm thấy bài đăng." });

            var existing = await _context.PostLikes
                .FirstOrDefaultAsync(l => l.PostId == id && l.UserId == req.UserId);

            bool liked;
            if (existing != null)
            {
                _context.PostLikes.Remove(existing);
                post.LikesCount = Math.Max(0, post.LikesCount - 1);
                liked = false;
            }
            else
            {
                _context.PostLikes.Add(new PostLike { PostId = id, UserId = req.UserId });
                post.LikesCount += 1;
                liked = true;
            }

            await _context.SaveChangesAsync();
            return Ok(new { likesCount = post.LikesCount, isLiked = liked });
        }

        // GET: api/Posts/5/comments
        [HttpGet("{id}/comments")]
        public async Task<IActionResult> GetComments(int id)
        {
            var comments = await (from c in _context.Comments
                                  where c.PostId == id
                                  orderby c.CreatedAt ascending
                                  select new
                                  {
                                      commentId = c.CommentId,
                                      postId = c.PostId,
                                      userId = c.UserId,
                                      userName = _context.Users.Where(u => u.UserId == c.UserId).Select(u => u.FullName).FirstOrDefault() ?? "Người dùng",
                                      content = c.Content,
                                      createdAt = c.CreatedAt
                                  }).ToListAsync();
            return Ok(comments);
        }

        // POST: api/Posts/5/comments
        [HttpPost("{id}/comments")]
        public async Task<IActionResult> AddComment(int id, [FromBody] CreateCommentRequest req)
        {
            var post = await _context.Posts.FindAsync(id);
            if (post == null) return NotFound(new { message = "Không tìm thấy bài đăng." });
            if (string.IsNullOrWhiteSpace(req.Content)) return BadRequest(new { message = "Nội dung trống." });

            var comment = new Comment
            {
                PostId = id,
                UserId = req.UserId,
                Content = req.Content,
                CreatedAt = DateTime.Now
            };
            _context.Comments.Add(comment);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã bình luận.", commentId = comment.CommentId });
        }

        // DELETE: api/Posts/5  (chủ bài hoặc Admin gỡ bài)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePost(int id)
        {
            var post = await _context.Posts.FindAsync(id);
            if (post == null) return NotFound(new { message = "Không tìm thấy bài đăng." });

            // Dọn dữ liệu liên quan
            var comments = _context.Comments.Where(c => c.PostId == id);
            var likes = _context.PostLikes.Where(l => l.PostId == id);
            _context.Comments.RemoveRange(comments);
            _context.PostLikes.RemoveRange(likes);

            DeleteImageIfLocal(post.ImageUrl);
            _context.Posts.Remove(post);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã gỡ bài đăng." });
        }

        // ===== Helpers ảnh tĩnh =====
        private async Task<string> SaveImageAsync(IFormFile image)
        {
            var webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            var imagesDir = Path.Combine(webRoot, "images");
            Directory.CreateDirectory(imagesDir);

            var ext = Path.GetExtension(image.FileName);
            var fileName = $"{Guid.NewGuid():N}{ext}";
            var fullPath = Path.Combine(imagesDir, fileName);
            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await image.CopyToAsync(stream);
            }
            return $"/images/{fileName}";
        }

        private void DeleteImageIfLocal(string? imageUrl)
        {
            if (string.IsNullOrWhiteSpace(imageUrl) || !imageUrl.StartsWith("/images/")) return;
            var webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            var fullPath = Path.Combine(webRoot, imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
            if (System.IO.File.Exists(fullPath))
            {
                try { System.IO.File.Delete(fullPath); } catch { }
            }
        }
    }
}
