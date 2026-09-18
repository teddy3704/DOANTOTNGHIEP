# Kịch bản báo cáo integration — khoảng 8 phút

Phạm vi: **Student Support, database-first, development API chỉ đọc**. Không demo
Flutter ở phase này. Dữ liệu mẫu được sinh từ mô hình tham chiếu schema Moodle do
GVHD cung cấp; không phải dữ liệu sinh viên DLU thật.

## Chuẩn bị

Checkpoint 2026-09-17: local API và Postman Web đã PASS (17 requests / 85 assertions
qua Desktop Agent 0.5.1); fresh backend recheck 50 tests và 20 Neon checks PASS.
pgAdmin đã reconnect server Neon hiện có trong phiên này; ERD được xác minh ở
checkpoint trước theo người dùng. Không lấy credential từ trình duyệt/pgAdmin.

Render staging đã deploy từ `integration-api-render-staging` tại
`https://dlu-lms-student-support-staging.onrender.com`. Commit `e241f8a` là
nguồn đã xác minh; `/health`, `/docs`, `/openapi.json` đều HTTP 200. Independent
smoke 19/19 PASS và Postman staging 17 requests / 85 assertions, 0 errors.
`RENDER_STAGING_GATE=PASS`, `POSTMAN_STAGING_GATE=PASS`. Database secret do người
dùng nhập riêng ở Render và không hiển thị/đưa vào kịch bản. Flutter đã được
phê duyệt và phải bắt đầu ở worktree sạch để giữ nguyên các thay đổi local khác.

- Đọc `INTEGRATION_STATUS.md` và `API_TEST_RESULT.md`; chỉ trình diễn bước thực sự
  đã chạy được. Không dùng screenshot cũ để thay cho kết quả live.
- Khởi động API theo `integration-api/README.md`, kiểm tra health và Swagger.
- Chuẩn bị pgAdmin kết nối **chính Neon database**, không tạo database local.
- Đóng hộp thoại Connect, password, Environment secrets và `.env` trước khi chia
  sẻ màn hình/chụp ảnh. Không hiển thị connection string ở bất cứ bước nào.
- Nếu Postman Web cần Desktop Agent để gọi localhost, kiểm tra trước; nếu chưa
  dùng được, nói rõ giới hạn browser, không gọi đó là Postman PASS.

## Trình tự

| Thời lượng | Màn hình / thao tác | Nội dung nói ngắn gọn |
|---|---|---|
| 0:00–0:35 | Trang chính thức `https://lms.dlu.edu.vn/` | “Đây là LMS chính thức của Nhà trường và là nguồn dữ liệu chính.” Không dùng dữ liệu private để thay Web Services. |
| 0:35–1:20 | Neon: project `DLU-LMS-Mobile`, database `lms_mobile_learning`, schema `lms`; không mở Connect | “Đây là mô hình phát triển phục vụ phân tích và kiểm thử. Không phải database Moodle DLU production.” |
| 1:20–2:30 | pgAdmin: tables → fields/FK → views → ERD nếu đã có → truy vấn chỉ đọc SV001 | Giải thích một quan hệ user–ghi danh–course và một view sinh viên; đối chiếu kết quả database thực tế. Không chạy seed/migration hoặc write. |
| 2:30–3:15 | `TRACEABILITY_MATRIX.md`, chọn SV-01 và SV-07 | Chức năng → nguồn Moodle → PostgreSQL → view → API → future Mobile. Tách dữ liệu Moodle-owned khỏi app-owned. |
| 3:15–3:45 | `/health` | “Đây là Development Integration API. Kiểm tra này xác minh backend kết nối mô hình Neon, không xác minh Web Services DLU.” |
| 3:45–4:45 | `/docs`: courses, assignments, grades, progress | Chỉ GET student endpoints. Không có assignment submission, teacher grading hoặc upload endpoint. Deep-link chưa xác minh vẫn null. |
| 4:45–6:45 | Postman nếu đã kết nối: Health → Courses → Assignments → Grades → Progress → Deadlines → request thiếu header | Dùng synthetic SV001 đã có trong database. So sánh điểm/khóa học với pgAdmin. Bỏ header phải ra 401; header mẫu không phải production authentication. Nếu bị browser/agent block, trình bày bằng chứng local test và ghi đúng BLOCKED/PARTIAL, không giả chạy Web. |
| 6:45–7:15 | Render staging Live | Mở service staging đã xác minh, nhắc đây là development API chỉ đọc. Không push main hoặc hiển thị Render secrets. |
| 7:15–8:00 | `INTEGRATION_ARCHITECTURE.md` | “Bước tiếp theo là xác nhận cơ chế xác thực và Moodle Web Services với DLU rồi thay adapter dữ liệu. Không thử live rồi fallback sang mẫu.” |

## Điểm cần trả lời rõ

- Tại sao PostgreSQL? Mô hình học tập/phân tích có FK, views và dữ liệu mẫu kiểm thử
  độc lập; không kết luận Moodle DLU dùng PostgreSQL.
- Điểm/trạng thái lấy từ đâu? Trong demo này: Neon synthetic rows qua view. Sau
  tích hợp thật: Web Services có quyền đọc được DLU xác nhận.
- Sinh viên nộp bài ở đâu? LMS DLU. Mobile chỉ dự kiến mở deep-link được xác minh,
  không dựng hệ thống nộp bài/chấm điểm thay Moodle.
- Nhắc nhở? SV-10 là thiết kế app-owned, chưa có endpoint hoặc persistence đợt này.
- Flutter đã nối API chưa? Chưa trong phase này; đã được phê duyệt sau hai staging
  gates, không dùng API local PASS để khẳng định Mobile đã tích hợp.
- Supabase? Giữ foundation cũ, không tạo thêm service hoặc clone dữ liệu Moodle.

Kết luận trung thực: Postman local **và** Render/Postman staging đã PASS cho
development API chỉ đọc. Điều này không xác minh Moodle production. Xem
`ADVISOR_EVIDENCE_INDEX.md` để phân biệt ảnh local, staging và blocker lịch sử.
Production Moodle vẫn **TO_VERIFY_DLU**.
