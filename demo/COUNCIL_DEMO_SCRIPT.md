# Kịch bản báo cáo 6–8 phút — LMS Support

1. **LMS chính thức — 40 giây.** Mở https://lms.dlu.edu.vn/. “Đây là hệ thống
   nguồn và nơi thực hiện nghiệp vụ chính thức; Mobile không thay thế LMS.”
2. **Database-first — 90 giây.** Trên kết nối Neon candidate đã lưu trong pgAdmin,
   chạy 01_verify_database_baseline.sql. Giới thiệu lms/app/derived, 39 bảng và 20 view.
   Đây là mô hình Moodle-oriented phát triển/staging từ schema nhóm, không phải
   database production hay hồ sơ thật của DLU.
3. **Quan hệ/read model — 60 giây.** Chạy 02_council_database_demo.sql: role gắn
   context khác enrolment; module instance đa hình; Student overview và Teacher
   monitoring. Chỉ báo hỗ trợ dựa trên quy tắc, không AI hoặc quyết định học vụ.
4. **Backend — 40 giây.** Render /health và /docs: Node.js/TypeScript/Fastify,
   PostgreSQL và GET-only API. Hai vai trò dùng cùng nguồn staging, có lọc phạm vi.
5. **Student — 90 giây.** Hồ sơ mẫu SV001 → Home → Courses → Detail → Assignment →
   Progress → Grades → Profile. “Nộp bài trên LMS” mở LMS, không nộp bài.
6. **Teacher — 80 giây.** Hồ sơ mẫu GV001 → Home → Teaching Course → Theo dõi sinh viên
   (tìm tên, mở thẻ tiến độ) → Work → Calendar → Profile.
   Teacher đọc API Render, không fixture; “Chấm bài trên LMS” chỉ mở hệ thống nguồn.
7. **Ranh giới — 40 giây.** Nộp bài, quiz, chấm điểm, phản hồi học vụ và quản trị
   học phần vẫn thuộc LMS. Mobile chỉ hỗ trợ theo dõi và lời nhắc cá nhân.
   DLU cần xác nhận cơ chế định danh/Web Services trước tích hợp production.

Khi mạng yếu: dùng ảnh runtime/contract offline, không tuyên bố đang truy cập live.
Deep link chỉ dùng đích đã xác minh hoặc trang LMS chung; không bịa Moodle ID.
Không trình chiếu secret. Bản Word cũ Spring Boot/JdbcTemplate cần sửa theo
docs/REPORT_ALIGNMENT_NOTES.md; bản gốc nhóm được giữ nguyên.
