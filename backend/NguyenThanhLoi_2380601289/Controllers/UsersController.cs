using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Controllers
{
    // Chi Admin duoc xem danh sach tai khoan va khoa / mo khoa.
    // Khong co API nang ai len Admin.
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class UsersController : ControllerBase
    {
        private readonly UserManager<User> _userManager;

        public UsersController(UserManager<User> userManager)
        {
            _userManager = userManager;
        }

        // GET: api/Users
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _userManager.Users.OrderBy(u => u.UserName).ToListAsync();
            var result = new List<object>();
            foreach (var u in users)
            {
                var roles = await _userManager.GetRolesAsync(u);
                result.Add(new
                {
                    id = u.Id,
                    username = u.UserName,
                    email = u.Email,
                    phoneNumber = u.PhoneNumber,
                    role = roles.Contains("Admin") ? "Admin" : "User",
                    isLocked = await _userManager.IsLockedOutAsync(u)
                });
            }
            return Ok(result);
        }

        // POST: api/Users/{id}/lock — khoa vinh vien
        [HttpPost("{id}/lock")]
        public async Task<IActionResult> Lock(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });
            if (await _userManager.IsInRoleAsync(user, "Admin"))
                return BadRequest(new { message = "Không thể khóa tài khoản Admin" });

            await _userManager.SetLockoutEnabledAsync(user, true);
            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);
            return Ok(new { message = "Đã khóa tài khoản" });
        }

        // POST: api/Users/{id}/unlock
        [HttpPost("{id}/unlock")]
        public async Task<IActionResult> Unlock(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });

            await _userManager.SetLockoutEndDateAsync(user, null);
            await _userManager.ResetAccessFailedCountAsync(user);
            return Ok(new { message = "Đã mở khóa tài khoản" });
        }
    }
}
