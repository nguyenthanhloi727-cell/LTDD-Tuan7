using Microsoft.AspNetCore.Identity;

namespace NguyenThanhLoi_2380601289.Models
{
    public class User : IdentityUser
    {
        // Ten viet tat cua nguoi dung, vd: "NTL"
        public string Initials { get; set; } = string.Empty;
    }
}
