# PROGRESS.md — LTDD Tuần 7

> Luật làm việc nằm trong `CLAUDE.md`. File này chỉ chứa tiến độ, chi tiết từng bước và nhật ký bàn giao.
> Đọc theo luật 10 trong `CLAUDE.md`: không đọc hết file.

---

## 1. Tiến độ

- [x] P0. Khởi tạo git + đẩy code tuần 6
- [x] P1. Backend: Identity + JWT + Role
- [x] P2. Flutter: dotenv + jwt_decoder + đăng nhập/đăng ký + tự đăng nhập
- [x] BT1. Đăng xuất
- [x] BT2. Đăng nhập đúng giao diện theo role
- [x] BT3. Mở lại app vào đúng trang theo role
- [x] BT4. Phân quyền API danh sách sản phẩm
- [x] BT6+8. Category + Product.CategoryId nullable + xóa danh mục thì set null
- [ ] BT7. Admin thêm/xóa/sửa danh mục
- [ ] BIO. Đăng nhập nhanh bằng vân tay với biometric_storage
- [ ] BT5. smart_auth (điểm cộng)
- [ ] FINAL. README + soát repo + tag nộp bài

---

## 2. Chi tiết từng bước

### P0. Khởi tạo git + đẩy code tuần 6

Làm mới từ đầu (không có code tuần 6 sẵn). Thông số đã chốt:
- Backend: `backend/NguyenThanhLoi_2380601289` (ASP.NET Core 8 Web API, controllers).
- Mobile: `flutter create --org com.nguyenthanhloi --project-name nguyenthanhloi_2380601289 mobile`.
- DB: `Server=.\SQLEXPRESS;Database=NguyenThanhLoi_2380601289;Trusted_Connection=True;TrustServerCertificate=True`.

Việc cần làm:
1. Tạo khung phần tuần 6: model `Product` (Id, Name, Price, Description?, ImageUrl?), `ApplicationDbContext` có `DbSet<Product>`, `ProductsController` CRUD, migration `InitialProduct`. Mobile: model `Product` + `ProductService` + màn danh sách sản phẩm (MainScreen tạm).
2. Tạo `.gitignore` ở gốc (giữ nguyên `mobile/.gitignore` do Flutter sinh ra):
   ```
   .vs/
   **/bin/
   **/obj/
   *.user
   *.suo
   .idea/
   *.iml
   ```
3. `git init` → `git branch -M main` → `git add .` → kiểm tra `git status` không có file trong bin/obj/build.
4. Commit: `chore: init repo voi code tuan 6 (backend + mobile)`.
5. Remote: nếu có `gh` và đã đăng nhập thì `gh repo create nguyenthanhloi727-cell/LTDD-Tuan7 --public --source=. --push`.
   Không có `gh` thì dừng, nhờ người dùng tạo repo rỗng `LTDD-Tuan7` trên GitHub, rồi chạy
   `git remote add origin https://github.com/nguyenthanhloi727-cell/LTDD-Tuan7.git` và `git push -u origin main`.

Người dùng tự kiểm tra: mở repo trên GitHub, không thấy thư mục bin/, obj/, .vs/, build/.

---

### P1. Backend: Identity + JWT + Role

Bỏ qua (đánh `[x]` luôn) nếu kiểm tra thấy đã có đủ 5 mục dưới và build chạy.

1. `User : IdentityUser` thêm `string Initials`.
2. `ApplicationDbContext : IdentityDbContext<User>`, `OnModelCreating` gọi `base.OnModelCreating` và `HasDefaultSchema("identity")`.
3. Gói: `Microsoft.AspNetCore.Identity.EntityFrameworkCore` 8.0.3, `Microsoft.AspNetCore.Authentication.JwtBearer` 8.x.
4. `AuthenticateController`: POST register (username, email, password, initials, role; role chưa có thì tạo), POST login trả JWT có claim Name, Jti, Role và thời hạn.
5. `Program.cs`: `AddIdentity<User, IdentityRole>`, `AddAuthentication().AddJwtBearer`, CORS, seed role Admin và User, `UseAuthentication()` đặt trước `UseAuthorization()`. Swagger có nút Authorize nhập Bearer token.
6. Migration `InitialIdentityModel` + `database update` (theo luật 7 trong `CLAUDE.md`).

Commit: `feat(api): Identity + JWT + seed role Admin/User` — add: `backend`

Người dùng tự kiểm tra: chạy API trong Visual Studio → Swagger register 1 tài khoản role User, 1 tài khoản role Admin → login ra token → dán vào https://jwt.io thấy claim role.

---

### P2. Flutter: dotenv + jwt_decoder + đăng nhập/đăng ký + tự đăng nhập

Bỏ qua nếu đã có đủ và chạy được.

1. `flutter pub add jwt_decoder flutter_dotenv shared_preferences http` (gói nào có rồi thì thôi).
2. `mobile/.env` có `BASE_URL=http://10.0.2.2:<port>` (hỏi người dùng port API nếu không tìm thấy trong `backend/**/launchSettings.json`). Khai `.env` trong assets của `pubspec.yaml`. `main()` gọi `await dotenv.load(fileName: ".env")` trước `runApp`.
3. `lib/config/config_url.dart`: đọc BASE_URL, gom endpoint login, register, products.
4. Tạo `lib/services/auth_service.dart` (nếu chưa có) chứa: `saveToken`, `getToken`, `logout`, `getRole(token)`. Các bước sau dùng chung file này.
5. LoginScreen gọi login, lưu token; RegisterScreen gọi register.
6. Mở app: có token và `JwtDecoder.isExpired(token) == false` thì vào màn chính, không thì LoginScreen.

Commit: `feat(mobile): dang nhap/dang ky JWT, dotenv, tu dang nhap` — add: `mobile`

Người dùng tự kiểm tra: đăng ký → đăng nhập → tắt hẳn app → mở lại vào thẳng màn chính.

---

### BT1. Đăng xuất

1. `AuthService.logout()`: xóa đúng key token trong shared_preferences.
2. Nút đăng xuất trên AppBar (hoặc Drawer) ở **cả** MainScreen và trang Admin.
3. Bấm → dialog xác nhận → `logout()` → `Navigator.pushAndRemoveUntil` về LoginScreen (xóa hết stack).

Commit: `feat(mobile): BT1 dang xuat, xoa token` — add: `mobile`

Người dùng tự kiểm tra: đăng xuất → bấm Back không quay lại được → tắt mở app vẫn ở LoginScreen.

---

### BT2. Đăng nhập đúng giao diện theo role

Lỗi hiện tại: Admin đăng nhập vẫn vào MainScreen.

1. `AuthService.getRole(token)`: decode bằng `JwtDecoder.decode`, đọc role ở key `"role"` **hoặc** `"http://schemas.microsoft.com/ws/2008/06/identity/claims/role"`. Giá trị có thể là `String` hoặc `List` (nhiều role) → có `"Admin"` thì trả `"Admin"`, còn lại trả `"User"`.
2. Thêm `debugPrint` payload token 1 lần (ghi comment `// TODO xoa truoc khi nop`).
3. LoginScreen: login thành công → `getRole` → Admin `pushReplacement` trang Admin, còn lại MainScreen.

Commit: `fix(mobile): BT2 dieu huong theo role sau khi dang nhap` — add: `mobile`

Người dùng tự kiểm tra: login Admin vào trang Admin; login User vào MainScreen.

---

### BT3. Mở lại app vào đúng trang theo role

Lỗi hiện tại: Admin thoát app vào lại thì vào MainScreen.

1. Sửa đoạn kiểm tra token lúc khởi động (main.dart hoặc splash/wrapper), dùng lại `getRole` của BT2:
   - Có token, chưa hết hạn → Admin vào trang Admin, User vào MainScreen.
   - Token hết hạn → `logout()` rồi vào LoginScreen.
   - Không có token → LoginScreen.

Commit: `fix(mobile): BT3 tu dang nhap vao dung trang theo role` — add: `mobile`

Người dùng tự kiểm tra: login Admin → kill app → mở lại vào trang Admin. Làm lại với User.

---

### BT4. Phân quyền API danh sách sản phẩm

Backend:
1. GET danh sách sản phẩm: `[Authorize]`.
2. POST/PUT/DELETE sản phẩm: `[Authorize(Roles = "Admin")]`.
3. Kiểm tra lại thứ tự `UseAuthentication` → `UseAuthorization` và Swagger có nút Authorize.

Mobile:
4. Mọi request API sản phẩm gửi header `Authorization: Bearer <token>`.
5. 401 → `logout()` + về LoginScreen. 403 → SnackBar "Không có quyền".

Commit: `feat: BT4 phan quyen API san pham + gui Bearer token` — add: `backend mobile`

Người dùng tự kiểm tra: Swagger không token gọi GET → 401; token User gọi DELETE → 403; app đăng nhập vẫn thấy danh sách sản phẩm.

---

### BT6+8. Category + Product.CategoryId nullable + xóa danh mục thì set null

Backend:
1. Model `Category` (Id, Name, Description?), `DbSet<Category>`.
2. `Product` thêm `int? CategoryId` và `Category? Category`.
3. `OnModelCreating`: 1 Category nhiều Product, `.OnDelete(DeleteBehavior.SetNull)`.
4. Migration `AddCategory` + database update. Mở file migration kiểm tra có `onDelete: ReferentialAction.SetNull`, không có thì sửa config rồi tạo lại.
5. GET sản phẩm trả DTO có thêm `categoryId`, `categoryName` (null nếu không có), tránh vòng lặp JSON.

Mobile:
6. `Product` thêm `int? categoryId`, `String? categoryName`, `fromJson` chịu được null.
7. Danh sách sản phẩm hiện tên danh mục, null thì hiện "Chưa phân loại".

Commit: `feat: BT6 BT8 them Category, CategoryId nullable, xoa danh muc set null` — add: `backend mobile`

Người dùng tự kiểm tra: trong SQL Server bảng Products có cột CategoryId cho phép NULL; app hiện "Chưa phân loại" với sản phẩm cũ.

---

### BT7. Admin thêm/xóa/sửa danh mục

Backend — `CategoriesController`:
1. GET tất cả, GET theo id: `[Authorize]`.
2. POST, PUT, DELETE: `[Authorize(Roles = "Admin")]`. DELETE không xóa sản phẩm (dựa vào SetNull).

Mobile (chỉ trang Admin):
3. Thêm endpoint categories vào `config_url.dart`, gửi Bearer token.
4. Màn quản lý danh mục: danh sách, thêm, sửa (dialog nhập tên), xóa (dialog ghi "Sản phẩm trong danh mục này sẽ thành Chưa phân loại").
5. Form thêm/sửa sản phẩm (nếu có) thêm Dropdown chọn danh mục, có lựa chọn "Không có".
6. Trang User không có nút quản lý danh mục.

Commit: `feat: BT7 CRUD danh muc cho Admin (API + giao dien)` — add: `backend mobile`

Người dùng tự kiểm tra: Admin tạo danh mục → gán 2 sản phẩm → xóa danh mục → 2 sản phẩm vẫn còn, hiện "Chưa phân loại". Login User không thấy chức năng quản lý.

---

### BIO. Đăng nhập nhanh bằng vân tay với biometric_storage

Package: https://pub.dev/packages/biometric_storage — bản stable mới nhất lúc lập plan là **5.0.1** (có bản 6.0.0-dev, **không dùng** bản dev). Package là kho lưu trữ mã hóa, đọc/ghi có thể bắt xác thực sinh trắc học.

Phạm vi: chỉ thêm tính năng đăng nhập nhanh, **không** đổi luồng của bài học và BT1–BT8 (token vẫn lưu shared_preferences, tự đăng nhập và điều hướng theo role giữ nguyên).

Thiết kế:
- Lưu **username + password** (JSON) vào biometric storage file `login_credentials`, không lưu token (token hết hạn thì lưu cũng vô dụng).
- Đăng nhập thường thành công lần đầu → hỏi "Bật đăng nhập bằng vân tay?" → đồng ý thì ghi vào storage.
- LoginScreen có nút "Đăng nhập bằng vân tay" (chỉ hiện khi máy hỗ trợ và đã bật) → đọc storage (hệ điều hành hiện hộp thoại vân tay) → gọi API login như bình thường → điều hướng theo role (dùng lại `getRole` của BT2).
- Đăng xuất (BT1) **không** xóa dữ liệu vân tay. Thêm nút "Tắt đăng nhập vân tay" (trên trang User và Admin) để xóa storage.
- Gọi API login bằng vân tay mà bị 401 (đổi mật khẩu) → xóa storage, báo đăng nhập lại bằng mật khẩu.

Việc cần làm:
1. Đọc API docs của bản 5.0.1 (`BiometricStorage().canAuthenticate()`, `getStorage(name, options: StorageFileInitOptions(...))`, `read`, `write`, `delete`, `PromptInfo`) để dùng đúng tên tham số, không đoán.
2. `flutter pub add biometric_storage:^5.0.1`.
3. Android:
   - `minSdk` ≥ 23 trong `android/app/build.gradle(.kts)`.
   - `MainActivity` đổi từ `FlutterActivity` sang `FlutterFragmentActivity`.
   - `LaunchTheme` và `NormalTheme` trong `res/values/styles.xml` (và `values-night` nếu có) dùng parent `Theme.AppCompat.NoActionBar`, nếu không app crash trên Android dưới 10.
4. iOS: thêm `NSFaceIDUsageDescription` vào `ios/Runner/Info.plist`.
5. Tạo `lib/services/biometric_service.dart`: `isSupported()`, `isEnabled()`, `saveCredentials(username, password)`, `readCredentials()` (trả null nếu người dùng hủy hoặc lỗi), `disable()`. Bắt mọi exception, không để app crash khi người dùng bấm Hủy.
6. Gắn vào LoginScreen, trang User, trang Admin theo thiết kế trên.
7. Nếu BT5 smart_auth cũng yêu cầu sửa MainActivity/theme thì giữ cấu hình chung, không ghi đè lẫn nhau.

Commit: `feat(mobile): dang nhap bang van tay voi biometric_storage` — add: `mobile`

Người dùng tự kiểm tra (emulator: Settings → Security → thêm vân tay, giả lập chạm bằng Extended Controls → Fingerprint):
- [ ] Đăng nhập mật khẩu → bật vân tay → đăng xuất → bấm "Đăng nhập bằng vân tay" → chạm → vào đúng trang theo role
- [ ] Bấm Hủy ở hộp thoại vân tay → app không crash, vẫn ở LoginScreen
- [ ] "Tắt đăng nhập vân tay" → nút vân tay ở LoginScreen biến mất
- [ ] Máy chưa cài vân tay → không hiện nút vân tay

---

### BT5. smart_auth (điểm cộng)

1. Trước khi code: đọc https://pub.dev/packages/smart_auth (bản mới nhất), báo cho người dùng package làm được gì, bản nào hợp với Flutter SDK hiện tại (`flutter --version`), cần cấu hình gì trong `android/`. **Chờ người dùng chọn cách tích hợp** rồi mới code.
2. Gợi ý mặc định: gắn vào LoginScreen (lưu/gợi ý tài khoản hoặc đọc OTP nếu có). Không dùng API đã bị bỏ.
3. Chỉ chạy trên Android; iOS không crash (kiểm tra `Platform.isAndroid`).

Commit: `feat(mobile): BT5 tich hop smart_auth` — add: `mobile`

Người dùng tự kiểm tra: chạy trên máy thật hoặc emulator có Google Play, chụp màn hình để demo.

---

### FINAL. README + soát repo + tag nộp bài

1. Xóa các `debugPrint` có `TODO xoa truoc khi nop`.
2. Viết `README.md` ở gốc: mô tả bài tuần 7, bảng BT1–BT8 đã làm, yêu cầu môi trường (.NET 8, SQL Server, Flutter SDK), cách chạy backend (connection string, `dotnet ef database update`, chạy API) và mobile (BASE_URL trong `.env`, `flutter pub get`, `flutter run`), 2 tài khoản test Admin/User. Ghi thêm 1 dòng: có tính năng đăng nhập nhanh bằng vân tay (biometric_storage).
3. Soát: `git ls-files | grep -E "bin/|obj/|build/|\.dart_tool"` phải rỗng; không có mật khẩu thật trong repo.
4. Chạy lại `dotnet build backend` và `flutter analyze`.

Commit: `docs: README tuan 7 + hoan thien bai tap` — add: `.`
Sau khi push: `git tag tuan7-nop && git push origin tuan7-nop`.

Người dùng tự kiểm tra (demo cho thầy):
- [ ] Login Admin → trang Admin; login User → MainScreen
- [ ] Kill app mở lại vào đúng trang theo role
- [ ] Đăng xuất xong Back không quay lại được
- [ ] Không token → 401; User gọi API Admin → 403
- [ ] Admin thêm/sửa/xóa danh mục; xóa danh mục thì sản phẩm thành "Chưa phân loại"
- [ ] Đăng nhập bằng vân tay vào đúng trang theo role
- [ ] (Cộng) smart_auth chạy được

---

## 3. Nhật ký bàn giao

> Mỗi bước ghi 3–5 dòng ngay dưới đây, mới nhất ở dưới cùng. Phiên sau đọc mục này thay vì quét lại code.

- P0 (xong): tạo `backend/NguyenThanhLoi_2380601289` (Product, ApplicationDbContext, ProductsController CRUD, CORS "AllowAll", Swagger, cổng 5080) + `.sln`; DB `.\SQLEXPRESS` Windows Auth.
  Mobile `nguyenthanhloi_2380601289`: `config/config_url.dart` (baseUrl `http://10.0.2.2:5080`), `models/product.dart`, `services/product_service.dart`, `screens/main_screen.dart`; Manifest thêm INTERNET + usesCleartextTraffic. `flutter analyze` sạch.
  Đã cài .NET 8 SDK 8.0.426 (winget). `dotnet-ef` global là bản 10.0.8, dùng được với EF 8 → giữ nguyên. Migration `InitialProduct` + database update xong, `dotnet build backend` 0 lỗi.
  Repo public: https://github.com/nguyenthanhloi727-cell/LTDD-Tuan7. Bước sau (P1): đổi `ApplicationDbContext` sang `IdentityDbContext<User>`, giữ `DbSet<Product>`.
- P1 (xong): `Models/User.cs` (`User : IdentityUser` + `Initials`); `ApplicationDbContext : IdentityDbContext<User>`, `HasDefaultSchema("identity")` (bảng Products cũng sang schema identity). Gói Identity.EFCore + JwtBearer 8.0.3.
  `Controllers/AuthenticateController.cs`: POST `api/Authenticate/register` (role trống → "User", role chưa có thì tạo), POST `api/Authenticate/login` trả `{ token, expiration }` (claim Name, Jti, Role; hạn 3 giờ). Config `JWT:ValidIssuer/ValidAudience/Secret` trong `appsettings.json`.
  `Program.cs`: AddIdentity, AddJwtBearer, Swagger nút Authorize, seed role Admin/User, `UseAuthentication()` trước `UseAuthorization()`. Migration `InitialIdentityModel`.
  Chạy máy khác: `Program.cs` tự `Database.Migrate()` lúc khởi động + thử `.\SQLEXPRESS` 3s, không được thì dùng `LocalDbConnection` `(localdb)\MSSQLLocalDB` → clone về bấm Run là chạy.
  Lưu ý cho P2: `dotnet` không có trong PATH của Claude, gọi `C:\Program Files\dotnet\dotnet.exe`. DB máy mới trống, phải register lại tài khoản.
- P2 (xong): gói `jwt_decoder`, `flutter_dotenv`, `shared_preferences`; `mobile/.env` (`BASE_URL=http://10.0.2.2:5080`, khai trong assets, được commit). `main()` load dotenv rồi `AuthService().getValidToken()` → `MyApp(isLoggedIn)` chọn `MainScreen`/`LoginScreen`.
  `config/config_url.dart`: getter `baseUrl`, `login`, `register`, `products` (không còn `const`).
  `services/auth_service.dart`: `login`, `register` (trả null nếu ok, ngược lại chuỗi lỗi), `saveToken`/`getToken`/`logout` (key prefs `'token'`), `getValidToken`, `getRole(token)` đọc claim `http://schemas.microsoft.com/ws/2008/06/identity/claims/role`.
  `screens/login_screen.dart`, `screens/register_screen.dart` mới; `test/widget_test.dart` sửa theo `MyApp(isLoggedIn: false)`.
  Cho BT1/BT2: `MainScreen` chưa có nút đăng xuất; login hiện luôn vào `MainScreen`, chưa rẽ theo role. Máy này không có Python, sửa file bằng Edit.
- BT1 (xong): `AuthService.logout()` có sẵn (xóa key `'token'`), không sửa.
  Mới `mobile/lib/widgets/logout_button.dart`: `LogoutButton` (IconButton) → dialog xác nhận → `logout()` → `Navigator.pushAndRemoveUntil(..., (route) => false)` về `LoginScreen`.
  `MainScreen` AppBar thêm `actions: const [LogoutButton()]`.
  Cho BT2: trang Admin chưa có → khi tạo nhớ gắn `actions: const [LogoutButton()]` vào AppBar.
- BT2 (xong): `AuthService.getRole(token)` đổi sang trả `String` ("Admin"/"User"): đọc `roleClaim` hoặc `'role'`, chuỗi hay List đều được, có "Admin" thì là Admin. Có `debugPrint('JWT payload: ...')` kèm `// TODO xoa truoc khi nop` (FINAL nhớ xóa).
  Mới `mobile/lib/screens/admin_screen.dart`: `AdminScreen` (AppBar "Trang Admin" + `LogoutButton`, body lời chào) → BT7 thêm quản lý danh mục vào đây.
  `LoginScreen._login`: login ok → `getToken()` → `getRole` → Admin `pushReplacement` `AdminScreen`, còn lại `MainScreen`.
  Cho BT3: `main.dart` vẫn dùng `MyApp(isLoggedIn)` chỉ chọn `MainScreen`/`LoginScreen`, chưa rẽ theo role. Tài khoản Admin tạo qua Swagger (`"role": "Admin"`), app đăng ký luôn gửi role User.
- BT3 (xong): `main.dart` `main()`: có token → `getValidToken()`; còn hạn thì `role = getRole(token)`, hết hạn thì `logout()`; không có token → role null.
  `MyApp` đổi tham số `isLoggedIn` → `String? role` (null → `LoginScreen`, "Admin" → `AdminScreen`, "User" → `MainScreen`). `test/widget_test.dart` sửa thành `MyApp(role: null)`.
  `AuthService` không sửa. Cho BT4: backend chưa gắn `[Authorize]` cho `ProductsController`, `ProductService` chưa gửi header `Authorization: Bearer`.
- BT4 (xong): `ProductsController` gắn `[Authorize]` cả class (GET cần đăng nhập), POST/PUT/DELETE thêm `[Authorize(Roles = "Admin")]`. `Program.cs` đã đúng thứ tự, không sửa.
  `services/product_service.dart`: class mới `ApiException(statusCode, message)`; `_headers()` gửi `Authorization: Bearer <token>` (lấy từ `AuthService().getToken()`); `getProducts()` ném `ApiException` 401/403/khác.
  `MainScreen._fetch()`: 401 → `logout()` + `pushAndRemoveUntil` về `LoginScreen`; 403 → SnackBar "Không có quyền". `_reload()` nuốt lỗi (lỗi hiện qua FutureBuilder).
  Cho BT6+8/BT7: API Category mới nhớ gắn Authorize tương tự; service mới dùng lại cách tạo header Bearer + `ApiException` như `ProductService`.
- BT6+8 (xong): mới `Models/Category.cs` (Id, Name, Description?, `[JsonIgnore] Products`), `Models/ProductDto.cs` (thêm `CategoryId`, `CategoryName`). `Product` thêm `int? CategoryId` + `[JsonIgnore] Category?`.
  `ApplicationDbContext`: `DbSet<Category> Categories`; `OnModelCreating` HasOne/WithMany/`OnDelete(DeleteBehavior.SetNull)`. Migration `AddCategory` (có `ReferentialAction.SetNull`) đã database update.
  `ProductsController`: 2 GET trả `ProductDto` qua expression `ToDto` (LEFT JOIN lấy `Category.Name`); POST/PUT/DELETE vẫn nhận `Product` (gửi `categoryId` được).
  Mobile: `Product` thêm `categoryId`, `categoryName` (nullable); `MainScreen` subtitle "Danh mục: ... / Chưa phân loại".
  Cho BT7: chưa có `CategoriesController` và `CategoryService`; nhớ `[Authorize]` + Admin cho POST/PUT/DELETE, service dùng `_headers()` + `ApiException` như `ProductService`.
