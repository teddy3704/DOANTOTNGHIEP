# Đối chiếu báo cáo nhóm với hệ thống đang chạy

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
