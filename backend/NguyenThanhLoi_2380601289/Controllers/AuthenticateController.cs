using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using NguyenThanhLoi_2380601289.Models;
using NguyenThanhLoi_2380601289.Services;

namespace NguyenThanhLoi_2380601289.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticateController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly OtpService _otpService;

        public AuthenticateController(UserManager<User> userManager,
            RoleManager<IdentityRole> roleManager, IConfiguration configuration,
            OtpService otpService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _otpService = otpService;
        }

        // POST: api/Authenticate/send-otp  { "phoneNumber": "0912345678" }
        // Tao ma OTP 6 so (han 5 phut), "gui SMS" = in ra log backend (xem OtpService)
        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpModel model)
        {
            var phone = OtpService.NormalizePhone(model.PhoneNumber);
            if (phone == null)
                return BadRequest(new { status = false, message = "Số điện thoại không hợp lệ" });

            if (await _userManager.Users.AnyAsync(u => u.PhoneNumber == phone))
                return BadRequest(new { status = false, message = "Số điện thoại đã được sử dụng" });

            var waitSeconds = _otpService.Send(phone);
            if (waitSeconds > 0)
                return StatusCode(StatusCodes.Status429TooManyRequests,
                    new { status = false, message = $"Vui lòng đợi {waitSeconds} giây rồi gửi lại mã" });

            return Ok(new { status = true, message = "Đã gửi mã OTP", expiresInSeconds = (int)OtpService.Lifetime.TotalSeconds });
        }

        // POST: api/Authenticate/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterModel model)
        {
            // UP5: bat buoc SDT + ma OTP dung
            var phone = OtpService.NormalizePhone(model.PhoneNumber);
            if (phone == null)
                return BadRequest(new { status = false, message = "Số điện thoại không hợp lệ" });

            var userExists = await _userManager.FindByNameAsync(model.Username);
            if (userExists != null)
                return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại" });

            // Kiem truoc bang AnyAsync: DB cu co the da co 2 tai khoan trung email
            // (FindByEmailAsync gap 2 dong se loi 500), du lieu cu giu nguyen, chi chan tao moi.
            var normalizedEmail = _userManager.NormalizeEmail(model.Email);
            if (!string.IsNullOrEmpty(normalizedEmail)
                && await _userManager.Users.AnyAsync(u => u.NormalizedEmail == normalizedEmail))
                return BadRequest(new { status = false, message = "Email đã được sử dụng" });

            if (await _userManager.Users.AnyAsync(u => u.PhoneNumber == phone))
                return BadRequest(new { status = false, message = "Số điện thoại đã được sử dụng" });

            // Ma chi bi xoa khi tao tai khoan thanh cong: sai mat khau... thi sua roi dang ky lai bang ma cu
            if (!_otpService.Verify(phone, model.Otp))
                return BadRequest(new { status = false, message = "Mã OTP không đúng hoặc đã hết hạn" });

            var user = new User
            {
                UserName = model.Username,
                Email = model.Email,
                Initials = model.Initials,
                PhoneNumber = phone,
                PhoneNumberConfirmed = true, // da xac minh qua OTP
                SecurityStamp = Guid.NewGuid().ToString()
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
                return BadRequest(new
                {
                    status = false,
                    message = "Tạo tài khoản thất bại",
                    errors = result.Errors.Select(e => new
                    {
                        code = e.Code,
                        description = e.Code == "DuplicateEmail" ? "Email đã được sử dụng" : e.Description
                    })
                });

            // Dang ky luon la User; tai khoan Admin duy nhat duoc tao san luc khoi dong (Program.cs)
            await _userManager.AddToRoleAsync(user, "User");
            _otpService.Remove(phone);

            return Ok(new { status = true, message = "Đăng ký thành công" });
        }

        // POST: api/Authenticate/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
                return Unauthorized(new { status = false, message = "Sai tên đăng nhập hoặc mật khẩu" });

            // Admin da khoa tai khoan nay (UsersController.Lock)
            if (await _userManager.IsLockedOutAsync(user))
                return Unauthorized(new { status = false, message = "Tài khoản đã bị khóa" });

            var userRoles = await _userManager.GetRolesAsync(user);

            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };
            // Dau cua tai khoan: Admin thu hoi / khoa -> doi SecurityStamp -> token cu het dung (Program.cs)
            authClaims.Add(new Claim("stamp", await _userManager.GetSecurityStampAsync(user)));
            foreach (var userRole in userRoles)
                authClaims.Add(new Claim(ClaimTypes.Role, userRole));

            var authSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["JWT:Secret"]!));

            var token = new JwtSecurityToken(
                issuer: _configuration["JWT:ValidIssuer"],
                audience: _configuration["JWT:ValidAudience"],
                expires: DateTime.Now.AddHours(3),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256));

            return Ok(new
            {
                status = true,
                message = "Đăng nhập thành công",
                token = new JwtSecurityTokenHandler().WriteToken(token),
                expiration = token.ValidTo
            });
        }
    }

    public class RegisterModel
    {
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Initials { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? Otp { get; set; }
    }

    public class SendOtpModel
    {
        public string? PhoneNumber { get; set; }
    }

    public class LoginModel
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
