# Truy vết yêu cầu tới bản staging GROUP_39_20

Các bảng/view là mô hình **development/staging**. “View tham chiếu” mô tả read model trong SQL nhóm; adapter API hiện có thể query bảng scoped trực tiếp thay vì SELECT view đó. Không nhận một view là endpoint độc lập nếu OpenAPI không công bố.

| Yêu cầu | Moodle domain / bảng lms | View tham chiếu | API thật | Flutter feature / screen | Nghiệp vụ chính thức | Trạng thái |
|---|---|---|---|---|---|---|
| Hồ sơ và role | `"user"`, `role`, `context`, `role_assignments`, `enrol`, `user_enrolments` | `student_dashboard`, `teacher_course_overview` | `GET /api/v1/me`, `/api/v1/me/teacher` | Profile, role/context selector staging | Xác thực DLU chờ phê duyệt | STAGING PASS; DLU `TO_VERIFY_DLU` |
| Học phần Student | `course`, `course_categories`, `enrol`, `user_enrolments` | `student_course_overview` | `GET /api/v1/me/courses` | Student Courses, Course Detail | Mở LMS khi cần | PASS |
| Nội dung/tài nguyên | `course_sections`, `course_modules`, `modules`, `resource`, `folder`, `forum` | `student_course_learning_items` | `GET /api/v1/me/resources`, `/api/v1/me/courses/{courseId}/content` | Course Detail / resources | Private access theo LMS policy | PASS metadata/điều hướng |
| Bài tập và hạn | `assign`, `assign_submission`, `quiz`, `quiz_attempts` | `unified_tasks`, `student_task_summary` | `GET /api/v1/me/assignments`, `/assignment-status`, `/deadlines` | Assignment/Calendar/reminders | “Nộp bài trên LMS”; quiz trên LMS | PASS đọc + LMS link; Mobile submit NO |
| Tiến độ | `course_modules_completion`, `course_completions` | `student_course_progress` | `GET /api/v1/me/progress` | Student Progress | Completion chính thức ở LMS | PASS đọc staging |
| Điểm/feedback | `grade_items`, `grade_grades`, `grade_categories`, `assign_grades`, `quiz_grades` | `student_grade_overview`, `student_grade_category_summary` | `GET /api/v1/me/grades` | Student Grades | Chấm/feedback ở LMS | PASS đọc staging; Mobile grade write NO |
| Chuyên cần/engagement | `attendance`, `attendance_sessions`, `attendance_statuses`, `attendance_log`, `logstore_standard_log`, `user_lastaccess` | `student_attendance_summary`, `student_engagement` | Chưa có endpoint chuyên cần/engagement riêng | Không có màn chuyên cần riêng | DLU là nguồn chính khi được phép | MODEL ONLY; không tuyên bố API PASS |
| Teacher course/work | `course`, `role_assignments`, `context`, `assign`, `assign_submission` | `teacher_course_overview`, `teacher_assignment_monitoring` | `GET /api/v1/me/teacher/overview`, `/courses`, `/assignments` | Teacher Home/Courses/Công việc | “Chấm bài trên LMS” | PASS đọc + LMS link; Mobile grading NO |
| Teacher student monitoring | `"user"`, `course`, `user_enrolments`, `course_modules_completion`, `assign_submission` | `teacher_student_monitoring`, `student_risk_indicator` | `GET /api/v1/me/teacher/courses/{courseId}/students` | Theo dõi sinh viên trong course | Giảng viên xử lý chính thức trên LMS | PASS scoped; chỉ báo rule-based |
| Lời nhắc Mobile | Không là dữ liệu LMS chính thức | `app.learning_reminders` là model DB tham chiếu, **không** là nguồn runtime | Không có API ghi reminder | Calendar/reminders cục bộ | Không thay hạn LMS | Persistence/test PASS; fire `NOT_VERIFIED` |

Backend Student/Teacher cùng đọc database staging GROUP_39_20 nhưng không tự nối sang dữ liệu production DLU. Identity header mẫu chỉ ở staging; production cần DLU Authentication/Web Services và quyền server-side được xác minh.
