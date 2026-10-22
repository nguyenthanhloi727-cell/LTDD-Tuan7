using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Controllers
{
    // Chi Admin duoc xem danh sach tai khoan, khoa / mo khoa, thu hoi token, doi role.
    // Rieng me/revoke: ai dang nhap cung goi duoc cho chinh minh.
    // Khong co API nang ai len Admin (doi role chi trong Manager / Employee / User).
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly UserManager<User> _userManager;

        public UsersController(UserManager<User> userManager)
        {
            _userManager = userManager;
        }

        // GET: api/Users
        [HttpGet]
        [Authorize(Roles = "Admin")]
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
                    role = AppRoles.Highest(roles),
                    isLocked = await _userManager.IsLockedOutAsync(u)
                });
            }
            return Ok(result);
        }

        // POST: api/Users/{id}/lock — khoa vinh vien, doi SecurityStamp de token dang dung bi 401 ngay
        [HttpPost("{id}/lock")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Lock(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });
            if (await _userManager.IsInRoleAsync(user, "Admin"))
                return BadRequest(new { message = "Không thể khóa tài khoản Admin" });

            await _userManager.SetLockoutEnabledAsync(user, true);
            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);
            await _userManager.UpdateSecurityStampAsync(user);
            return Ok(new { message = "Đã khóa tài khoản" });
        }

        // POST: api/Users/{id}/unlock
        [HttpPost("{id}/unlock")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Unlock(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });

            await _userManager.SetLockoutEndDateAsync(user, null);
            await _userManager.ResetAccessFailedCountAsync(user);
            return Ok(new { message = "Đã mở khóa tài khoản" });
        }

        // POST: api/Users/{id}/revoke — "Buoc dang xuat": doi SecurityStamp, moi token cu cua user do bi 401
        [HttpPost("{id}/revoke")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Revoke(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });

            await _userManager.UpdateSecurityStampAsync(user);
            return Ok(new { message = "Đã buộc đăng xuất" });
        }

        // POST: api/Users/{id}/role  body { "role": "Manager" } — UP15: Admin doi role.
        // Chi doi giua Manager / Employee / User; khong doi role cua Admin, khong nang ai len Admin.
        // Doi xong doi SecurityStamp: token cu (role cu) bi 401, nguoi do dang nhap lai nhan role moi.
        [HttpPost("{id}/role")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> ChangeRole(string id, [FromBody] ChangeRoleModel model)
        {
            var role = AppRoles.Assignable.FirstOrDefault(
                r => string.Equals(r, model.Role, StringComparison.OrdinalIgnoreCase));
            if (role == null)
                return BadRequest(new { message = "Role chỉ được là Manager, Employee hoặc User" });

            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });
            if (await _userManager.IsInRoleAsync(user, AppRoles.Admin))
                return BadRequest(new { message = "Không thể đổi role tài khoản Admin" });

            var oldRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, oldRoles);
            await _userManager.AddToRoleAsync(user, role);
            await _userManager.UpdateSecurityStampAsync(user);
            return Ok(new { message = $"Đã đổi role thành {role}", role });
        }

        // POST: api/Users/me/revoke — tu thu hoi token cua chinh minh (nut demo het han token)
        [HttpPost("me/revoke")]
        public async Task<IActionResult> RevokeMe()
        {
            var user = await _userManager.FindByNameAsync(User.Identity!.Name!);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });

            await _userManager.UpdateSecurityStampAsync(user);
            return Ok(new { message = "Token hiện tại đã bị thu hồi" });
        }
    }

    public class ChangeRoleModel
    {
        public string Role { get; set; } = string.Empty;
    }
}
