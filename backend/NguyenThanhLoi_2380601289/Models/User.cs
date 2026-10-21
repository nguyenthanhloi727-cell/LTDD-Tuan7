using Microsoft.AspNetCore.Identity;

namespace NguyenThanhLoi_2380601289.Models
{
    public class User : IdentityUser
    {
        public string Initials { get; set; } = string.Empty;
    }
}
