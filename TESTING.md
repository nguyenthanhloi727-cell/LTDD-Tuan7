# Quy trình test — LTDD Tuần 7

Làm lần lượt từ trên xuống. Mỗi mục ghi **Làm gì** và **Kết quả đúng**. Cách cài đặt và chạy xem [README.md](README.md).

## 0. Chuẩn bị

1. Chạy backend (Visual Studio → Run profile `http`). Mở Swagger: `http://localhost:5080/swagger`.
2. Chạy app mobile (`flutter run`). `mobile/.env` đúng `BASE_URL` (máy ảo `http://10.0.2.2:5080`; điện thoại thật `adb reverse tcp:5080 tcp:5080` + `http://localhost:5080`).

### Tạo tài khoản test (Swagger)

Tài khoản **Admin** có sẵn: `admin` / `Admin@123` (backend tự tạo lúc chạy nếu chưa có Admin). Chỉ cần tạo tài khoản User:

`POST /api/Authenticate/register` → **Try it out**, gửi body:

```json
{ "username": "user", "email": "user@test.com", "password": "User@123", "initials": "US" }
```

Kết quả đúng: `200` `{ "message": "Đăng ký thành công" }`. Gửi lại lần 2 → `400` "Tên đăng nhập đã tồn tại".

### Lấy token Admin để tạo dữ liệu mẫu

1. `POST /api/Authenticate/login` với `{ "username": "admin", "password": "Admin@123" }` → copy giá trị `token`.
2. Bấm nút **Authorize** (góc phải trên) → dán token (không gõ chữ `Bearer`) → Authorize.
3. `POST /api/Categories` tạo 2 danh mục:
   ```json
   { "name": "Điện thoại", "description": "Smartphone" }
   ```
   ```json
   { "name": "Laptop", "description": "Máy tính xách tay" }
   ```
4. `GET /api/Categories` để xem `id` của 2 danh mục, rồi `POST /api/Products` tạo vài sản phẩm, ví dụ:
   ```json
   { "name": "iPhone 15", "price": 20000000, "description": "128GB", "imageUrl": null, "categoryId": 1 }
   ```
   ```json
   { "name": "Dell XPS 13", "price": 30000000, "description": "16GB RAM", "imageUrl": null, "categoryId": 2 }
   ```
   ```json
   { "name": "Tai nghe", "price": 500000, "description": "Bluetooth", "imageUrl": null, "categoryId": null }
   ```

---

## 1. Đăng ký trong app (P2 + BT5)

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 1.1 | Màn Đăng nhập → bấm "Chưa có tài khoản? Đăng ký" | Mở màn **Đăng ký** |
| 1.2 | (Android, BT5) Bấm icon SIM "Lấy số từ SIM" ở ô số điện thoại | Hiện hộp chọn số của Google; chọn số → số được điền vào ô. Bấm hủy → không có gì xảy ra |
| 1.3 | Điền tên đăng nhập `user2`, email, mật khẩu `User2@123`, tên viết tắt → Đăng ký | SnackBar "Đăng ký thành công, hãy đăng nhập", quay về màn Đăng nhập |
| 1.4 | Đăng ký lại `user2` | Báo lỗi "Tên đăng nhập đã tồn tại" |

## 2. Đăng nhập theo role (BT2)

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 2.1 | Đăng nhập sai mật khẩu | Báo "Sai tên đăng nhập hoặc mật khẩu", vẫn ở màn Đăng nhập |
| 2.2 | Đăng nhập `user` / `User@123` (nếu hỏi bật vân tay thì chọn **Không**) | Vào **Danh sách sản phẩm** (MainScreen), thấy sản phẩm kèm "Danh mục: ..." |
| 2.3 | Đăng xuất, đăng nhập `admin` / `Admin@123` | Vào **Trang Admin** |

## 3. Đăng xuất (BT1)

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 3.1 | Bấm icon Đăng xuất trên AppBar → **Hủy** | Hộp thoại đóng, vẫn ở trang hiện tại |
| 3.2 | Bấm Đăng xuất → **Đăng xuất** | Về màn Đăng nhập |
| 3.3 | Bấm nút Back của điện thoại | **Không** quay lại trang trước (thoát app) |

## 4. Mở lại app vào đúng trang (BT3)

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 4.1 | Đăng nhập `user` → kill app (vuốt khỏi đa nhiệm) → mở lại | Vào thẳng **Danh sách sản phẩm**, không hỏi đăng nhập |
| 4.2 | Đăng xuất, đăng nhập `admin` → kill app → mở lại | Vào thẳng **Trang Admin** |
| 4.3 | Đăng xuất → kill app → mở lại | Vào màn **Đăng nhập** |

Token hết hạn sau 3 giờ; hết hạn thì mở app sẽ về màn Đăng nhập.

## 5. Phân quyền API (BT4) — test trên Swagger

Bấm **Authorize → Logout** trước mỗi trường hợp để đổi token.

| # | Token | Gọi | Kết quả đúng |
|---|-------|-----|--------------|
| 5.1 | Không có | `GET /api/Products` | `401` |
| 5.2 | Không có | `GET /api/Categories` | `401` |
| 5.3 | `user` | `GET /api/Products` | `200`, có `categoryName` |
| 5.4 | `user` | `POST /api/Products` | `403` |
| 5.5 | `user` | `DELETE /api/Categories/{id}` | `403` |
| 5.6 | `admin` | `POST /api/Products` | `201` |

Trên app: đang ở MainScreen mà token bị mất hiệu lực (401) → app tự đăng xuất về màn Đăng nhập.

## 6. Danh mục + xóa danh mục thì set null (BT6, BT7, BT8)

Đăng nhập `admin` trên app.

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 6.1 | Trang Admin → icon "Quản lý danh mục" | Mở **Quản lý danh mục**, thấy "Điện thoại", "Laptop" |
| 6.2 | Bấm nút **+** → nhập "Phụ kiện" → Lưu | Danh mục mới xuất hiện trong danh sách |
| 6.3 | Sửa "Phụ kiện" thành "Phụ kiện điện tử" → Lưu | Tên được cập nhật |
| 6.4 | Quay lại Trang Admin → bấm "Tai nghe" → chọn "Phụ kiện điện tử" → Lưu | "Tai nghe" hiện "Danh mục: Phụ kiện điện tử" |
| 6.5 | Vào Quản lý danh mục → xóa "Phụ kiện điện tử" | Hộp thoại có câu "Sản phẩm trong danh mục này sẽ thành Chưa phân loại" → Xóa → danh mục biến mất |
| 6.6 | Quay lại Trang Admin (hoặc đăng nhập `user`) | "Tai nghe" hiện **"Danh mục: Chưa phân loại"**, sản phẩm **không bị xóa** |
| 6.7 | Swagger `GET /api/Products` | "Tai nghe" có `categoryId: null`, `categoryName: null` |

## 7. Đăng nhập bằng vân tay (biometric_storage)

Điện thoại/máy ảo phải đã cài vân tay (máy ảo: Settings → Security → Fingerprint, dùng Extended controls → Fingerprint để chạm).

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7.1 | Đăng xuất. Đăng nhập `user` bằng mật khẩu | Hỏi "Bật đăng nhập bằng vân tay cho lần sau?" → **Bật** → quét vân tay → SnackBar "Đã bật đăng nhập bằng vân tay", vào MainScreen |
| 7.2 | Đăng xuất | Màn Đăng nhập có nút **"Đăng nhập bằng vân tay"** |
| 7.3 | Bấm nút vân tay → quét đúng vân tay | Vào **Danh sách sản phẩm** (đúng role User) |
| 7.4 | Bấm nút vân tay → bấm hủy hộp quét | SnackBar "Đã hủy xác thực vân tay", vẫn ở màn Đăng nhập |
| 7.5 | Đăng nhập lại → icon "Tắt đăng nhập vân tay" trên AppBar → **Tắt** | SnackBar "Đã tắt đăng nhập bằng vân tay"; đăng xuất ra thì không còn nút vân tay |
| 7.6 | Làm lại 7.1–7.3 với `admin` | Quét vân tay vào **Trang Admin** |

## 7b. Chỉ 1 Admin + khóa tài khoản (UP1)

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7b.1 | Swagger register `{ "username": "hacker", "email": "h@test.com", "password": "Hacker@123", "initials": "HK", "role": "Admin" }` → login `hacker` trên app | Vào **Danh sách sản phẩm** (vẫn là User) |
| 7b.2 | Đăng nhập `admin` → icon "Quản lý tài khoản" | Thấy danh sách tài khoản; dòng `admin` không có nút khóa |
| 7b.3 | Bấm khóa `hacker` → xác nhận | Dòng `hacker` hiện "Đang khóa" |
| 7b.4 | Đăng xuất, đăng nhập `hacker` | Báo **"Tài khoản đã bị khóa"** |
| 7b.5 | Đăng nhập `admin` → mở khóa `hacker` → đăng nhập lại `hacker` | Đăng nhập được |
| 7b.6 | Swagger: token của `user` gọi `GET /api/Users` | `403` |
| 7b.7 | Swagger: token `admin` gọi `POST /api/Users/{id của admin}/lock` | `400` "Không thể khóa tài khoản Admin" |

## 7c. Token hết hạn / bị thu hồi (UP2)

Token có claim `stamp`; backend so với SecurityStamp trong DB, khác (bị thu hồi), user bị khóa hoặc hết `exp` → `401` → app tự về màn Đăng nhập + SnackBar "Phiên đăng nhập hết hạn, hãy đăng nhập lại".
Token đăng nhập **trước** khi cập nhật UP2 không có `stamp` → cũng 401, đăng nhập lại là xong.

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7c.1 | Đăng nhập `admin` → icon đồng hồ gạch chéo "Làm hết hạn token (demo)" → Đồng ý | Về màn **Đăng nhập**, có SnackBar |
| 7c.2 | Điện thoại đăng nhập `user`. Admin (Swagger hoặc máy khác) → Quản lý tài khoản → nút "Buộc đăng xuất" dòng `user` | User kéo tải lại danh sách → về màn **Đăng nhập** |
| 7c.3 | `user` đang đăng nhập; Admin khóa `user` | User kéo tải lại → về màn Đăng nhập; đăng nhập lại báo **"Tài khoản đã bị khóa"** |
| 7c.4 | Swagger: copy token `user` → Admin gọi `POST /api/Users/{id}/revoke` → dùng token cũ gọi `GET /api/Products` | `401` |
| 7c.5 | Swagger: token `user` gọi `POST /api/Users/me/revoke` → gọi lại `GET /api/Products` bằng token đó | `200` rồi `401` |

Vân tay: sau khi bị thu hồi vẫn đăng nhập vân tay được (gọi login lấy token mới), trừ khi tài khoản bị khóa.

## 7d. Số lượng, "Hết hàng", chặn số âm, email không trùng (UP3)

Sản phẩm có `quantity` (mặc định 0, migration `AddQuantity`). Backend: `[Range]` chặn giá/số lượng âm, `categoryId` không tồn tại → 400, `RequireUniqueEmail`.

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7d.1 | `admin` → nút **Thêm sản phẩm** → thử gõ `-` vào ô Giá / Số lượng | Không gõ được (chỉ nhận số); để trống → "Bắt buộc nhập" |
| 7d.2 | Thêm sản phẩm số lượng `0` → đăng nhập `user` | Sản phẩm hiện chữ đỏ **"Hết hàng"**; sản phẩm khác hiện "Còn: n" |
| 7d.3 | `admin` bấm 1 sản phẩm → sửa Tên/Giá/Số lượng/Danh mục → Lưu | Danh sách cập nhật đúng |
| 7d.4 | Swagger token Admin `POST /api/Products` `{"name":"A","price":-5}` hoặc `"quantity":-1` | `400` "Giá không được âm" / "Số lượng không được âm" |
| 7d.5 | Swagger `POST /api/Products` `{"name":"A","price":1,"categoryId":999999}` | `400` "Danh mục không tồn tại" (không còn 500) |
| 7d.6 | App đăng ký tài khoản mới dùng email đã có | Báo **"Email đã được sử dụng"** |

Tài khoản cũ trùng email (tạo trước UP3) vẫn giữ nguyên, chỉ chặn tạo mới.

## 7e. Kéo xuống để tải lại (UP4)

Trang User, Trang Admin, Quản lý danh mục, Quản lý tài khoản đều có `RefreshIndicator`, kéo được cả khi lỗi hoặc danh sách rỗng.

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7e.1 | Đang ở trang danh sách → tắt backend → kéo xuống | Hiện lỗi kết nối, vẫn kéo xuống được |
| 7e.2 | Bật lại backend → kéo xuống ở màn lỗi | Danh sách tải lại bình thường |
| 7e.3 | Màn có danh sách rỗng (vd. xóa hết danh mục) → kéo xuống | Hiện vòng xoay tải lại, không bị kẹt |
| 7e.4 | Quản lý danh mục → mở dialog Thêm/Sửa nhiều lần, Hủy/Lưu | Không có lỗi "used after being disposed" trong log |

## 8. Kiểm tra code trước khi nộp

```bash
dotnet build backend
```

```bash
cd mobile && flutter pub get && flutter analyze
```

Kết quả đúng: build `0 Error(s)`, analyze `No issues found!`.
