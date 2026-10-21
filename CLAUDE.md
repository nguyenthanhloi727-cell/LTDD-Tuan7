# CLAUDE.md — LTDD Tuần 7

Trả lời bằng tiếng Việt, ngắn gọn. Kế hoạch, tiến độ và nhật ký nằm trong `PROGRESS.md`.
Người dùng sẽ gõ **"làm bước tiếp theo"** hoặc **"làm bước <mã bước>"** (mã bước xem trong `PROGRESS.md`).
Luật dưới đây áp dụng cho MỌI yêu cầu trong repo này, kể cả việc lẻ ngoài kế hoạch (khi đó bỏ qua luật 1 và luật 11, các luật còn lại vẫn giữ).

## Ngữ cảnh project

- `backend/`: ASP.NET Core 8 Web API, EF Core + SQL Server, Identity, JWT. Mở bằng Visual Studio.
- `mobile/`: Flutter, chạy bằng Android Studio, emulator gọi API qua `http://10.0.2.2:<port>`.
- Code tuần 6 đã có: model Product, API sản phẩm, giao diện danh sách sản phẩm.
- Bài tuần 7 (trên lớp) gồm: Identity + JWT + role Admin/User, Flutter có flutter_dotenv, jwt_decoder, shared_preferences, LoginScreen, RegisterScreen, MainScreen (trang User), trang Admin, tự đăng nhập bằng token.
- Bài tập là bài cá nhân, chấm tại lớp. Ưu tiên chạy đúng, code dễ giải thích khi thầy hỏi.

## Luật làm việc (bắt buộc)

1. Mỗi lần chỉ làm **1 bước**: bước đầu tiên còn `[ ]` trong mục Tiến độ của `PROGRESS.md`, hoặc bước người dùng chỉ định.
2. Trước khi sửa: đọc code liên quan, nói ngắn gọn sẽ sửa file/hàm nào. Phần nào đã có và chạy đúng thì **không viết lại**.
3. Chỉ sửa phần cần cho bước đó. Không đổi tên app, không đổi package name, không xóa code đang chạy được, không nâng version package khi bước không yêu cầu.
4. Sửa xong phải tự kiểm tra bằng lệnh:
   - Backend: `dotnet build backend` (không lỗi).
   - Mobile: `cd mobile && flutter pub get && flutter analyze` (không có error; warning có sẵn từ trước thì bỏ qua).
5. Sau đó **DỪNG**, in phần "Người dùng tự kiểm tra" của bước đó, chờ người dùng trả lời `ok`.
   Không tự commit trước khi người dùng nói `ok`.
6. Khi người dùng nói `ok`:
   - Đổi `[ ]` thành `[x]` cho bước đó và ghi Nhật ký (luật 11).
   - `git add` đúng thư mục của bước + `PROGRESS.md` → `git commit -m "<message của bước>"` → `git push`. Code, tiến độ và nhật ký nằm chung 1 commit.
7. Migration: Claude Code không mở được Package Manager Console của Visual Studio, nên dùng `dotnet ef`:
   - Chưa có tool thì chạy: `dotnet tool install --global dotnet-ef --version 8.*`
   - Project cần gói `Microsoft.EntityFrameworkCore.Design` bản 8.x.
   - Lệnh: `dotnet ef migrations add <Ten> --project backend/<ProjectApi>` và `dotnet ef database update --project backend/<ProjectApi>`.
8. Không commit: `bin/`, `obj/`, `.vs/`, `build/`, `.dart_tool/`, mật khẩu thật. File `mobile/.env` chỉ chứa BASE_URL nên **được commit** (đã khai trong assets, thiếu thì app không build).
9. Lỗi push (chưa đăng nhập GitHub, sai remote) thì dừng lại, báo lỗi nguyên văn, không tự đổi remote.
10. Tiết kiệm token: mỗi bước chạy trong 1 phiên mới (hoặc sau `/clear`). Đầu phiên, trong `PROGRESS.md` chỉ đọc mục 1 "Tiến độ", mục 3 "Nhật ký bàn giao" và **đúng phần của bước đang làm** trong mục 2. Không đọc phần của bước khác, không quét toàn repo; chỉ mở file mà Nhật ký hoặc bước hiện tại nhắc tới.
11. Trước khi commit, thêm 3–5 dòng vào mục 3 "Nhật ký bàn giao" của `PROGRESS.md`: file/hàm đã tạo hoặc sửa, tên key/biến quan trọng, việc còn dở hoặc lưu ý cho bước sau. Nhật ký được commit cùng code của bước (nhớ `git add PROGRESS.md`).
12. Chỉ 1 phiên làm việc trong folder tại một thời điểm. Không chạy 2 phiên song song (các bước phụ thuộc nhau và dùng chung git index).
