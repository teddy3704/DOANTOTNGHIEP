# Kiến trúc ĐLU LMS Support — một trang

**Mục tiêu.** Giúp sinh viên theo dõi học phần, bài cần làm, tiến độ, điểm đã có và nhắc việc; giúp giảng viên xem lớp, công việc và sinh viên cần hỗ trợ. Không thay LMS chính thức.

**Database First.** Nhóm phân tích các quan hệ Moodle trước khi làm màn hình. Mô hình development/staging PostgreSQL có `lms` (35 bảng dữ liệu học tập), `app` (4 bảng dữ liệu hỗ trợ do Mobile sở hữu) và `derived` (20 view đọc/tổng hợp). Tổng 39 bảng vật lý, 39 PK, 38 FK, 548 cột. Dữ liệu là mẫu, không phải CSDL DLU production.

**Luồng đang chạy.** `Flutter → HTTPS → Render staging → Node.js/TypeScript/Fastify API → PostgreSQL lms/app/derived`. Student và Teacher dùng cùng nguồn, GET có kiểm tra phạm vi; Teacher API không ghi điểm hoặc sửa LMS. Flutter không nối PostgreSQL trực tiếp.

**Ranh giới LMS.** Nộp bài, quiz, chấm điểm, phản hồi học vụ, quản trị học phần và xác thực chính thức ở [lms.dlu.edu.vn](https://lms.dlu.edu.vn/). Mobile chỉ mở link LMS an toàn, không tự thực hiện các nghiệp vụ đó.

**Production.** DLU Authentication và Web Services phải được Trường xác nhận. Khi được cấp cơ chế hợp lệ, thay adapter nguồn dữ liệu ở backend, xác minh quyền server-side; không tuyên bố staging là production.

**Câu chốt.** “Nhóm không xây lại LMS; nhóm dùng Database First và một API tách biệt để tạo trải nghiệm Mobile hỗ trợ sinh viên, giảng viên, còn nghiệp vụ học vụ chính thức ở LMS của Trường.”
