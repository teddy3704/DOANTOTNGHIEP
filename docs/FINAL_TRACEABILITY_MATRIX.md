# Truy vết yêu cầu tới bản staging GROUP_39_20

## Innovation extension — 06/10/2026

Nhánh `innovation-study-planner-intervention`; baseline được giữ nguyên.
Candidate migration applied/verified, original rows/lms columns/views không đổi:
3 schemas, 42 tables (35 lms + 7 app), 20 views, 42 PK, 45 FK, 588 columns.
Backend 82/82 tests và real local API CRUD/scope 181 checks PASS. Render backend
`a0c2cb7` Live từ nhánh innovation; public regression 165 checks PASS, config và
database secret không đổi. Flutter format/analyze/224 tests PASS, 1 opt-in live
test skipped và separately PASS; responsive UI ở 320/390px/scale 1.3 PASS.
Final APK rebuilt/cài/relaunch Success. Actual Student plan edit/postpone/
handled/restore, Teacher action/follow-up/resolved-history persistence và
SV001/SV002/GV001 isolation PASS. Android reminder delivered 17:22 rồi hủy khi
handled, không đổi LMS state. Fifteen actual PNGs ở
`evidence/mobile/innovation-final/` là evidence runtime, không suy ra từ source.
Final handoff secret/index scan và diff check PASS; focused commit/push receipt
được bàn giao riêng, exact hash lấy từ Git, không suy đoán.
Final read-only integrity/persistence PASS: original rows/columns/views intact;
SV001 cleanup count 0; resolved Teacher case/history and observed 29%/4 overdue
retained with no due follow-up. `INNOVATION_FINAL_QA.md` holds actual final proof.

| Feature | Domain / repository | Data source / API | UI | Tests / verification |
|---|---|---|---|---|
| Student priorities | `StudyRecommendation`, `StudyPlannerRepository` | `rankRecommendations` in `domain/innovation.ts`; scoped assignment/status/progress; GET `/me/recommendations` | `StudentTodayScreen` | `innovation-domain.test.ts`, `study_planner_widget_test.dart`, real API smoke |
| Personal study plan | `StudyPlanItem`, `StudyPlanCoordinator` | `StudyPlannerApiRepository`; `app.study_plan_items`; GET/POST/PATCH/DELETE `/me/study-plan...` | `StudyPlanScreen`, editor/card | `innovation-http.test.ts`, `innovation-store.test.ts`, coordinator/provider/widget suites, persistence smoke |
| Study-session reminder | Existing `ReminderRepository`, coordinator | Device-local secure metadata and scheduler; no LMS event | Plan editor reminder option | `study_plan_coordinator_test.dart`; Android delivered 17:22/cancel on handled PASS; `12_study_reminder.png` |
| Teacher attention | `AttentionStudent`, `InterventionRepository` | `rankAttention`; scoped progress/pending/overdue; GET `/me/teacher/attention` | `TeacherTodayScreen`, `StudentAttentionDetailScreen` | domain/model/provider/widget suites, role/context smoke |
| Teacher action/history | `TeacherIntervention`, `FollowupDraft` | `InterventionApiRepository`; `app.teacher_interventions`, `app.intervention_followups`; `/me/teacher/interventions...` | `InterventionInboxScreen`, editor/detail/history | HTTP/store suites, `intervention_screens_test.dart`, actual action → follow-up → reread/resolve |
| Ownership and safe transport | Session-scoped providers, `StudentSupportApiClient` | Backend alias + role/enrolment/owner checks; closed app-write allowlist | Role-scoped routes, state invalidation | `workflow_transport_test.dart`, negative HTTP/real scope smoke |

All paths above are under `/api/v1`. Reasons/priority and baseline/current
snapshots are server-owned. Handled plan/closed support never mutate official
submission, completion or grade. No inactivity, causal improvement or AI claims.
Actual final statuses are authoritative in `PROJECT_STATUS.md`; the older matrix
below describes the previously verified academic read baseline.

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
