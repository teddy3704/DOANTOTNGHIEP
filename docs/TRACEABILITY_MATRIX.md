# Traceability — Student + Teacher Support

## Current GROUP_39_20 trace (22/09/2026)

| Feature | Source → API → Mobile | Verification |
|---|---|---|
| Student identity/profile | scoped lms user → `/api/v1/me` → StagingUserRepository → ProfileScreen | optional department regression; 320/390px profile widgets; opt-in real payload test |
| Courses/content/assignments/grades/progress | GROUP_39_20 scoped read models → existing Student GET routes → Staging repositories → Student screens | student_support_repositories_test; staging_live_contract_test |
| Teacher Home/Courses/Work/Profile | role/course context → GroupTeacherDataSource overview → `/api/v1/me/teacher/overview` → TeacherSupportApiRepository → TeacherSupportScreen/ProfileScreen | teacher_support_api_repository_test; live payload test |
| Student Monitoring | derived.teacher_student_monitoring + course guard → `/api/v1/me/teacher/courses/{courseId}/students` → StudentMonitoring → TeacherStudentsScreen | scope/duplicate/bounds tests; search/expand/error/retry/layout tests |
| Context isolation | identity provider → exclusive role headers + stale-response rejection → role router + user-scoped providers | client/teacher adapter/role routing tests; final runtime evidence |
| Official actions | central OfficialLmsLauncher → HTTPS official LMS home | host allowlist tests; no mobile submission/grading or fabricated deep link |

Teacher fixture is test-only, not the current staging source. Runtime and final
gate details: `FLUTTER_TEST_RESULT.md`. Earlier baseline tables below are historical.

## Council baseline alignment — 2026-09-19

Configured Neon: **lms 22 tables, 10 views**, not the group's 39-table model.
`REPORT_ALIGNMENT_NOTES.md` records the difference and Node/Fastify backend.
`demo/02_council_database_demo.sql` can demonstrate the existing SQL Teacher
views, but they are not exposed by a deployed Teacher API and are not the source
of Teacher Flutter screens. No row implies a deployed `derived.*` endpoint.

Student Assignment: Moodle assign/submission → lms assignments/submissions →
vw_student_assignments/vw_assignment_status → GET API → AssignmentScreen →
Nộp bài trên LMS (official home, no fabricated activity URL).
Reminder: app-owned metadata → secure local store/scheduler → editor/manager,
no academic write. Teacher Work: scoped canonical fixture assign/submission →
StagingTeacherSupportRepository → TeacherSupportScreen → Chấm bài trên LMS.
Automated and runtime evidence: `FLUTTER_TEST_RESULT.md`.

## Current support extension — 2026-09-18

Student rows below remain the verified PostgreSQL/Render API trace. Teacher
Support uses a distinct, explicit read-only staging adapter (not a Teacher API):
`user` + `role_assignments` + course `context` → assigned `course` + active
`enrol`/`user_enrolments` → `StagingTeacherSupportRepository` →
`TeacherSupportScreen` (Home/Courses/Work/Calendar), shared Profile.
`assign` + latest `assign_submission` produce only counts within enrolled scope;
`course_sections`/`course_modules`/`resource` produce read-only content summaries.
The existing canonical synthetic JSON is the Teacher development source; no new
database or remote endpoint is claimed. Tests: `teacher_support_test.dart`.

Student **Nộp bài trên LMS** and Teacher **Chấm bài / Quản lý bài tập trên LMS**
→ central `OfficialLmsLauncher` → official HTTPS home, with no generated activity
ID. Mobile does not implement the official write operation. Personal reminders
remain app-owned. See `MOBILE_FEATURE_MATRIX.md` and `FLUTTER_TEST_RESULT.md` for
the current gate; older Student-only gate notes below are historical.

**VERIFIED STUDENT API SCOPE.** Hai bảng nối bằng Function Code bao quát nguồn dữ liệu,
API và consumer. Mô hình Neon là representation phát triển có dữ liệu mẫu, không
khẳng định schema/version/endpoint DLU giống upstream. Flutter staging consumer
đã được xác minh qua `main_staging.dart` explicit read-only boundary sau khi Render
staging và Postman staging PASS; điều đó không xác nhận DLU integration.

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
| SV-10 Nhắc nhở học tập cá nhân | Không suy đoán Moodle reminder table; deadline chỉ được đọc làm tham chiếu | opaque owner/course/assignment refs, due/remind time, enabled | Không dùng table/view Neon; secure local app metadata | Assignment Detail editor; Profile reminder manager | APP_SUPPORT; owner-scoped local setting, no Moodle/Neon write. Automated checks pass locally; APK/emulator delivery gate pending |

Không tạo view trùng `vw_student_assignment_status`: reuse view thật
`vw_assignment_status`. Không expose hai teacher views chỉ vì chúng có trong
database tham chiếu. Hồ sơ current student là endpoint phụ trợ dùng chung SV-01..09.

## View → Development API → OpenAPI/Postman → Flutter staging mobile

Operation ID dưới đây khớp `src/app.ts`; Postman đối chiếu bằng GET/path và tên
request, không suy ra đã chạy Web từ việc collection tồn tại.

| Code | Development API endpoint / HTTP method | OpenAPI operation | Postman request | Flutter staging module/screen | Future production source candidate |
|---|---|---|---|---|---|
| SV-01 | GET `/api/v1/me/courses` | `getCourses` | Courses | Courses list | `core_enrol_get_users_courses` |
| SV-02 | GET `/api/v1/me/courses/{courseId}/content` | `getCourseContent` | Course content, course ID lấy từ Courses | Course detail / sections | `core_course_get_contents` |
| SV-03 | GET `/api/v1/me/resources` | `getResources` | Learning resources | Resources metadata list | `core_course_get_contents`; file permission/URL xác minh riêng |
| SV-04 | GET `/api/v1/me/assignments` | `getAssignments` | Assignments | Assignment list/detail read-only | `mod_assign_get_assignments` |
| SV-05 | GET `/api/v1/me/assignment-status` | `getAssignmentStatus` | Assignment status | Assignment status read-only | `mod_assign_get_submission_status` |
| SV-06 | Không standalone route; đọc deep-link fields từ GET content/assignments/status | `getCourseContent`, `getAssignments`, `getAssignmentStatus` | Course content / Assignments / Assignment status; contract deepLink được kiểm tra ở backend tests | Assignment Detail chỉ mở LMS home origin chính thức; không ghép activity URL, không Mobile submit | DLU-supported activity link, chưa xác minh |
| SV-07 | GET `/api/v1/me/grades` | `getGrades` | Grades and feedback | Personal grades/feedback | `gradereport_user_get_grade_items` |
| SV-08 | GET `/api/v1/me/progress` | `getProgress` | Learning progress | Progress screen, course summary chỉ đọc | `core_completion_get_activities_completion_status` |
| SV-09 | GET `/api/v1/me/deadlines` | `getDeadlines` | Upcoming deadlines | Calendar contextually từ Dashboard / upcoming tasks | `core_calendar_get_calendar_events` + assignment API; events endpoint chưa triển khai |
| SV-10 | Không endpoint HTTP | Không OpenAPI operation | Không Postman/API request ghi reminder | Assignment Detail tạo/chỉnh sửa; Profile quản lý nhắc việc cục bộ | Secure local persistence + generic Android local notification; không Moodle/Neon/Render write |

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
- Checkpoint 2026-09-18: `RENDER_STAGING_GATE=PASS` and
  `POSTMAN_STAGING_GATE=PASS`; the public service returned 200 for `/health`,
  `/docs` and `/openapi.json`, while Postman completed 85/85 assertions. The
  explicit Flutter staging consumer also passed `dart format .`, `flutter analyze`
  and `flutter test` (93 tests) plus Android emulator verification for Dashboard,
  Courses, Course Detail, Resource Detail, Assignment Detail, Grades, Calendar and
  Profile. This stays a read-only non-production flow: no DLU password login,
  upload, submission, grading or other write workflow is available or fabricated.
- Current local Flutter extension adds explicit sample-scope selection and 401
  invalidation, a read-only Assignment list, a Progress screen, contextual
  Calendar navigation, canonical-LMS handoff and app-owned local reminders from
  Assignment Detail/Profile. `flutter analyze` is clean and the full test suite
  passes 137 tests; its final format/build/emulator gate is pending. It does not
  change any `TO_VERIFY_DLU` production row above.
