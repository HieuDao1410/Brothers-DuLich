using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;
using VietNamTravelAPI.DTOs;    
using VietNamTravelAPI.Models;
namespace VietNamTravelAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("sync")]
        public async Task<IActionResult> SyncUser([FromBody] SyncUserRequest request)
        {
            // Kiểm tra xem User này đã tồn tại trong MySQL chưa
            var existingUser = await _context.Users.FindAsync(request.UserId);

            if (existingUser == null)
            {
                // 1. Tạo biến newUser (viết thường chữ n)
                var newUser = new User
                {
                    UserId = request.UserId,
                    Email = request.Email,
                    FullName = request.FullName ?? "Khách du lịch",
                    Role = "User",
                    IsBanned = false,         // Đảm bảo trong file User.cs đã có thuộc tính này
                    CreatedAt = DateTime.Now   // Đảm bảo trong file User.cs đã có thuộc tính này
                };

                // 2. SỬA TẠI ĐÂY: Truyền đúng biến 'newUser' vào hàm Add chứ không truyền Class 'User'
                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã đồng bộ user mới thành công!" });
            }

            // Nếu đã có (Đăng nhập lại) -> Không làm gì cả
            return Ok(new { message = "User đã tồn tại, tiến hành đăng nhập." });
        }
        [HttpGet]
        public async Task<IActionResult> GetAllUsers()
        {
            // Lấy tất cả user, sắp xếp người mới đăng ký lên đầu
            var users = await _context.Users
                                      .OrderByDescending(u => u.CreatedAt)
                                      .ToListAsync();
            return Ok(users);
        }
        [HttpPut("{id}/toggle-ban")]
        public async Task<IActionResult> ToggleBanUser(string id)
        {
            // Tìm user theo ID (UID của Firebase)
            var user = await _context.Users.FindAsync(id);

            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng này." });
            }

            // Đảo ngược trạng thái hiện tại (Nếu đang khóa thì mở, đang mở thì khóa)
            user.IsBanned = !user.IsBanned;

            await _context.SaveChangesAsync();

            var status = user.IsBanned ? "đã bị khóa" : "đã được mở khóa";
            return Ok(new { message = $"Tài khoản {user.Email} {status}." });
        }
        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng." });
            }
            return Ok(user);
        }

        // PUT: api/Users/{id}/profile  - cập nhật họ tên hồ sơ cá nhân
        [HttpPut("{id}/profile")]
        public async Task<IActionResult> UpdateProfile(string id, [FromBody] UpdateProfileRequest req)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng." });
            }

            if (!string.IsNullOrWhiteSpace(req.FullName))
            {
                user.FullName = req.FullName;
            }

            await _context.SaveChangesAsync();
            return Ok(user);
        }
    }
}
