# Bảo mật và ranh giới hệ thống

- Flutter không có connection string PostgreSQL và không kết nối DB trực tiếp. Credential nằm ở cấu hình server-side của staging; `.env`/`.env.candidate` bị Git ignore. Không đưa credential vào Postman export, ảnh hoặc bộ bàn giao.
- Identity mẫu SV/GV bằng header chỉ dành cho development/staging với dữ liệu tổng hợp. Đây **không phải** DLU Authentication. Giá trị mật khẩu giả trong seed đã bị vô hiệu hóa và không dùng làm xác thực; không lưu mật khẩu DLU trong APK hay tài liệu.
- Student API chỉ trả dữ liệu thuộc identity được chọn; Teacher API GET chỉ lấy course được gán, học viên trong course đó. Test đã kiểm tra thiếu/mixed identity trả 401, override không hợp lệ trả 400 và cross-course trả 404. Cơ chế này không đủ cho production nếu chưa thay bằng identity/capability DLU được phê duyệt.
- API Student/Teacher hỗ trợ đọc; không có Mobile submit, quiz submit, grade write hoặc course admin. Link “Nộp bài trên LMS”, “Chấm bài trên LMS” và “Mở LMS” mở host HTTPS chính thức, không gửi dữ liệu học vụ vào staging.
- Dữ liệu PostgreSQL hiện là synthetic/development. Không clone dữ liệu sản xuất DLU vào Neon/Supabase và không tự động fallback fixture nếu production integration lỗi.
- DLU Auth/Web Services đang `TO_VERIFY_DLU`; chỉ sau xác nhận của Nhà trường mới có thể thiết kế adapter sản xuất và kiểm tra capability bằng tài khoản test được cấp.

**Nếu hội đồng hỏi “đã an toàn production chưa?”** Trả lời: chưa; bản hiện tại là staging demo dùng dữ liệu mẫu. Ranh giới, kiểm thử isolation và không lộ secret đã có, nhưng production cần identity/capability, vận hành, bảo mật và phê duyệt chính thức.
