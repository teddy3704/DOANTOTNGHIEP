# Kịch bản báo cáo 6–8 phút

1. **LMS chính thức — 40 giây.** Mở https://lms.dlu.edu.vn/. “Đây là hệ thống
   nguồn. Ứng dụng hỗ trợ học tập, không thay thế LMS của trường.” Không yêu cầu
   trình chiếu password, cookie hoặc thông tin học tập cá nhân.
2. **Database-first — 90 giây.** pgAdmin kết nối Neon hiện hữu. Chạy
   `01_verify_database_baseline.sql`. Nêu đúng baseline đang chạy: lms 22 bảng,
   10 view. Mô hình nhóm 3 schema/39 bảng là đầu vào mở rộng, chưa deploy vào
   baseline này. Không hiển thị app/derived như thể đã tồn tại.
3. **Quan hệ và read model — 60 giây.** Chạy các SELECT trong
   `02_council_database_demo.sql`: role/context khác enrolment; module instance
   đa hình; Student course/progress và Teacher roster view. Nhấn mạnh view SQL
   Teacher hiện có không đồng nghĩa đã có Teacher API.
4. **Một backend — 40 giây.** Mở Render `/health` và `/docs`. Giới thiệu
   Node/Fastify + PostgreSQL read-only. Xem endpoint courses/assignments/progress
   với header demo Student được mô tả trong Swagger; không dùng DLU credential.
5. **Student — 90 giây.** Chọn SV001 → Home → Courses → Course Detail →
   Assignment → nhắc việc → Progress → Profile. Thử “Nộp bài trên LMS”, chỉ mở
   trang chính thức; chưa có mapping deep link hoạt động cụ thể.
6. **Teacher — 70 giây.** Đổi dữ liệu mô phỏng → GV001 → Home → Courses →
   Work → Calendar → Profile → “Chấm bài trên LMS”. Dữ liệu giảng viên là fixture
   chỉ đọc có phạm vi course/context, chưa đồng bộ với Student API. Không nhập điểm.
7. **Ranh giới và bước tiếp — 40 giây.** “Ứng dụng không xây dựng lại LMS của
   Trường Đại học Đà Lạt. Nhóm phân tích dữ liệu Moodle trước, xây dựng lớp dữ liệu
   và API phục vụ Mobile, sau đó cung cấp trải nghiệm hỗ trợ sinh viên và giảng
   viên. Nộp bài, làm bài kiểm tra, chấm điểm và quản lý học phần vẫn trên LMS.”
   Production cần DLU xác nhận cơ chế đăng nhập/Web Services và dữ liệu kiểm thử.

Nếu mạng chậm: mở bộ ảnh runtime và OpenAPI local, không tuyên bố Student đang
online. Không giới thiệu AI, grading Mobile, Teacher API hoặc 39-table deployment
chưa có. Xem `docs/REPORT_ALIGNMENT_NOTES.md` trước khi chỉnh Word/slide.
