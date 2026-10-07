# Đối chiếu báo cáo nhóm với hệ thống đang chạy

## Phần mở rộng innovation — 06/10/2026 (product/runtime PASS)

Phần mới không còn chỉ là màn hình xem LMS: sinh viên có ưu tiên có giải thích
và kế hoạch học cá nhân; giảng viên có danh sách cần chú ý, ghi nhận hỗ trợ và
lịch sử theo dõi. Đây là **rule-based decision support**, không AI, không dự báo
kết quả học vụ. Chỉ dùng trường API đã có; không suy đoán chuyên cần, không hoạt
động hoặc điểm thấp từ dữ liệu thiếu.

Bổ sung ba bảng `app.*` cho plan/intervention/follow-up, không dựng backend thứ
hai và không đổi 35 bảng `lms` hay 20 derived views. Candidate migration đã apply
sau rehearsal/rollback PASS: **3 schema, 42 bảng (35 lms + 7 app), 20 views,
42 PK, 45 FK, 588 cột**; original rows/lms columns/view definitions không đổi.
Backend 82 tests, local real API 181 checks, public regression 165 checks PASS.
Render `a0c2cb7` Live chỉ từ nhánh innovation, environment/database secret không
đổi. Flutter format/analyze/224 tests PASS (1 opt-in skipped, separately PASS);
responsive UI PASS ở 320/390px, text scale 1.3, form validation đã sửa/test.
APK cuối rebuilt/cài/relaunch thành công. Student plan create/edit/postpone/
handled/restore PASS; notification delivered 17:22, handled cancels alarm.
Teacher action → follow-up → resolved/history persist sau restart PASS; đổi
SV001/SV002/GV001 không lẫn scope. 15 ảnh thật ở `evidence/mobile/innovation-final/`.
Final candidate/index secret scan và diff check PASS. Commit/push receipt bàn
giao riêng; lấy exact hash từ Git, không dùng hash dự kiến trong báo cáo.
Số 39/20 trong Word và phần dưới là baseline lịch sử; không trộn với extension.

Khi biên tập báo cáo, phân biệt: học vụ đọc staging từ dữ liệu mẫu; thao tác ghi
thuộc ứng dụng; nộp bài/quiz/chấm điểm chính thức ở DLU LMS. “Đã xử lý” trong kế
hoạch không có nghĩa “đã nộp”; “đã kết thúc hỗ trợ” không có nghĩa đã cải thiện
điểm. Snapshot chỉ so sánh quan sát nguồn trước/sau, không chứng minh quan hệ
nhân quả. DLU auth/Web Services vẫn **TO_VERIFY_DLU**.

Word nguồn được giữ nguyên. Dùng `PRODUCT_DIFFERENTIATION.md`,
`REVIEWER_FEEDBACK_RESPONSE.md`, `PRESENTATION_UPDATE_PLAN.md` và
`INNOVATION_ARCHITECTURE.md` để cập nhật phần đóng góp/kiến trúc đã được kiểm tra;
screenshot lịch sử vẫn cần nhãn lịch sử, không dùng làm bằng chứng workflow
mới. Các phần dưới là checkpoint đã đóng trước innovation.

## Bản chốt hội đồng — 23/09/2026

Hai Word nguồn được giữ nguyên. Ma trận vị trí/câu thay thế nằm ở `docs/council/REPORT_CORRECTION_MATRIX.md`; bản sao DOCX đã sửa kỹ thuật ở `D:\DLU-LMS-FINAL-DEMO\05_REPORT\revised`. Số liệu hiện hành: GROUP_39_20 (3 schema, 39 bảng gồm 35 `lms` + 4 `app`, 20 view, 39 PK, 38 FK, 548 cột); backend Node.js/TypeScript/Fastify trên Render; Student và Teacher API thật chỉ đọc; Flutter 167 test và backend 54 test PASS. Word gốc từng nêu Spring Boot/JdbcTemplate/localhost:8080 và ảnh MVP cũ; các nội dung đó **không** mô tả runtime cuối. Bản Word sửa giữ ảnh MVP cũ nhưng gắn nhãn lịch sử; ảnh runtime cuối ở `evidence/mobile/group39-20-final/`.

DLU Auth/Web Services = `TO_VERIFY_DLU`; thông báo Android fire = `NOT_VERIFIED`; nộp bài, quiz, chấm điểm, quản trị = LMS ONLY. Các section phía dưới là nhật ký các checkpoint cũ, không được trích làm hiện trạng.

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
