using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;
using VietNamTravelAPI.DTOs;
using VietNamTravelAPI.Models;

namespace VietNamTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LocationsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;

        public LocationsController(AppDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // GET: api/Locations
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Location>>> GetLocations()
        {
            // Trả về toàn bộ danh sách địa điểm dưới dạng JSON
            return await _context.Locations.OrderByDescending(l => l.LocationId).ToListAsync();
        }

        // POST: api/Locations/seed
        // Thêm các địa danh mẫu (kèm ảnh) còn THIẾU - chạy được kể cả khi bảng đã có dữ liệu.
        [HttpPost("seed")]
        public async Task<IActionResult> SeedLocations()
        {
            // Ảnh THẬT lưu local trong wwwroot/images (phục vụ qua URL tĩnh /images/...)
            var samples = new List<Location>
            {
                new() { Name = "Vịnh Hạ Long", Province = "Quảng Ninh", Category = "Tham quan", Latitude = 20.9101, Longitude = 107.1839, Rating = 4.8, ImageUrl = "/images/halong.jpg", Description = "Di sản thiên nhiên thế giới với hàng nghìn đảo đá vôi kỳ vĩ." },
                new() { Name = "Phố cổ Hội An", Province = "Quảng Nam", Category = "Tham quan", Latitude = 15.8801, Longitude = 108.3380, Rating = 4.7, ImageUrl = "/images/hoian.jpg", Description = "Phố cổ rực rỡ đèn lồng, di sản văn hóa thế giới." },
                new() { Name = "Bà Nà Hills", Province = "Đà Nẵng", Category = "Tham quan", Latitude = 15.9977, Longitude = 107.9960, Rating = 4.6, ImageUrl = "/images/bana.jpg", Description = "Khu nghỉ dưỡng trên núi với Cầu Vàng nổi tiếng." },
                new() { Name = "Hồ Hoàn Kiếm", Province = "Hà Nội", Category = "Tham quan", Latitude = 21.0285, Longitude = 105.8524, Rating = 4.5, ImageUrl = "/images/hoankiem.jpg", Description = "Trái tim của thủ đô Hà Nội với Tháp Rùa cổ kính." },
                new() { Name = "Chợ Bến Thành", Province = "TP. Hồ Chí Minh", Category = "Ăn uống", Latitude = 10.7720, Longitude = 106.6980, Rating = 4.3, ImageUrl = "/images/benthanh.jpg", Description = "Khu chợ sầm uất, thiên đường ẩm thực và mua sắm." },
                new() { Name = "Phong Nha - Kẻ Bàng", Province = "Quảng Bình", Category = "Tham quan", Latitude = 17.5870, Longitude = 106.2870, Rating = 4.9, ImageUrl = "/images/phongnha.jpg", Description = "Hệ thống hang động kỳ vĩ bậc nhất thế giới." },
                new() { Name = "Vinpearl Nha Trang", Province = "Khánh Hòa", Category = "Khách sạn", Latitude = 12.2173, Longitude = 109.2540, Rating = 4.6, ImageUrl = "/images/nhatrang.png", Description = "Thành phố biển Nha Trang xinh đẹp với bãi biển và đảo nổi tiếng." },
                new() { Name = "Chùa Một Cột", Province = "Hà Nội", Category = "Tham quan", Latitude = 21.0359, Longitude = 105.8337, Rating = 4.4, ImageUrl = "/images/motcot.jpg", Description = "Ngôi chùa biểu tượng kiến trúc độc đáo của Việt Nam." },
            };

            var existing = await _context.Locations.ToListAsync();
            int added = 0, updated = 0;
            foreach (var s in samples)
            {
                var match = existing.FirstOrDefault(l => l.Name == s.Name);
                if (match == null)
                {
                    _context.Locations.Add(s);
                    added++;
                }
                else
                {
                    // Cập nhật ảnh thật cho địa danh đã tồn tại (sửa ảnh cũ/ngẫu nhiên)
                    match.ImageUrl = s.ImageUrl;
                    if (string.IsNullOrWhiteSpace(match.Description)) match.Description = s.Description;
                    updated++;
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new
            {
                message = $"Đã thêm {added} địa danh, cập nhật ảnh thật cho {updated} địa danh.",
                added,
                updated
            });
        }

        // GET: api/Locations/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetLocation(int id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location == null)
            {
                return NotFound(new { message = "Không tìm thấy địa danh." });
            }
            return Ok(location);
        }

        // POST: api/Locations  (multipart/form-data, có thể kèm ảnh)
        [HttpPost]
        public async Task<IActionResult> PostLocation([FromForm] LocationUpsertRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Name))
            {
                return BadRequest(new { message = "Tên địa danh không được để trống." });
            }

            var location = new Location
            {
                Name = req.Name,
                Category = req.Category ?? string.Empty,
                Province = req.Province ?? string.Empty,
                Description = req.Description ?? string.Empty,
                Latitude = ParseCoord(req.Latitude),
                Longitude = ParseCoord(req.Longitude),
                ImageUrl = string.Empty
            };

            // Lưu ảnh (nếu có) vào thư mục tĩnh wwwroot/images
            if (req.Image != null && req.Image.Length > 0)
            {
                location.ImageUrl = await SaveImageAsync(req.Image);
            }

            _context.Locations.Add(location);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetLocation), new { id = location.LocationId }, location);
        }

        // PUT: api/Locations/5  (multipart/form-data, ảnh tùy chọn)
        [HttpPut("{id}")]
        public async Task<IActionResult> PutLocation(int id, [FromForm] LocationUpsertRequest req)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location == null)
            {
                return NotFound(new { message = "Không tìm thấy địa danh." });
            }

            location.Name = req.Name;
            location.Category = req.Category ?? string.Empty;
            location.Province = req.Province ?? string.Empty;
            location.Description = req.Description ?? string.Empty;
            location.Latitude = ParseCoord(req.Latitude);
            location.Longitude = ParseCoord(req.Longitude);

            // Chỉ thay ảnh khi người dùng chọn ảnh mới
            if (req.Image != null && req.Image.Length > 0)
            {
                DeleteImageIfLocal(location.ImageUrl);
                location.ImageUrl = await SaveImageAsync(req.Image);
            }

            await _context.SaveChangesAsync();
            return Ok(location);
        }

        // DELETE: api/Locations/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteLocation(int id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location == null)
            {
                return NotFound(new { message = "Không tìm thấy địa danh." });
            }

            DeleteImageIfLocal(location.ImageUrl);
            _context.Locations.Remove(location);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa địa danh." });
        }

        // Parse tọa độ an toàn theo InvariantCulture (chấp nhận "20.9101")
        private static double ParseCoord(string? value)
        {
            if (string.IsNullOrWhiteSpace(value)) return 0;
            return double.TryParse(value, System.Globalization.NumberStyles.Any,
                System.Globalization.CultureInfo.InvariantCulture, out var result)
                ? result
                : 0;
        }

        // ===== Hàm hỗ trợ xử lý tệp ảnh tĩnh =====

        // Lưu ảnh vào wwwroot/images và trả về đường dẫn tương đối "/images/xxx.jpg"
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

        // Xóa file ảnh cũ trên ổ đĩa (chỉ với ảnh nội bộ dạng /images/...)
        private void DeleteImageIfLocal(string? imageUrl)
        {
            if (string.IsNullOrWhiteSpace(imageUrl)) return;
            if (!imageUrl.StartsWith("/images/")) return;

            var webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            var fullPath = Path.Combine(webRoot, imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
            if (System.IO.File.Exists(fullPath))
            {
                try { System.IO.File.Delete(fullPath); } catch { /* bỏ qua lỗi xóa file */ }
            }
        }
    }
}
