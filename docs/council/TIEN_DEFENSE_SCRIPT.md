# Kịch bản bảo vệ cá nhân Phan Văn Tiến

## Trả lời ngắn khoảng 2 phút

“Phần em tập trung là phân tích cấu trúc Moodle theo hướng Database First và đưa kết quả đó vào trải nghiệm Student trên Flutter. Nhóm không tạo một LMS mới. Chúng em bắt đầu từ 35 bảng `lms` trong mô hình development, phân theo các nhóm như user, course, assignment, quiz, gradebook, completion và attendance. Em đặc biệt kiểm tra việc ghi danh khác với vai trò: `user_enrolments` cho biết ai tham gia học phần, còn `role_assignments` cùng `context` xác định vai trò trong ngữ cảnh.

Từ đó, 20 view `derived` tạo các read model; `unified_tasks` gộp assignment và quiz thành công việc để Student dễ xem, còn progress dựa trên dữ liệu completion chứ không đoán từ nút đã mở. Flutter gọi API qua HTTPS, không đọc PostgreSQL. Ở màn Student, em trình bày Home, course, bài tập, tiến độ, điểm và hồ sơ; nút nộp bài chuyển tới LMS chính thức, không nộp trong app.

Bản đã chạy với dữ liệu mẫu ở staging, Flutter 167 test PASS; đó chưa phải dữ liệu DLU thật. Để đưa vào production, Nhà trường cần xác nhận xác thực và Web Services; khi đó nhóm thay adapter nguồn dữ liệu và kiểm tra quyền, còn ranh giới nghiệp vụ LMS vẫn giữ nguyên.”

## Trình bày khoảng 5 phút

**0:00–0:45 — Bài toán.** “Trên điện thoại, người học cần thấy ngay học phần, việc đến hạn và tiến độ. Mục tiêu là một lớp hỗ trợ Mobile quanh LMS DLU, không thay phần nộp/chấm.” Chỉ LMS chính thức và sơ đồ kiến trúc.

**0:45–1:45 — Database First.** “Em đọc schema theo quan hệ thay vì học thuộc 35 tên bảng. Một user có thể có role khác nhau theo context; enrolment là tham gia course, không phải quyền chấm. Course đi qua sections/modules; `instance` của module có nghĩa theo loại.” Chỉ SQL schema hoặc tài liệu 35 bảng.

**1:45–2:40 — Read model.** “`unified_tasks` chuẩn hóa assign/quiz cho timeline. `student_course_progress` đọc completion; completion không tự chứng minh đã nộp. Grade view chỉ đọc điểm đã có, `null` khác 0. Attendance summary đến từ buổi và log chuyên cần; risk là quy tắc hỗ trợ, không AI.” Chạy truy vấn demo read-only.

**2:40–3:55 — Student Flutter.** Mở Student Home → Course → Assignment → Progress → Grades. “Màn hình không tự nối DB, dữ liệu qua Fastify API trên Render. Link ‘Nộp bài trên LMS’ trả về hệ thống chính thức.” Không gửi bài thật.

**3:55–4:30 — Kiểm chứng.** “Backend 54 test, Flutter 167 test và analyze PASS. Runtime Student/Teacher/đổi role và 15 ảnh đã ghi nhận. Teacher API là read-only thật, không còn fixture ở bản cuối.” Chỉ test report và ảnh.

**4:30–5:00 — Giới hạn.** “Đây là staging với dữ liệu mẫu. Auth và Web Services DLU cần Nhà trường xác minh; thông báo Android phát đúng giờ chưa có chứng cứ runtime do dataset không có hạn tương lai.”

## Trình bày chi tiết khoảng 8 phút

**0:00–1:00:** Mục tiêu sản phẩm, ranh giới với LMS và vai trò cá nhân trong nhóm. Vương phụ trách phạm vi/backend/E2E; Tiến phụ trách schema/mapping/mock data/Student Flutter; Luật phụ trách `lms`/`app`/`derived`, Teacher Flutter/analytics. Các thành viên có review chéo.

**1:00–2:30:** Dùng tài liệu 35 bảng theo domain để giải thích user/role/context, course/enrolment, section/module, assignment/quiz, gradebook, attendance và log. Nhấn 39 bảng vật lý là 35 `lms` + 4 `app`; `derived` là view, không phải bảng vật lý.

**2:30–3:35:** Giải thích `course_modules.instance` đa hình và vì sao không tự suy ra FK vật lý. Nêu 39 PK, 38 FK, 548 cột là số đo catalog của model staging; không áp sang production DLU.

**3:35–4:40:** Chỉ `unified_tasks`, `student_course_progress`, `student_grade_overview`, `student_attendance_summary`. Task có trạng thái từ activity; progress từ completion; grade có `null`; attendance dựa log/session. Risk rule-based không phải AI.

**4:40–6:15:** Demo Student qua Home → Courses → Course Detail → Assignment → Progress → Grades → Profile. Chỉ màn empty/loading/error nếu gặp nhưng không cố tạo lỗi. Bấm “Nộp bài trên LMS” để chứng minh ranh giới. Không nhập credential hay thực hiện academic write.

**6:15–7:10:** API boundary: Flutter → HTTPS Render → Fastify → read model PostgreSQL. Nêu quyền Student/Teacher do API lọc ở staging; production vẫn cần identity/capability DLU. Đổi Teacher → Student chứng minh không giữ course của Teacher trên shell Student.

**7:10–8:00:** Kiểm thử và kết luận: backend 54, Flutter 167, analyze, APK debug staging, 15 ảnh; DLU auth/Web Services `TO_VERIFY_DLU`, thông báo fire `NOT_VERIFIED`. “Bản này chứng minh kiến trúc và UX hỗ trợ học tập trên data mẫu; production cần nguồn/chính sách được Trường cho phép.”
