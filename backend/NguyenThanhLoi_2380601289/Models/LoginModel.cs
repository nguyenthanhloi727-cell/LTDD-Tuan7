using System.ComponentModel.DataAnnotations;

namespace NguyenThanhLoi_2380601289.Models
{
    public class LoginModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }
}
