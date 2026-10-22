# Quy trình test — LTDD Tuần 7

Làm lần lượt từ trên xuống. Mỗi mục ghi **Làm gì** và **Kết quả đúng**. Cách cài đặt và chạy xem [README.md](README.md).

## 0. Chuẩn bị

1. Chạy backend (Visual Studio → Run profile `http`). Mở Swagger: `http://localhost:5080/swagger`.
2. Chạy app mobile (`flutter run`). `mobile/.env` đúng `BASE_URL` (máy ảo `http://10.0.2.2:5080`; điện thoại thật `adb reverse tcp:5080 tcp:5080` + `http://localhost:5080`).

### Tạo tài khoản test (Swagger)

Tài khoản **Admin** có sẵn: `admin` / `Admin@123` (backend tự tạo lúc chạy nếu chưa có Admin). Chỉ cần tạo tài khoản User:

Đăng ký cần mã OTP (UP5):

1. `POST /api/Authenticate/send-otp` → **Try it out**, gửi `{ "phoneNumber": "0900000001" }`.
2. Xem cửa sổ chạy backend: có dòng `[OTP] 0900000001: 123456 | ...` → mã là 6 số đó (hạn 5 phút).
3. `POST /api/Authenticate/register`, gửi body (thay `<mã>`):

```json
{ "username": "user", "email": "user@test.com", "password": "User@123", "initials": "US", "phoneNumber": "0900000001", "otp": "<mã>" }
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
| 1.3 | Điền tên đăng nhập `user2`, email, mật khẩu `User2@123`, tên viết tắt, số điện thoại → bấm **Gửi mã** → nhập mã OTP (xem mục 7f) → Đăng ký | SnackBar "Đăng ký thành công, hãy đăng nhập", quay về màn Đăng nhập |
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
| 7b.1 | Swagger `send-otp` `{ "phoneNumber": "0900000002" }` → register `{ "username": "hacker", "email": "h@test.com", "password": "Hacker@123", "initials": "HK", "phoneNumber": "0900000002", "otp": "<mã trong log>", "role": "Admin" }` → login `hacker` trên app | Vào **Danh sách sản phẩm** (vẫn là User) |
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

## 7f. Đăng ký bằng mã OTP qua SMS (UP5 + UP6, smart_auth)

Không thuê dịch vụ SMS: backend tạo mã 6 số (hạn 5 phút), in ra log dạng
`[OTP] 0900000003: 123456 | Gia lap gui SMS: adb emu sms send 0900000003 "Ma OTP dang ky cua ban la 123456"`
và **tự chạy lệnh đó** (UP6) vào máy ảo đang mở trên cùng máy tính → máy ảo nhận SMS như thật,
app dùng smart_auth (SMS User Consent API) đọc tin và tự điền mã.
Backend tìm `adb.exe` theo `SmsSimulator:AdbPath` (appsettings.json) → `ANDROID_HOME` → `%LOCALAPPDATA%\Android\Sdk\platform-tools` → PATH.

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7f.1 | **Máy ảo** (backend chạy cùng máy): màn Đăng ký → điền thông tin + SĐT `0900000003` → bấm **Gửi mã** | SnackBar "Đã gửi mã OTP..."; log backend có dòng `[OTP]` rồi `[SMS gia lap] Da gui SMS ...` |
| 7f.2 | Chờ 2–3 giây (không gõ lệnh gì) | Hiện hộp **"Cho phép ... đọc tin nhắn"**. Không hiện → xem log `[SMS gia lap]`; vẫn gửi tay được bằng lệnh trong log hoặc emulator ⋯ → Phone |
| 7f.3 | Bấm **Cho phép** | Ô "Mã OTP" tự điền 6 số, SnackBar "Đã tự điền mã OTP từ SMS" → bấm Đăng ký → thành công |
| 7f.4 | Bấm **Gửi mã** lần nữa ngay sau đó | Báo "Vui lòng đợi ... giây rồi gửi lại mã" |
| 7f.5 | Nhập mã sai → Đăng ký | Báo "Mã OTP không đúng hoặc đã hết hạn", không tạo tài khoản |
| 7f.6 | Đăng ký tài khoản khác bằng SĐT đã dùng | Bấm Gửi mã → "Số điện thoại đã được sử dụng" |
| 7f.7 | **Điện thoại thật** (log backend ghi "Khong thay may ao Android"): lấy mã trong log backend, gõ tay vào ô OTP (hoặc nhờ máy khác nhắn tin chứa mã tới số mình — người gửi không nằm trong danh bạ) | Đăng ký thành công |

## 7g. Admin xóa sản phẩm + tên app "Smart Auth" (UP7)

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7g.1 | Đăng nhập `admin` → bấm 🗑 ở 1 sản phẩm → **Hủy** | Không xóa gì |
| 7g.2 | Bấm 🗑 lại → **Xóa** | SnackBar "Đã xóa ..."; sản phẩm biến mất khỏi danh sách (đăng nhập `user` cũng không còn thấy) |
| 7g.3 | Bấm ✏️ hoặc bấm vào dòng sản phẩm | Vẫn mở form sửa như cũ |
| 7g.4 | Xem tên app dưới icon trên máy, và hộp "Allow ... to read the message" ở mục 7f | Hiện **Smart Auth** |

## 7h. Ảnh sản phẩm, chi tiết sản phẩm, upload ảnh, dữ liệu mẫu (UP8–UP10)

DB chưa có sản phẩm nào → backend tự tạo 3 danh mục + 6 sản phẩm mẫu có ảnh (iPhone 15, Galaxy S24, MacBook Air M3, Dell XPS 13 hết hàng, Tai nghe, Chuột).

| # | Làm gì | Kết quả đúng |
|---|--------|--------------|
| 7h.1 | Màn Đăng nhập / Đăng ký: bấm icon con mắt ở ô mật khẩu | Hiện chữ mật khẩu; bấm lại → ẩn |
| 7h.2 | Swagger `POST /api/Authenticate/login` | Body có `"status": true`, `"message": "Đăng nhập thành công"`, `token`; sai mật khẩu → `401` `"status": false` |
| 7h.3 | Đăng nhập `user` → Trang User | Sản phẩm mẫu có ảnh; sản phẩm không có ảnh hiện icon túi |
| 7h.4 | Bấm 1 sản phẩm | Mở **Chi tiết sản phẩm**: ảnh lớn, tên, giá, tồn kho, danh mục, mô tả |
| 7h.5 | Đăng nhập `admin` → bấm 👁 ở 1 sản phẩm | Mở cùng màn chi tiết như User |
| 7h.6 | Admin → ✏️ sửa 1 sản phẩm → **Chọn ảnh** → chọn ảnh trong máy | Nút hiện "Đang tải lên...", xong thì ô Link ảnh có `/uploads/products/...` và ảnh xem trước đổi |
| 7h.7 | Bấm **Lưu** | Danh sách và màn chi tiết hiện ảnh mới (User cũng thấy) |
| 7h.8 | Ô Link ảnh dán link ngoài `https://...` hoặc xóa trống → Lưu | Hiện ảnh từ link / quay về icon túi |
| 7h.9 | Swagger `upload-image` bằng token User | `403` |

## 7i. Theme chung + định dạng giá + giao diện Đăng nhập / Đăng ký (UP11)

| # | Thao tác | Kết quả mong đợi |
|---|---|---|
| 7i.1 | Mở app (chưa đăng nhập) | Màn Đăng nhập không có AppBar: logo túi tròn xanh, chữ **Smart Auth**, "Đăng nhập để tiếp tục"; ô nhập nền xám bo tròn có icon người / ổ khóa |
| 7i.2 | Bấm vào ô nhập | Viền xanh khi focus; nút con mắt vẫn hiện/ẩn mật khẩu |
| 7i.3 | Đăng nhập `user` / `admin` | Vào đúng trang theo role như cũ; máy đã bật vân tay thì có nút **Đăng nhập bằng vân tay** dưới nút Đăng nhập và vẫn dùng được |
| 7i.4 | Bấm **Đăng ký** | Màn "Tạo tài khoản" có nút quay lại, các ô có icon (người, email, khóa, thẻ, điện thoại, tin nhắn); Gửi mã OTP + nút SIM + đăng ký chạy như 7f |
| 7i.5 | Xem giá ở Trang User, Trang Admin, Chi tiết sản phẩm | Dạng `20.990.000 đ` (dấu chấm mỗi 3 số); ô nhập giá trong form sửa vẫn là số trơn |

## 7j. Trang User có tab dưới (UP12)

| # | Thao tác | Kết quả mong đợi |
|---|---|---|
| 7j.1 | Đăng nhập `user` | Có thanh tab dưới 3 tab **Trang chủ / Marketplace / Tài khoản**, mở ở tab Trang chủ; mỗi tab có tiêu đề AppBar riêng, AppBar không còn nút đăng xuất / vân tay |
| 7j.2 | Trang chủ → bấm **Xem Marketplace** | Chuyển sang tab Marketplace, danh sách sản phẩm như trước (ảnh, giá, Hết hàng, bấm vào xem chi tiết, kéo để tải lại) |
| 7j.3 | Ở Marketplace cuộn xuống giữa danh sách → sang tab khác → quay lại | Vẫn ở vị trí cũ, không hiện vòng tải lại |
| 7j.4 | Tab **Tài khoản** | Avatar tròn chữ cái đầu, đúng tên đăng nhập, "Vai trò: User"; máy đã bật vân tay thì có dòng **Tắt đăng nhập vân tay** (bấm → xác nhận → dòng biến mất + SnackBar) |
| 7j.5 | Tài khoản → **Đăng xuất** → xác nhận | Về màn Đăng nhập, bấm Back không quay lại được; đăng nhập lại / mở lại app vẫn vào đúng trang theo role (BT3) |
| 7j.6 | Đăng nhập `admin` | Vẫn vào Trang Admin như cũ (nút vân tay / đăng xuất trên AppBar) |

## 7k. Marketplace dạng lưới + tìm kiếm + lọc + sắp xếp (UP13)

| # | Thao tác | Kết quả mong đợi |
|---|---|---|
| 7k.1 | Đăng nhập `user` → tab **Marketplace** | Lưới 2 cột: ảnh, tên (tối đa 2 dòng), giá `x.xxx.xxx đ` màu xanh đậm, tồn kho; sản phẩm số lượng 0 có ảnh mờ + nhãn đỏ **Hết hàng**; dòng "n sản phẩm · Mới nhất" |
| 7k.2 | Gõ `chuot` rồi `IPHONE` vào ô tìm kiếm | Ra đúng sản phẩm có "Chuột…" / "iPhone…" (không phân biệt hoa thường, bỏ dấu); nút X xóa chữ hiện lại tất cả |
| 7k.3 | Bấm chip một danh mục, rồi **Chưa phân loại**, rồi **Tất cả** | Chỉ còn sản phẩm của danh mục đó / sản phẩm chưa có danh mục / tất cả |
| 7k.4 | Nút sắp xếp (góc phải AppBar) → Giá tăng dần / Giá giảm dần / Tên A→Z / Mới nhất | Lưới sắp xếp đúng thứ tự; mục đang chọn có dấu tích |
| 7k.5 | Gõ `zzzz` | "Không tìm thấy sản phẩm" + nút **Xóa bộ lọc** → bấm thì hiện lại tất cả |
| 7k.6 | Kéo xuống để tải lại; tắt backend rồi kéo | Có vòng tải, tải lại cả sản phẩm + danh mục; backend tắt thì hiện lỗi, bật lại kéo tiếp là có dữ liệu |
| 7k.7 | Bấm một ô sản phẩm | Mở màn Chi tiết sản phẩm như UP9 |

## 7l. Trang chủ (UP14)

| # | Thao tác | Kết quả mong đợi |
|---|---|---|
| 7l.1 | Đăng nhập `user` → tab **Trang chủ** | "Xin chào, user" + "Hôm nay bạn muốn mua gì?", ô tìm kiếm, banner xanh **Hàng mới về — Xem ngay →**, hàng danh mục tròn (Điện thoại 📱, Laptop 💻, Phụ kiện 🎧, khác icon danh mục), "Sản phẩm mới" (tối đa 6, cuộn ngang, mới nhất trước) |
| 7l.2 | Có sản phẩm số lượng 1–5 | Mục **Sắp hết hàng**: ảnh nhỏ, tên, giá, chữ đỏ "Chỉ còn n" (ít nhất lên trước); không có sản phẩm nào như vậy thì mục bị ẩn; sản phẩm hết hàng (0) không nằm ở đây |
| 7l.3 | Bấm một danh mục | Sang tab Marketplace, chip danh mục đó đang chọn, chỉ còn sản phẩm của danh mục đó |
| 7l.4 | Gõ `iphone` vào ô tìm kiếm Trang chủ → Enter | Sang Marketplace, ô tìm đã điền `iphone`, đã lọc; ô ở Trang chủ được xóa trắng |
| 7l.5 | Bấm **Xem tất cả** / bấm banner | Sang Marketplace, bỏ hết bộ lọc; banner thì sắp xếp **Mới nhất** |
| 7l.6 | Bấm một sản phẩm ở "Sản phẩm mới" hoặc "Sắp hết hàng" | Mở màn Chi tiết sản phẩm |
| 7l.7 | Admin thêm sản phẩm mới → User kéo xuống tải lại Trang chủ | Sản phẩm mới hiện đầu "Sản phẩm mới"; tắt backend rồi kéo thì hiện lỗi, bật lại kéo tiếp là có dữ liệu |

## 7m. Phân quyền Admin / Manager / Employee / User + Admin đổi role (UP15)

| Role | Vào trang | Được làm |
|---|---|---|
| User | Trang chủ / Marketplace / Tài khoản | Xem hàng (khách) |
| Employee | **Trang Nhân viên** | Chỉ xem sản phẩm, tồn kho, danh mục |
| Manager | **Trang Quản lý** | Thêm / sửa / xóa sản phẩm, danh mục, upload ảnh; không vào Quản lý tài khoản |
| Admin | Trang Admin | Như Manager + Quản lý tài khoản (khóa, buộc đăng xuất, đổi role) |

| # | Thao tác | Kết quả mong đợi |
|---|---|---|
| 7m.1 | `admin` → Quản lý tài khoản | Dòng User có thêm nút **Đổi role**; dòng `admin` không có nút nào |
| 7m.2 | Bấm Đổi role ở `hacker` | Hộp chọn Manager / Employee / User (không có Admin), role hiện tại được đánh dấu |
| 7m.3 | Chọn **Employee** | SnackBar "Đã đổi ... thành Employee (phải đăng nhập lại)", dòng hiện "Role: Employee" |
| 7m.4 | `hacker` đang đăng nhập (máy khác) kéo tải lại | Về màn Đăng nhập (token cũ bị thu hồi, như 7c.2) |
| 7m.5 | Đăng nhập `hacker` (Employee) | **Trang Nhân viên**: chỉ có nút 👁; không có Thêm / Sửa / Xóa, không có Quản lý tài khoản; bấm dòng → Chi tiết; icon danh mục → màn "Danh mục" không có nút sửa / xóa / + |
| 7m.6 | Admin đổi `hacker` thành **Manager** → đăng nhập `hacker` | **Trang Quản lý**: có Thêm / Sửa / Xóa, Quản lý danh mục; **không** có Quản lý tài khoản |
| 7m.7 | Swagger token Employee: `POST /api/Products`, `DELETE /api/Categories/1` | `403` |
| 7m.8 | Swagger token Manager: `POST /api/Products` | `201`; `GET /api/Users` → `403` |
| 7m.9 | Swagger token Admin: `POST /api/Users/{id}/role` `{ "role": "Admin" }` / đổi role của `admin` | `400` "Role chỉ được là Manager, Employee hoặc User" / "Không thể đổi role tài khoản Admin" |

Xong thì đổi `hacker` về **User** để mục 7b vẫn đúng. Mua hàng (giỏ hàng) chưa có, làm ở bước sau.

## 8. Kiểm tra code trước khi nộp

```bash
dotnet build backend
```

```bash
cd mobile && flutter pub get && flutter analyze
```

Kết quả đúng: build `0 Error(s)`, analyze `No issues found!`.
