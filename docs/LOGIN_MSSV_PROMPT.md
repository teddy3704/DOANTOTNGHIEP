# L — Đăng nhập bằng mã số sinh viên (giống LMS của trường)

Phiên cloud soạn ngày 10/11/2026, owner yêu cầu. Phiên native làm **sau khi xong FINAL-F5** (video), trước F7. Mọi quy tắc của FINAL và EXECUTION_RULES vẫn áp dụng: gate, RESUME_STATE, commit cục bộ, không push.

## Mục tiêu

Bỏ màn "Chọn vai trò" (đăng nhập thử nghiệm) khỏi luồng chính. Thay bằng màn đăng nhập giống lms.dlu.edu.vn:
- **Tên đăng nhập:** sinh viên dùng mã số sinh viên, giảng viên dùng tên tài khoản.
- **Mật khẩu.**
- Vai trò do máy chủ tự xác định theo tài khoản.

## Sự thật về dữ liệu (đã kiểm tra)

- MSSV của sinh viên nằm ở `lms.user.idnumber` (dạng 7 chữ số như của trường). Ví dụ user 205 Hoang Giang có MSSV **2312005**; các SV khác: 2212001…2412008.
- Giảng viên không có idnumber, nên đăng nhập bằng `username` (ví dụ `teacher02` là GV 102).
- Cột `lms.user.password` trong bản dump là chuỗi giả `mock_password`. **Không dùng cột này.**
- MSSV thật của thành viên nhóm (ví dụ 2212472) **không có** trong dữ liệu mẫu. Không ánh xạ MSSV thật vào tài khoản mẫu, vì làm vậy là gán sai danh tính.

## Thiết kế (không cần DDL)

1. **`AuthProvider`** (interface) có hai cài đặt.
   - **`LocalCredentialProvider`** (bật trong demo):
     - Thông tin đăng nhập demo đọc từ `.local\backend.json` (đã git-ignore), mỗi mục gồm `{login, userId, role, bcrypt}`.
     - So mật khẩu bằng BCrypt (cost 12), dùng thư viện có sẵn của Spring Security.
     - Không lưu mật khẩu thô ở bất kỳ đâu.
   - **`MoodleTokenProvider`** (TẮT mặc định, chỉ test bằng `MockRestServiceServer`):
     - Luồng giống ứng dụng Moodle chính thức: `POST {lmsBaseUrl}/login/token.php` với `service=moodle_mobile_app`, rồi gọi `core_webservice_get_site_info` để lấy username và userid.
     - **KHÔNG gọi thử vào lms.dlu.edu.vn** khi chưa có văn bản cho phép của Trường.
     - Ghi rõ trong docs: triển khai thật chỉ cần bật provider này. MSSV lấy từ tài khoản đã xác thực, nhờ vậy ánh xạ Portal không còn phải cấu hình tay.
2. **API `POST /api/v1/auth/login`** với body `{login, password}` → trả JWT giống hiện tại (issuer, audience, sub là userId, role).
   - Sai thì trả **một thông báo chung**: "Mã số hoặc mật khẩu không đúng" (không lộ tài khoản nào tồn tại).
   - **Chống dò mật khẩu:** sai 5 lần trong 15 phút cho cùng một login (và cùng IP) thì trả 429 kèm `Retry-After`. Lưu trong bộ nhớ là đủ.
   - Thời gian xử lý như nhau dù tài khoản có hay không: khi không có tài khoản vẫn so một hash giả.
   - Không ghi login hay mật khẩu vào log. Chỉ log: kết quả (OK/FAIL/LOCKED), userId khi OK, độ dài login.
   - Validate: login dài 1–64 ký tự, mật khẩu 1–128 ký tự, body lớn thì từ chối.
3. **`demo-login` cũ** chỉ còn dùng khi bật cờ `local-development` để dự phòng ngày bảo vệ. Ẩn khỏi giao diện chính; chỉ mở được bằng một nút nhỏ "Chế độ demo" trong màn đăng nhập khi app build ở chế độ local.
4. **Script owner `tools\Set-DemoPasswords.ps1`**
   - Mật khẩu nhập bằng `Read-Host -AsSecureString`.
   - Băm BCrypt bằng chính backend (một lệnh CLI nhỏ trong JAR hoặc test helper), **không** băm bằng PowerShell tự viết.
   - Ghi vào `.local\backend.json` cho ba tài khoản: SV 205 (`2312005`), SV 201 (`2212001`) để thử phân quyền, GV 102 (`teacher02`).
   - In bản tóm tắt đã che: chỉ login và role.
   - Phiên native tự đặt mật khẩu demo tạm để test, rồi ghi vào HANDOFF là owner cần đặt lại bằng script.

## Giao diện Flutter

- **Màn "Đăng nhập"**
  - Theo theme hiện có. Logo "Hỗ trợ học tập LMS" và dòng phụ "Dùng tài khoản LMS của trường".
  - Ô "Mã số sinh viên / Tên đăng nhập" (bàn phím chữ và số, tự bỏ khoảng trắng) và ô "Mật khẩu" có nút hiện/ẩn.
  - Nút "Đăng nhập" có trạng thái đang tải.
  - Lỗi hiện ngay dưới form: sai thông tin, bị khóa tạm (còn bao nhiêu phút), mất mạng.
- **"Ghi nhớ mã số":** chỉ lưu login trên máy. Không bao giờ lưu mật khẩu; token vẫn chỉ giữ trong bộ nhớ như hiện tại.
- **Sau khi đăng nhập:** server trả role nào thì vào thẳng giao diện sinh viên hoặc giảng viên, không còn bước chọn vai trò. Giới thiệu 3 bước (N18) vẫn hiện lần đầu.
- **Đăng xuất** (trong menu): xóa token, cache ngoại tuyến (N11) và lịch nhắc của phiên đó.
- **Hỗ trợ khác:** đáp ứng chế độ tối, cỡ chữ 1.3, chiều rộng 320 dp; có nhãn Semantics.

## Test bắt buộc

**Backend:**
- Đăng nhập đúng cho SV và cho GV; JWT có đúng sub và role.
- Sai mật khẩu, tài khoản không tồn tại: cùng thông báo, cùng mã 401.
- Bị khóa sau 5 lần sai (429), mở lại sau 15 phút (dùng fake clock).
- Body thiếu trường hoặc quá dài: 400.
- Log không chứa mật khẩu (test bắt log).
- `demo-login` bị tắt khi không có cờ local.
- Token từ đăng nhập mới đi qua PathIdentity như cũ: SV 2212001 gọi dữ liệu của 205 thì bị 403.
- `MoodleTokenProvider` với mock: token hợp lệ, sai mật khẩu, web service bị tắt.

**Flutter:** form validate; đúng thì vào màn theo role; sai thì hiện lỗi; khóa tạm; hiện/ẩn mật khẩu; ghi nhớ mã số không lưu mật khẩu; đăng xuất xóa sạch.

## Chạy thật và cập nhật

1. Gate backend và Flutter; build APK.
2. Trên emulator: đăng nhập `2312005` vào giao diện sinh viên; `teacher02` vào giao diện giảng viên; sai 5 lần thì bị khóa; `2212001` không xem được dữ liệu của 205. Chụp ảnh `login-01..05`.
3. Cập nhật `DEMO_SCRIPT.md` (bước mở đầu là đăng nhập bằng MSSV), `USER_GUIDE.md`, `FEATURES_V3.md` (mục Đăng nhập), sơ đồ `04-seq-auth.mmd`.
4. **Quay lại đoạn video mở đầu** của F5 cho có màn đăng nhập. Không cần quay lại cả bộ.
5. Đóng gói lại bản cuối F3: APK và JAR mới kèm SHA-256, ghi `RELEASE_NOTES`. Sau đó mới làm F7 (tag).
