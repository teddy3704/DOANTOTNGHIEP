# Đối chiếu báo cáo nhóm với hệ thống đang chạy

## Trạng thái hiện hành — 22/09/2026 (thay thế các checkpoint cũ bên dưới)

- Render đã dùng GROUP_39_20: **3 schema, 39 bảng vật lý (35 lms + 4 app),
  20 derived views, 39 PK, 38 FK, 548 cột vật lý**. Không còn phục vụ baseline 22/10.
- Backend hiện hành: **Node.js / TypeScript / Fastify / PostgreSQL / Render**,
  không Spring Boot hay JdbcTemplate. Backend 54 tests PASS ở checkpoint đã duyệt.
- Student và Teacher đều đọc API thật từ cùng database staging. Teacher Flutter
  dùng `TeacherSupportApiRepository`, không fixture hay fallback khi lỗi.
- Database vẫn là **Moodle-oriented PostgreSQL development/staging model** với
  dữ liệu mẫu, không phải database production hoặc hồ sơ thật DLU.
- Chỉ báo hỗ trợ là **rule-based heuristic**, không dự báo AI, không quyết định học vụ.
- DLU Authentication / Web Services = **TO_VERIFY_DLU**. Nộp bài, quiz, chấm điểm,
  phản hồi học vụ và quản trị chỉ thực hiện trên LMS. Link Mobile chỉ mở host
  chính thức; không ghép Moodle ID từ ID staging.
- Nhắc việc là dữ liệu cục bộ thuộc ứng dụng, chưa đồng bộ qua app.* của Neon.
- Kết quả Mobile cuối và giới hạn thông báo: `FLUTTER_TEST_RESULT.md`.
  Word gốc được giữ nguyên; dùng mục này để sửa nội dung báo cáo khi biên tập.

Các mục bên dưới ghi lại lịch sử đối chiếu, không mô tả bản staging hiện tại.

## Kết quả mới nhất — candidate đã chạy thật

Candidate đã restore và catalog xác nhận **3 schema, 39 bảng, 20 views, 39 PK,
38 FK, 548 cột**; các view Student/Teacher và app.* được truy vấn thật. Đây là
**mô hình Moodle-oriented development**, không phải CSDL production DLU.
Node/Fastify đã có adapter Student giữ contract và API Teacher chỉ đọc, kiểm thử
HTTP local cùng candidate PASS; backend 54 tests PASS. Render vẫn 22/10, chưa
switch; Flutter Teacher vẫn fixture cho đến khi API Teacher đã deploy được xác
minh. Không gọi API local là API DLU hay Teacher Mobile tích hợp hoàn tất.

## Cập nhật 19/09 — đã nhận schema nhóm

Candidate đã có database rỗng riêng `lms_mobile_learning_candidate` và bản SQL
sanitized local; **chưa restore**. Các số 39/20 bên dưới vẫn chỉ là bằng chứng DDL,
không phải catalog runtime candidate. Cần cấu hình connection candidate riêng
cho CLI; không thay connection Render/current Neon.

DDL tại `D:\DoAnTotNghiep-group` xác nhận offline **3 schema, 39 bảng (35 lms +
4 app), 20 derived views, 39 PK, 38 FK, 548 cột**. `lms.user.password` cho phép
NULL. Các ghi chú “thiếu schema/chưa rõ nullability” bên dưới là lịch sử.
Candidate branch đã tạo nhưng **chưa restore/kiểm chứng runtime**; chưa chọn
39/20 làm baseline triển khai. Student vẫn dùng Render/22 bảng; Teacher vẫn dùng
fixture; backend vẫn Node/Fastify. Không sửa Word gốc. Xem
`DATABASE_MODEL_RECONCILIATION.md` để phân biệt bằng chứng offline và runtime.

Kiểm tra 18–19/09/2026, worktree `flutter-student-support-v1`. Hai Word gốc
trong Downloads được đọc để đối chiếu nội dung, không chỉnh sửa. Bộ 39 bảng trong
báo cáo là **đầu vào khác baseline đang phục vụ app**, không tự động thay Neon.

| Nội dung trong Word | Thực tế xác minh | Chỉnh báo cáo |
|---|---|---|
| 3 schema; 35 lms + 4 app; 20 derived views; 39 PK; 38 FK; 548 cột | Neon cấu hình hiện tại: **1 schema lms; 22 bảng; 0 app; 0 derived views; 10 lms views; 22 PK; 35 FK; 135 cột** | Tách “mô hình nhóm cung cấp” khỏi “baseline staging đã triển khai”; không gọi hai bộ là một database |
| Spring Boot, Java, JdbcTemplate; Controller → Service → Repository | **Node 24 / TypeScript / Fastify 5 / pg** tại `integration-api/`; `npm run build`, `npm start` | Sửa sơ đồ, công nghệ và mô tả backend hiện hành trong cả hai Word; không dựng backend thứ hai |
| localhost:8080 và adb reverse | API local mặc định 3000; app staging dùng HTTPS Render | Bỏ yêu cầu adb reverse 8080 của bản demo này |
| Student và Teacher cùng lấy API; Teacher monitoring/quiz/analytics đầy đủ | Student lấy Render; Teacher Home/Courses/Work/Calendar/Profile lấy fixture chỉ đọc, có kiểm tra role/context | Không gắn nhãn Teacher API PASS hoặc trình diễn analytics chưa có |
| derived.teacher_* và unified_tasks đang phục vụ Mobile | Không có schema derived trong Neon đang dùng; có `lms.vw_teacher_roster` và `vw_teacher_submission_overview` ở SQL | Hai view cũ chưa phải API. 7 view Teacher mới cần schema export và kế hoạch adapter/contract riêng trước khi triển khai |
| Database app.* giữ reminders | Bản Mobile hiện giữ metadata lời nhắc cục bộ, secure storage + Android notification | Không mô tả lời nhắc hiện tại đã đồng bộ lên Neon |
| Authentication/JWT là tiến độ tiếp theo | Staging chọn SV001/SV002/GV001, không password; production chưa cấu hình | DLU auth và Web Services = **TO_VERIFY_DLU**, đăng nhập website không chứng minh API |

Render `/health` trả 200, `status=ok`, `database=reachable` ngày 19/09;
service hiện hữu không bị redeploy. Student API, Swagger và Postman PASS trước đó
được giữ nguyên. Backend có một implementation hiện hành: **NODE_FASTIFY**.

Teacher API giữ **PARTIAL**: không nhập schema nhóm vào database đang chạy để ép
khớp báo cáo. Thay fixture cần contract Teacher, kiểm tra phạm vi server, adapter
và một deployment được kiểm thử; không chỉ đổi tên view hay bật quyền Student.

`lms.users` hiện tại **không có cột password**. SQL nhóm có 10 literal placeholder
`mock_password`; không được import hay dùng authentication. Bản sao backup đã
vô hiệu hóa trường password/secret của cả 18 user bằng marker không xác thực;
file gốc giữ nguyên. Nullability của schema nhóm chưa được kiểm chứng nên không
đổi cấu trúc hay chèn NULL một cách phỏng đoán.

Chỉ báo LOW/MEDIUM/HIGH trong tài liệu là **heuristic dựa trên quy tắc**, không AI.
Điểm/progress trong demo không phải học bạ chính thức. Caption ảnh cần ghi dữ liệu
mô phỏng; Teacher fixture khác nguồn Student Render, không giả đồng bộ hai nguồn.

Kết quả Flutter/APK mới nhất: `FLUTTER_TEST_RESULT.md`. Phạm vi chức năng:
`MOBILE_FEATURE_MATRIX.md`; truy vết: `TRACEABILITY_MATRIX.md`.
`lms_mobile_learning_schema.sql` của nhóm: **MISSING**. Bộ DDL baseline 22 bảng,
seed hiện tại, bản mock nhóm đã vô hiệu auth và OpenAPI đã sao lưu local; không
khẳng định đó là export schema 39 bảng còn thiếu.
