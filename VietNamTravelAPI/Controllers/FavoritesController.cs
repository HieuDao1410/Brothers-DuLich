using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;
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
        public async Task<ActionResult> ToggleFavorite([FromBody] FavoriteLocation request)
        {
            var existingFavorite = await _context.FavoriteLocations
                .FirstOrDefaultAsync(f => f.UserId == request.UserId && f.LocationId == request.LocationId);

            if (existingFavorite != null)
            {
                // Nếu đã thích thì bỏ thích
                _context.FavoriteLocations.Remove(existingFavorite);
                await _context.SaveChangesAsync();
                return Ok(new { isFavorite = false, message = "Đã bỏ yêu thích" });
            }

            // Nếu chưa thích thì thêm vào
            _context.FavoriteLocations.Add(new FavoriteLocation { UserId = request.UserId, LocationId = request.LocationId });
            await _context.SaveChangesAsync();
            return Ok(new { isFavorite = true, message = "Đã thêm vào yêu thích" });
        }
    }
}