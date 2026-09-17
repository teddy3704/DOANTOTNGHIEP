# Traceability — SV-01..SV-10

**STUDENT SUPPORT ONLY.** Hai bảng nối bằng Function Code bao quát nguồn dữ liệu,
API và consumer. Mô hình Neon là representation phát triển có dữ liệu mẫu, không
khẳng định schema/version/endpoint DLU giống upstream. Flutter là **future consumer**
trong phase này; không sửa Flutter hoặc xác nhận đã tích hợp. Flutter đã được
phê duyệt nhưng phải chờ cả Render staging và Postman staging PASS.

Moodle source names không có table prefix vì prefix DLU chưa được xác nhận. Các
mapping tham chiếu đã phân tích nằm trong workspace local tại
`database/MOODLE_DATABASE_AUDIT.md` và `database/FUNCTION_DATABASE_MATRIX.md`.
Hai tài liệu database này **không được đưa vào nhánh deploy Integration API**;
không phải dependency hay liên kết bắt buộc của clean checkout nhánh deploy.
Bảng dưới đây ghi lại mapping cần cho contract của API. FK vật lý của mô hình
PostgreSQL không tự trở thành FK của Moodle; polymorphic/application mappings
vẫn tách biệt.

## Function → Moodle → PostgreSQL → View

| Function Code / Student Function | Moodle source table | Important fields | PostgreSQL representation | Student view | Data ownership / DLU status |
|---|---|---|---|---|---|
| SV-01 Xem khóa học đang học | `user`, `course`, `enrol`, `user_enrolments`, `course_categories`, `context`, `role_assignments`, `role` | user/course/enrolment identity, active, starts/ends, student role | `users`, `courses`, `enrolments`, `user_enrolments`, categories/contexts/roles | `vw_student_courses` | MOODLE; TO_VERIFY_DLU |
| SV-02 Xem nội dung khóa học | `course_sections`, `course_modules`, `modules`, `resource`, `assign` | course, section, sequence/position, module/instance, visible | `course_sections`, `course_modules`, `modules`, `resources`, `assignments` | `vw_course_content` + membership từ `vw_student_courses` | MOODLE; TO_VERIFY_DLU |
| SV-03 Xem tài liệu | `resource`, `files`, `context`, `course_modules` | filename, filesize, mimetype, component/filearea/itemid, visibility | `resources`, `files`, `contexts`, `course_modules` | `vw_student_resources` | MOODLE; file access/URL TO_VERIFY_DLU |
| SV-04 Xem bài tập và hạn nộp | `assign`, `course_modules`, `course_sections` | assignment identity/name/intro, allow-from/due time, max grade | `assignments`, `course_modules`, `course_sections` | `vw_student_assignments` | MOODLE; TO_VERIFY_DLU |
| SV-05 Xem trạng thái bài tập | `assign_submission`, `assign_grades`, `assignfeedback_comments` | student/assignment, attempt, status, submitted time, grade visibility | `assignment_submissions`, `assignment_grades`, `assignment_feedback_comments` | `vw_assignment_status` + visible assignment guard | MOODLE; READ IF API PERMITS; DLU response NOT_VERIFIED |
| SV-06 Mở bài tập trên LMS | `course_modules`, `assign` làm tham chiếu activity | URL/identity do DLU hỗ trợ; chưa có verified live URL | Catalogue mẫu chỉ phục vụ phân tích, không dùng ID ghép URL DLU | Không thêm view; assignment/content DTO mang null deep-link | MOODLE thực hiện nộp bài; DEEPLINK TO_VERIFY_DLU |
| SV-07 Xem điểm và phản hồi | `grade_items`, `grade_grades`, `assign_grades`, `assignfeedback_comments` | student, gradeitem, final/max grade, feedback, graded time | `grade_items`, `grade_grades`, `assignment_grades`, `assignment_feedback_comments` | `vw_student_grade_overview` + visible assignment guard | MOODLE; grade visibility/response NOT_VERIFIED |
| SV-08 Xem tiến độ | `course_modules_completion`, `course_modules` | user/module, completion state, completion tracking, visible | `course_module_completions`, `course_modules` | `vw_student_progress` | MOODLE; completion tracking TO_VERIFY_DLU |
| SV-09 Theo dõi lịch/deadline | `event`, `assign` | course/user, start/end, due time, event type | `events`, `assignments`; API phase này chỉ upcoming assignment | `vw_upcoming_deadlines` + visible assignment guard | MOODLE; calendar/timezone TO_VERIFY_DLU |
| SV-10 Nhắc nhở học tập cá nhân | Không có Moodle reminder table được suy đoán; deadline chỉ tham chiếu | owner, activity reference, remind time, enabled — đề xuất | Chưa tạo app-owned table | Chưa có | APP_SUPPORT; DESIGN_ONLY, chưa triển khai |

Không tạo view trùng `vw_student_assignment_status`: reuse view thật
`vw_assignment_status`. Không expose hai teacher views chỉ vì chúng có trong
database tham chiếu. Hồ sơ current student là endpoint phụ trợ dùng chung SV-01..09.

## View → Development API → OpenAPI/Postman → Future Mobile

Operation ID dưới đây khớp `src/app.ts`; Postman đối chiếu bằng GET/path và tên
request, không suy ra đã chạy Web từ việc collection tồn tại.

| Code | Development API endpoint / HTTP method | OpenAPI operation | Postman request | Future Flutter module/screen | Future production source candidate |
|---|---|---|---|---|---|
| SV-01 | GET `/api/v1/me/courses` | `getCourses` | Courses | Courses list | `core_enrol_get_users_courses` |
| SV-02 | GET `/api/v1/me/courses/{courseId}/content` | `getCourseContent` | Course content, course ID lấy từ Courses | Course detail / sections | `core_course_get_contents` |
| SV-03 | GET `/api/v1/me/resources` | `getResources` | Learning resources | Resources metadata list | `core_course_get_contents`; file permission/URL xác minh riêng |
| SV-04 | GET `/api/v1/me/assignments` | `getAssignments` | Assignments | Assignment list/detail read-only | `mod_assign_get_assignments` |
| SV-05 | GET `/api/v1/me/assignment-status` | `getAssignmentStatus` | Assignment status | Assignment status read-only | `mod_assign_get_submission_status` |
| SV-06 | Không standalone route; đọc deep-link fields từ GET content/assignments/status | `getCourseContent`, `getAssignments`, `getAssignmentStatus` | Course content / Assignments / Assignment status; contract deepLink được kiểm tra ở backend tests | Mở LMS qua URL được xác minh; không Mobile submit | DLU-supported activity link, chưa xác minh |
| SV-07 | GET `/api/v1/me/grades` | `getGrades` | Grades and feedback | Personal grades/feedback | `gradereport_user_get_grade_items` |
| SV-08 | GET `/api/v1/me/progress` | `getProgress` | Learning progress | Course progress | `core_completion_get_activities_completion_status` |
| SV-09 | GET `/api/v1/me/deadlines` | `getDeadlines` | Upcoming deadlines | Calendar / upcoming tasks | `core_calendar_get_calendar_events` + assignment API; events endpoint chưa triển khai |
| SV-10 | Không endpoint | Không operation | Không request ghi reminder | Reminder module DESIGN_ONLY | App-owned persistence tương lai, không Moodle write |

GET `/health` → `getHealth` kiểm tra hạ tầng; GET `/api/v1/me` →
`getStudentProfile` resolve profile; GET `/api/v1/me/overview` → `getOverview` tổng
hợp cùng nguồn SV-01/04/05/07/08/09. Không có totals hard-code hoặc student mặc định.

## Gate và bằng chứng

DLU production cho toàn bộ matrix vẫn **TO_VERIFY_DLU**, không phụ thuộc local/API
gate có PASS hay không. Upstream function candidates đã truy vết trong database
matrix, không chứng minh DLU version, enabled service hoặc capability.

- Contract: `API_CONTRACT.md`, runtime `/openapi.json` và export cùng pipeline.
- Isolation/read-only/secret controls: `API_SECURITY_MODEL.md`.
- Execution: `API_TEST_RESULT.md` và `INTEGRATION_STATUS.md` cập nhật theo gate thật.
- Postman/Render status cần kiểm chứng riêng; chưa hoàn tất không được đổi thành
  PASS nhờ có source hoặc export. API không gọi production LMS và không sửa Moodle.
- Checkpoint 2026-09-17: final local rechecks PASS (50 tests, 20 HTTP → Neon checks,
  dependency audit 0 vulnerabilities); Postman local đã PASS 85/85 assertions.
  Dedicated-branch publication/deployment IN_PROGRESS, `RENDER_STAGING_GATE` và
  `POSTMAN_STAGING_GATE` đều NOT_RUN. Evidence local/historical được phân loại trong
  `ADVISOR_EVIDENCE_INDEX.md`.
