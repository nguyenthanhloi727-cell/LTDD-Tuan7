# LTDD Tuần 7 — Đăng nhập JWT + phân quyền Admin/User

Sinh viên: **Nguyễn Thành Lợi — 2380601289**

Bài tuần 7 mở rộng project tuần 6 (danh sách sản phẩm):

- `backend/`: ASP.NET Core 8 Web API, EF Core + SQL Server, ASP.NET Identity, JWT, 2 role `Admin` / `User`.
- `mobile/`: Flutter, dùng `flutter_dotenv`, `jwt_decoder`, `shared_preferences`; có màn hình Đăng nhập, Đăng ký, trang User (`MainScreen`), trang Admin (`AdminScreen`), tự đăng nhập bằng token đã lưu.

## Bài tập đã làm

| Bài | Nội dung | Vị trí chính |
|-----|----------|--------------|
| BT1 | Đăng xuất (xóa token, không Back lại được) | `mobile/lib/widgets/logout_button.dart` |
| BT2 | Đăng nhập xong vào đúng trang theo role | `LoginScreen`, `AuthService.getRole` |
| BT3 | Mở lại app vào đúng trang theo role (token còn hạn) | `mobile/lib/main.dart` |
| BT4 | Phân quyền API sản phẩm: chưa đăng nhập → 401, User gọi API Admin → 403 | `ProductsController`, `ProductService` |
| BT5 | (Cộng) `smart_auth`: lấy số điện thoại gợi ý khi đăng ký (Android) | `RegisterScreen` |
| BT6 | Bảng `Category`, sản phẩm có danh mục | `Models/Category.cs`, migration `AddCategory` |
| BT7 | Admin thêm / sửa / xóa danh mục, đổi danh mục cho sản phẩm | `CategoriesController`, `CategoryScreen`, `AdminScreen` |
| BT8 | `Product.CategoryId` nullable, xóa danh mục thì sản phẩm thành "Chưa phân loại" | `OnDelete(DeleteBehavior.SetNull)` |

Thêm: **đăng nhập nhanh bằng vân tay** (`biometric_storage`) — đăng nhập bằng mật khẩu lần đầu rồi bật, lần sau bấm nút vân tay.

Nâng cấp:

| Mã | Nội dung | Vị trí chính |
|----|----------|--------------|
| UP1 | Chỉ 1 tài khoản Admin (tạo sẵn lúc chạy, đăng ký luôn là User); Admin khóa / mở khóa tài khoản | `Program.cs`, `AuthenticateController`, `UsersController`, `UserManagementScreen` |

## Yêu cầu môi trường

- .NET 8 SDK (Visual Studio 2022)
- SQL Server Express (`.\SQLEXPRESS`) hoặc LocalDB (`(localdb)\MSSQLLocalDB`)
- Flutter SDK (Android Studio), máy ảo Android hoặc điện thoại Android

## Chạy backend

1. Mở `backend/NguyenThanhLoi_2380601289.sln` bằng Visual Studio.
2. Connection string nằm trong `backend/NguyenThanhLoi_2380601289/appsettings.json`:
   - `DefaultConnection`: `.\SQLEXPRESS`
   - `LocalDbConnection`: `(localdb)\MSSQLLocalDB` (tự dùng nếu không kết nối được SQLEXPRESS sau 3 giây)
3. Database tự tạo khi chạy (`Database.Migrate()` trong `Program.cs`), tự tạo 2 role `Admin`, `User` và tài khoản Admin (mục `AdminAccount` trong `appsettings.json`) nếu chưa có Admin nào.
   Muốn tạo bằng tay thì chạy:
   ```bash
   dotnet ef database update --project backend/NguyenThanhLoi_2380601289
   ```
4. Bấm Run (profile `http`). API chạy ở `http://0.0.0.0:5080`, Swagger: `http://localhost:5080/swagger`.

## Chạy mobile

1. Sửa `mobile/.env`:
   - Máy ảo Android: `BASE_URL=http://10.0.2.2:5080`
   - Điện thoại thật cắm USB: chạy `adb reverse tcp:5080 tcp:5080` rồi dùng `BASE_URL=http://localhost:5080`
2. Chạy:
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

Quy trình test chi tiết từng bài: [TESTING.md](TESTING.md).

## Tài khoản test

- **Admin** (tạo sẵn khi chạy backend lần đầu): `admin` / `Admin@123`. Hệ thống chỉ có 1 Admin, không có cách đăng ký hay nâng quyền lên Admin.
- **User**: đăng ký trong app (cần mã OTP, xem bên dưới), hoặc Swagger: gọi `POST /api/Authenticate/send-otp` `{ "phoneNumber": "0900000001" }`, lấy mã 6 số trong log backend, rồi `POST /api/Authenticate/register`:
  `{ "username": "user", "email": "user@test.com", "password": "User@123", "initials": "US", "phoneNumber": "0900000001", "otp": "<mã>" }`
  (gửi thêm `"role": "Admin"` cũng bị bỏ qua, tài khoản vẫn là `User`).

DB cũ đã có Admin tạo trước đây qua Swagger thì backend không tạo thêm `admin`; dùng lại tài khoản Admin cũ.
Mật khẩu theo luật mặc định của Identity: có chữ hoa, chữ thường, số và ký tự đặc biệt.
