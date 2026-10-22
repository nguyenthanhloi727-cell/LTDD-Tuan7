namespace NguyenThanhLoi_2380601289.Models
{
    // UP15: 4 vai tro. Moi tai khoan chi co 1 role.
    // - Admin: toan quyen + quan ly tai khoan + doi role (chi 1 Admin, UP1)
    // - Manager: them/sua/xoa san pham, danh muc, upload anh; khong vao quan ly tai khoan
    // - Employee: nhan vien, chi xem hang + ton kho
    // - User: khach hang
    public static class AppRoles
    {
        public const string Admin = "Admin";
        public const string Manager = "Manager";
        public const string Employee = "Employee";
        public const string User = "User";

        // Dung trong [Authorize(Roles = ...)] cho API them/sua/xoa hang
        public const string ManageProducts = Admin + "," + Manager;

        public static readonly string[] All = { Admin, Manager, Employee, User };

        // Role ma Admin duoc gan cho nguoi khac (khong co Admin -> giu luat chi 1 Admin)
        public static readonly string[] Assignable = { Manager, Employee, User };

        // Tai khoan co nhieu role (du lieu cu) thi lay role cao nhat
        public static string Highest(IEnumerable<string> roles) =>
            All.FirstOrDefault(roles.Contains) ?? User;
    }
}
