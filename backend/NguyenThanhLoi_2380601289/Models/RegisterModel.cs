using System.ComponentModel.DataAnnotations;

namespace NguyenThanhLoi_2380601289.Models
{
    public class RegisterModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;

        public string Initials { get; set; } = string.Empty;

        // "Admin" hoac "User", bo trong thi mac dinh la "User"
        public string? Role { get; set; }
    }
}
