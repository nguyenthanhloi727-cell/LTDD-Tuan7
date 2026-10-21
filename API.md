# Hướng dẫn dùng API bằng Swagger

Backend: ASP.NET Core 8 Web API, xác thực bằng JWT, 2 role `Admin` / `User`.

## 1. Mở Swagger

1. Chạy backend (Visual Studio → Run profile `http`, hoặc `dotnet run --project backend/NguyenThanhLoi_2380601289`).
2. Mở trình duyệt: **http://localhost:5080/swagger**

Mỗi API là 1 dòng: bấm vào dòng → **Try it out** → sửa body/tham số → **Execute** → xem kết quả ở mục **Responses** (mã `Code` và `Response body`).

## 2. Đăng nhập và gắn token (bắt buộc cho hầu hết API)

Chỉ 3 API trong nhóm **Authenticate** gọi được khi chưa đăng nhập. Các API còn lại cần token:

1. `POST /api/Authenticate/login` → Try it out, body:
   ```json
   { "username": "admin", "password": "Admin@123" }
   ```
   Kết quả `200`:
   ```json
   { "status": true, "message": "Đăng nhập thành công",
     "token": "eyJhbGciOiJIUzI1NiIs...", "expiration": "2026-10-21T15:00:00Z" }
   ```
   Sai tên hoặc mật khẩu → `401` `{ "status": false, "message": "Sai tên đăng nhập hoặc mật khẩu" }`; tài khoản bị khóa → `401` "Tài khoản đã bị khóa".
2. Copy giá trị `token` (không lấy dấu ngoặc kép).
3. Bấm nút **Authorize** 🔓 ở góc phải trên → dán token vào ô **Value** → **Authorize** → **Close**.
   Chỉ dán token, **không** gõ chữ `Bearer` (Swagger tự thêm).
4. Từ giờ mọi request đều gửi kèm header `Authorization: Bearer <token>`.

Đổi tài khoản: bấm **Authorize** → **Logout** → dán token khác.
Token hết hạn sau 3 giờ, hoặc bị thu hồi (khóa / buộc đăng xuất) → API trả `401`, đăng nhập lại để lấy token mới.

Tài khoản Admin có sẵn: `admin` / `Admin@123` (tạo tự động khi chạy backend lần đầu). Hệ thống chỉ có 1 Admin.

## 3. Danh sách API

| Nhóm | Method + đường dẫn | Ai gọi được | Chức năng |
|---|---|---|---|
| Authenticate | `POST /api/Authenticate/send-otp` | Ai cũng được | Gửi mã OTP 6 số tới số điện thoại (hạn 5 phút) |
| | `POST /api/Authenticate/register` | Ai cũng được | Đăng ký tài khoản (luôn là role `User`, cần mã OTP) |
| | `POST /api/Authenticate/login` | Ai cũng được | Đăng nhập, trả về JWT |
| Products | `GET /api/Products` | Đã đăng nhập | Danh sách sản phẩm (kèm tên danh mục) |
| | `GET /api/Products/{id}` | Đã đăng nhập | Xem 1 sản phẩm |
| | `POST /api/Products` | Admin | Thêm sản phẩm |
| | `PUT /api/Products/{id}` | Admin | Sửa sản phẩm |
| | `DELETE /api/Products/{id}` | Admin | Xóa sản phẩm |
| | `POST /api/Products/upload-image` | Admin | Upload ảnh sản phẩm, trả về đường dẫn ảnh |
| Categories | `GET /api/Categories` | Đã đăng nhập | Danh sách danh mục (sắp theo tên) |
| | `GET /api/Categories/{id}` | Đã đăng nhập | Xem 1 danh mục |
| | `POST /api/Categories` | Admin | Thêm danh mục |
| | `PUT /api/Categories/{id}` | Admin | Sửa danh mục |
| | `DELETE /api/Categories/{id}` | Admin | Xóa danh mục (sản phẩm thuộc danh mục → "Chưa phân loại") |
| Users | `GET /api/Users` | Admin | Danh sách tài khoản |
| | `POST /api/Users/{id}/lock` | Admin | Khóa tài khoản (đá ra ngay) |
| | `POST /api/Users/{id}/unlock` | Admin | Mở khóa |
| | `POST /api/Users/{id}/revoke` | Admin | Buộc đăng xuất (token cũ hết dùng) |
| | `POST /api/Users/me/revoke` | Đã đăng nhập | Tự thu hồi token của chính mình |

### Ý nghĩa mã trả về

| Mã | Ý nghĩa |
|---|---|
| `200` / `201` / `204` | Thành công (`201` = đã tạo mới, `204` = thành công, không có body) |
| `400` | Dữ liệu sai, xem `message` hoặc `errors` trong body |
| `401` | Chưa Authorize, token hết hạn hoặc đã bị thu hồi → đăng nhập lại |
| `403` | Đã đăng nhập nhưng không đủ quyền (User gọi API của Admin) |
| `404` | Không tìm thấy (sai `id`, hoặc chưa chạy bản backend mới nhất) |
| `429` | Gửi OTP quá nhanh, đợi 60 giây |

## 4. Authenticate — đăng ký bằng OTP

Đăng ký gồm 2 bước:

**Bước 1:** `POST /api/Authenticate/send-otp`
```json
{ "phoneNumber": "0900000001" }
```
- `200` `{ "status": true, "message": "Đã gửi mã OTP", "expiresInSeconds": 300 }`
- Mã **không** trả về trong API. Xem cửa sổ chạy backend (Output / console), có dòng:
  ```
  [OTP] 0900000001: 123456 | Gia lap gui SMS: adb emu sms send 0900000001 "Ma OTP dang ky cua ban la 123456"
  ```
  Nếu đang mở máy ảo Android trên cùng máy, backend tự gửi SMS này vào máy ảo.
- Lỗi: `400` "Số điện thoại không hợp lệ" / "Số điện thoại đã được sử dụng"; `429` gửi lại trong 60 giây.
- Số điện thoại nhận dạng `0xxxxxxxxx` (10 số) hoặc `+84xxxxxxxxx`.

**Bước 2:** `POST /api/Authenticate/register` (thay `<mã>` bằng 6 số trong log)
```json
{
  "username": "user1",
  "email": "user1@test.com",
  "password": "User@123",
  "initials": "U1",
  "phoneNumber": "0900000001",
  "otp": "<mã>"
}
```
- `200` `{ "status": true, "message": "Đăng ký thành công" }` (lỗi thì `"status": false` + `message`)
- Lỗi `400`: "Tên đăng nhập đã tồn tại", "Email đã được sử dụng", "Số điện thoại đã được sử dụng", "Mã OTP không đúng hoặc đã hết hạn", hoặc lỗi mật khẩu trong `errors`.
- Mật khẩu: ít nhất 6 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt (ví dụ `User@123`).
- Gửi thêm `"role": "Admin"` cũng bị bỏ qua, tài khoản luôn là `User`.
- Nhập sai mã 5 lần thì mã bị hủy, phải gọi lại `send-otp`.

## 5. Products — sản phẩm

**Thêm** (Admin): `POST /api/Products`
```json
{
  "name": "iPhone 15",
  "price": 20000000,
  "description": "128GB",
  "imageUrl": null,
  "quantity": 10,
  "categoryId": 1
}
```
- `201`, body là sản phẩm vừa tạo (có `id`).
- `categoryId: null` = chưa phân loại. `categoryId` không tồn tại → `400` "Danh mục không tồn tại".
- `price` hoặc `quantity` âm → `400` "Giá không được âm" / "Số lượng không được âm".
- Không cần gửi `id` (server tự sinh).

**Xem danh sách**: `GET /api/Products` → `200`
```json
[
  { "id": 10, "name": "iPhone 15", "price": 20990000,
    "description": "Màn hình 6.1 inch, chip A16 Bionic, bộ nhớ 128GB.",
    "imageUrl": "/images/samples/iphone-15.png",
    "quantity": 12, "categoryId": 1, "categoryName": "Điện thoại" }
]
```
- `imageUrl` dạng `/...` là file trên backend, mở bằng `http://localhost:5080` + đường dẫn (ví dụ `http://localhost:5080/images/samples/iphone-15.png`, không cần token). Dạng `https://...` là link ngoài. `null` = không có ảnh.
- `categoryName: null` = "Chưa phân loại".

**Sửa** (Admin): `PUT /api/Products/{id}` — ô `id` trên URL và `"id"` trong body **phải giống nhau**, gửi **đầy đủ** các trường:
```json
{ "id": 1, "name": "iPhone 15 Pro", "price": 25000000, "description": "256GB",
  "imageUrl": null, "quantity": 5, "categoryId": 1 }
```
- `204` = đã sửa. `id` lệch nhau → `400`. Không có sản phẩm → `404`.

**Xóa** (Admin): `DELETE /api/Products/{id}` → `204`; không có → `404`.

**Upload ảnh** (Admin): `POST /api/Products/upload-image`
1. Try it out → ô `file` bấm **Choose File** → chọn ảnh `.jpg/.jpeg/.png/.webp/.gif` (tối đa 5 MB) → Execute.
2. Kết quả `200`: `{ "url": "/uploads/products/3f2a...c1.png" }`
3. Dùng `url` đó làm `imageUrl` khi `POST`/`PUT` sản phẩm. Xem ảnh trên trình duyệt: `http://localhost:5080/uploads/products/3f2a...c1.png`.
- Lỗi `400`: "Chỉ nhận ảnh .jpg, .jpeg, .png, .webp, .gif", "Ảnh tối đa 5 MB", không chọn file.
- `imageUrl` cũng nhận link ngoài (`https://...`).

**Dữ liệu mẫu:** chạy backend trên DB **chưa có sản phẩm nào** thì tự tạo 3 danh mục (Điện thoại, Laptop, Phụ kiện) + 6 sản phẩm có ảnh (`/images/samples/*.png`). DB đã có sản phẩm thì không thêm gì.

## 6. Categories — danh mục

**Thêm** (Admin): `POST /api/Categories`
```json
{ "name": "Điện thoại", "description": "Smartphone" }
```
→ `201`, body có `id` của danh mục mới.

**Sửa** (Admin): `PUT /api/Categories/{id}` — `id` trên URL và trong body phải giống nhau:
```json
{ "id": 1, "name": "Điện thoại di động", "description": "Smartphone" }
```
→ `204`.

**Xóa** (Admin): `DELETE /api/Categories/{id}` → `204`.
Sản phẩm không bị xóa theo, chỉ đổi `categoryId` thành `null` (hiện "Chưa phân loại").

## 7. Users — quản lý tài khoản (Admin)

**Danh sách**: `GET /api/Users` → `200`
```json
[
  { "id": "a1b2c3...", "username": "user1", "email": "user1@test.com",
    "phoneNumber": "0900000001", "role": "User", "isLocked": false }
]
```
Copy `id` (chuỗi dài) để dùng cho các API bên dưới, dán vào ô `id` của Swagger.

| API | Kết quả |
|---|---|
| `POST /api/Users/{id}/lock` | `200` "Đã khóa tài khoản". Người đó đăng nhập → `401` "Tài khoản đã bị khóa"; token đang dùng → `401` ngay. Khóa Admin → `400` "Không thể khóa tài khoản Admin" |
| `POST /api/Users/{id}/unlock` | `200` "Đã mở khóa tài khoản" |
| `POST /api/Users/{id}/revoke` | `200` "Đã buộc đăng xuất": mọi token cũ của người đó → `401`, phải đăng nhập lại |
| `POST /api/Users/me/revoke` | `200` "Token hiện tại đã bị thu hồi": token đang dán trong Authorize cũng hết dùng |

## 8. Kịch bản thử phân quyền nhanh

1. Không Authorize → `GET /api/Products` → **401**.
2. Đăng nhập `admin`, Authorize → `GET /api/Products` → **200**; `POST /api/Categories` → **201**.
3. Authorize → Logout, đăng nhập `user1`, Authorize bằng token của `user1`:
   - `GET /api/Products` → **200**
   - `POST /api/Products` / `DELETE /api/Categories/1` / `GET /api/Users` → **403**
4. Token `user1` gọi `POST /api/Products/upload-image` → **403**; token `admin` upload ảnh → **200** `{ "url": ... }`.
5. Đăng nhập lại `admin` → `POST /api/Users/{id của user1}/lock` → quay lại token `user1` gọi `GET /api/Products` → **401**.

Quy trình test cả app lẫn API theo từng bài: [TESTING.md](TESTING.md).
