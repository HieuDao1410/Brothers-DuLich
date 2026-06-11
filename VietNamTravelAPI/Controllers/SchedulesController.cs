using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using VietNamTravelAPI.Data;
using VietNamTravelAPI.DTOs;
using VietNamTravelAPI.Models;

namespace VietNamTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SchedulesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SchedulesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Schedules/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUser(string userId)
        {
            var schedules = await _context.Schedules
                .Where(s => s.UserId == userId)
                .OrderByDescending(s => s.ScheduleId)
                .ToListAsync();
            return Ok(schedules);
        }

        // POST: api/Schedules  (đồng bộ 1 lịch trình từ SQLite cục bộ lên Server)
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateScheduleRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.UserId))
            {
                return BadRequest(new { message = "Thiếu UserId." });
            }

            var schedule = new Schedule
            {
                UserId = req.UserId,
                Title = req.Title ?? string.Empty,
                // Sử dụng toán tử ?? để gán giá trị mặc định nếu ParseDate trả về null
                StartDate = ParseDate(req.StartDate) ?? DateTime.Now,
                EndDate = ParseDate(req.EndDate) ?? DateTime.Now.AddDays(1)
            };

            _context.Schedules.Add(schedule);
            await _context.SaveChangesAsync();

            // Trả về kèm ScheduleId để Client lưu lại làm khóa đồng bộ
            return Ok(schedule);
        }

        // PUT: api/Schedules/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] CreateScheduleRequest req)
        {
            var schedule = await _context.Schedules.FindAsync(id);
            if (schedule == null)
            {
                return NotFound(new { message = "Không tìm thấy lịch trình." });
            }

            schedule.Title = req.Title ?? string.Empty;
            // Sử dụng toán tử ?? để gán giá trị mặc định nếu ParseDate trả về null
            schedule.StartDate = ParseDate(req.StartDate) ?? DateTime.Now;
            schedule.EndDate = ParseDate(req.EndDate) ?? DateTime.Now.AddDays(1);

            await _context.SaveChangesAsync();
            return Ok(schedule);
        }

        // DELETE: api/Schedules/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var schedule = await _context.Schedules.FindAsync(id);
            if (schedule == null)
            {
                return NotFound(new { message = "Không tìm thấy lịch trình." });
            }

            _context.Schedules.Remove(schedule);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xóa lịch trình." });
        }

        private static DateTime? ParseDate(string? value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            if (DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dt))
            {
                return dt;
            }
            return null;
        }
    }
}