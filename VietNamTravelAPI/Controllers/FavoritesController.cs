using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;
using VietNamTravelAPI.DTOs;
using VietNamTravelAPI.Models;

namespace VietNamTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavoritesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public FavoritesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Favorites/{userId}
        [HttpGet("{userId}")]
        public async Task<ActionResult<IEnumerable<Location>>> GetUserFavorites(string userId)
        {
            var favoriteLocations = await _context.FavoriteLocations
                .Where(f => f.UserId == userId)
                .Include(f => f.Location) // Kéo theo thông tin địa danh
                .Select(f => f.Location)
                .ToListAsync();

            return Ok(favoriteLocations);
        }

        // POST: api/Favorites/toggle
        [HttpPost("toggle")]
        public async Task<ActionResult> ToggleFavorite([FromBody] ToggleFavoriteRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.UserId))
            {
                return BadRequest(new { message = "Thiếu UserId." });
            }

            // 1. Tự tạo user nếu chưa có trong MySQL (tài khoản "mồ côi" do đồng bộ lúc đăng ký
            //    bị lỗi) -> tránh lỗi khóa ngoại FK_FavoriteLocations_Users_UserId
            bool userExists = await _context.Users.AnyAsync(u => u.UserId == request.UserId);
            if (!userExists)
            {
                _context.Users.Add(new User
                {
                    UserId = request.UserId,
                    Email = string.Empty,
                    FullName = "Khách du lịch",
                    Role = "User",
                    IsBanned = false,
                    CreatedAt = DateTime.Now
                });
                await _context.SaveChangesAsync();
            }

            // 2. Tìm địa danh trong CSDL: ưu tiên theo Id hợp lệ, nếu không có thì theo Tên
            Location? location = null;
            if (request.LocationId > 0)
            {
                location = await _context.Locations.FirstOrDefaultAsync(l => l.LocationId == request.LocationId);
            }
            if (location == null && !string.IsNullOrWhiteSpace(request.Name))
            {
                location = await _context.Locations.FirstOrDefaultAsync(l => l.Name == request.Name);
            }

            // 3. Nếu là địa điểm ngoài (Lân cận/OSM) chưa có trong CSDL -> tự thêm vào để lưu được
            if (location == null)
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest(new { message = "Thiếu thông tin địa danh." });
                }
                location = new Location
                {
                    Name = request.Name,
                    Province = request.Province ?? string.Empty,
                    Description = request.Description ?? string.Empty,
                    ImageUrl = request.ImageUrl ?? string.Empty,
                    Rating = request.Rating,
                    Category = string.IsNullOrWhiteSpace(request.Category) ? "Địa danh" : request.Category,
                    Latitude = request.Latitude,
                    Longitude = request.Longitude
                };
                _context.Locations.Add(location);
                await _context.SaveChangesAsync(); // sinh LocationId mới
            }

            // 4. Bật/tắt yêu thích theo LocationId thật trong CSDL
            var existingFavorite = await _context.FavoriteLocations
                .FirstOrDefaultAsync(f => f.UserId == request.UserId && f.LocationId == location.LocationId);

            if (existingFavorite != null)
            {
                _context.FavoriteLocations.Remove(existingFavorite);
                await _context.SaveChangesAsync();
                return Ok(new { isFavorite = false, locationId = location.LocationId, message = "Đã bỏ yêu thích" });
            }

            _context.FavoriteLocations.Add(new FavoriteLocation { UserId = request.UserId, LocationId = location.LocationId });
            await _context.SaveChangesAsync();
            return Ok(new { isFavorite = true, locationId = location.LocationId, message = "Đã thêm vào yêu thích" });
        }
    }
}