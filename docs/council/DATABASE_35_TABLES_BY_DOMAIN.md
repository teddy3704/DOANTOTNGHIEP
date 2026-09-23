# 35 bảng lms theo nhóm nghiệp vụ

Danh mục dưới đây khớp tên `CREATE TABLE lms.*` trong SQL nhóm. Một bảng nằm trong đúng một nhóm; tổng **35**. Đây là mô hình development/staging, không phải catalog production DLU.

| Nhóm | Bảng thực tế | Mối quan hệ và ý nghĩa với Mobile |
|---|---|---|
| Danh tính, vai trò, ngữ cảnh (4) | `"user"`, `role`, `context`, `role_assignments` | Danh tính dùng chung, role gắn vào context; API xác định phạm vi Student/Teacher, không lập bảng tài khoản riêng cho từng vai trò. |
| Học phần, danh mục, ghi danh (5) | `course`, `course_categories`, `enrol`, `user_enrolments`, `course_completions` | Course thuộc danh mục; phương thức và người ghi danh khác role; completion cấp học phần hỗ trợ tổng quan. |
| Cấu trúc và nội dung course (7) | `course_sections`, `course_modules`, `course_modules_completion`, `modules`, `resource`, `folder`, `forum` | Course → section → module; `modules` xác định loại, `instance` đa hình trỏ hoạt động; completion module hỗ trợ tiến độ; tài nguyên/diễn đàn là nội dung, không phải nghiệp vụ Mobile mới. |
| Assignment và quiz (6) | `assign`, `assign_submission`, `assign_grades`, `quiz`, `quiz_attempts`, `quiz_grades` | Dữ liệu việc học, trạng thái nộp/làm và điểm; `derived.unified_tasks` gom vào timeline. Mobile chỉ đọc; nộp bài/làm quiz/chấm trên LMS. |
| Gradebook (3) | `grade_categories`, `grade_items`, `grade_grades` | Danh mục → mục điểm → giá trị; read model hiển thị điểm/feedback khi có dữ liệu, không tính “điểm chính thức” tùy ý. |
| Attendance (4) | `attendance`, `attendance_sessions`, `attendance_statuses`, `attendance_log` | Hoạt động → buổi → trạng thái → ghi nhận từng người; `student_attendance_summary` tóm tắt. |
| Hoạt động và truy cập (2) | `logstore_standard_log`, `user_lastaccess` | Dấu vết hoạt động và lần vào course cuối; dùng cho engagement/continue learning, không suy thành đánh giá tự động. |
| Nhóm học (4) | `groupings`, `groupings_groups`, `groups`, `groups_members` | Course grouping và thành viên nhóm; giúp giải thích phạm vi học phần/hoạt động trong schema, không có màn quản trị nhóm trên Mobile. |

**Quan hệ cần nhớ.** `user_enrolments` ghi nhận việc tham gia qua `enrol`; `role_assignments` áp quyền theo `context`. `course_modules.instance` chỉ có nghĩa khi biết loại `modules`; vì vậy đây không phải FK tới một bảng cố định. Trong số 38 FK vật lý của toàn mô hình, không được tự nhận các nối đa hình và application mapping là FK.
