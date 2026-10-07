# Database traceability — decision support, not a second LMS

Checked 07/10/2026 against actual GROUP candidate catalog, current API source and innovation migration. Data is synthetic; official DLU authentication/submission/grades remain `TO_VERIFY_DLU` / LMS ONLY.

## Student

| UI / value | API field / endpoint | Service / query | Actual source | Guard / interpretation |
| --- | --- | --- | --- | --- |
| Hôm nay: việc nên làm | `/api/v1/me/recommendations`: assignment/course, dueAt, submissionStatus | `InnovationService.recommendations`, `rankRecommendations` | `GroupStudentDataSource.assignments/assignmentStatus`: `lms.assign`, latest `lms.assign_submission`, visible `lms.grade_items/grade_grades` | `studentScope`, `visibleAssign`; submitted/graded/late excluded; unknown state never inferred unfinished |
| Vì sao ưu tiên | priorityScore, priority, reasons | typed `priorityRules` + current clock | assignment duedate, returned/draft state, known tracked activity denominator | Each displayed reason contributes weight. No grade/activity/inactivity score is fabricated |
| Tiến độ học phần | progressPercent, totalActivities, completedActivities | `GroupStudentDataSource.progress` | visible `lms.course_modules`, section visibility, `lms.course_modules_completion` | >0 tracked denominator needed for low-progress signal; no tracked module ≠ student failure |
| Danh sách/nội dung học phần | `/api/v1/me/courses`, content | scoped course + learning item SELECT | `derived.student_course_learning_items` → modules/type-specific LMS source | 002 maps module assign to task assignment, signatures unchanged; synthetic source paths are NOT verified DLU links |
| Tạo/sửa/hoãn kế hoạch | POST/PATCH `/api/v1/me/study-plan/items` | InnovationService + `PostgresInnovationStore` | `app.study_plan_items`: owner_user_id, assignment_id, course_id, scheduled_start_at, estimated_minutes, notes | Current active enrolment, source visibility; UNIQUE owner/assignment; duration 5–480, future date on edit |
| Xử lý/xóa kế hoạch | status handled / DELETE owner item | scoped update/delete | app state only | Does NOT update `lms.assign_submission` or academic completion; delete requires explicit UI confirmation |
| Reminder | generic copy + schedule/cancel | local reminder scheduler/coordinator after API commit | app persisted scheduled instant + device-local alarm mapping | Ownership snapshot before/after await, no password/name in notification; platform delivery limitation recorded separately |
| Điểm | score, percentage, feedback | scoped grade SELECT | `lms.grade_grades.finalgrade`, grade_items.grademax, hidden flags, course.showgrades | 0 is real grade, NULL is unknown; divide by NULLIF denominator; no grade writes |

Recommendation score: overdue70; due within24h60,72h45,168h25, later10; returned+20; draft+10; known tracked progress<50%+10; clamp100. High≥65, medium≥30. Deterministic tie: score desc, deadline asc, assignment id. `handled` excludes personal recommendation but never fabricates official submission.

## Teacher

| UI / value | API field / endpoint | Service / query | Actual source | Guard / interpretation |
| --- | --- | --- | --- | --- |
| Khóa học phụ trách | `/api/v1/me/teacher/courses` | `teacherScope` + course/work/sections SELECTs | course-level `lms.context`, role_assignments, teacher/editingteacher role; derived course/assignment views | Visible course, active actor; role from context, not UI boolean |
| Cần chú ý / lý do | `/api/v1/me/teacher/attention`: overdueTasks,pendingTasks,progressPercent,priority,reasons | `rankAttention`, typed `priorityRules` | `derived.teacher_student_monitoring` → student task/progress models → source assignments, quiz attempts, tracker states | Current active student/course enrolment; denominator guard. Legacy view risk_score/risk_level is not current score authority |
| Student detail/roster label | student/course identity and support level | `GroupTeacherDataSource.students`, same ranking for badge | Monitoring view + current actor/course student scope | No all-course wildcard; no inactive/suspended user leak; same signal rules as Inbox |
| Ghi nhận hỗ trợ | POST `/api/v1/me/teacher/interventions` | InnovationService + guarded INSERT | `app.teacher_interventions`: owner_teacher_id, student_id,course_id,title,note,action_type,reasons,baseline | Active relationship checked at data layer, one active record per teacher/course/student; no LMS messages/grades |
| Lịch theo dõi | PATCH intervention / `/api/v1/me/teacher/followups` | date validation + own-record filtering | follow_up_at, status, created_at | offset-aware instant, future scheduling; resolved removes due date; current due check against actual clock |
| Theo dõi lại / kết thúc | POST intervention/:id/followups | locked parent, append snapshot + update lifecycle atomically | `app.intervention_followups`: note,outcome_status,progress_percent,pending_tasks,overdue_tasks,created_at | Parent must be own scoped non-resolved; bounded history, consistent closed lifecycle |
| Lịch sử / so sánh | intervention baseline,current,followups | fresh current attention + stored historical snapshots | baseline JSON + append-only follow-up rows | Actual observations only; unchanged is not falsely improved; no causal claims |

Teacher score: overdue count×20 capped60; pending count×5 capped20; known tracked progress<50% adds20; max100; same high/medium thresholds. Order: score desc, course id, student id. Pending and overdue are separate source buckets. No LLM, failure prediction or fabricated engagement factor.

## GROUP read models vs server authority

`derived.unified_tasks`, task summary, grade overview, engagement/progress, Teacher monitoring/aggregates are explainable read models. They are not RBAC views or DLU official API capabilities. Every public query must constrain current principal/context/enrolment/source visibility; app write module contains reviewed fixed SQL only. Client never supplies raw SQL/table names.

20 view definitions and 42 table columns are captured as sanitized catalog metadata. 45 FK checks found no orphan; app polymorphic references were checked by their actual type rather than a false universal FK. `app.learning_reminders/notifications` GROUP rows are not a second scheduler automatically running in this app; device reminders use the existing local scheduler abstraction.

## Evidence and boundary

- `evidence/database/perfection-final/catalog.json`: actual counts, columns, constraints, indexes and view SQL; no credential/row dump.
- `semantics.json`: all20 view keys, true0/NULL grades, unknown attendance, active context, polymorphic and FK checks.
- `migration-applied.json`:002 all42 table rows and ALL column/type signatures unchanged;94 lost assignment source-state joins corrected.
- `003-migration-rehearsal.json`: official task completed vs independent tracker semantics, no data changes.
- `003-migration-applied.json`: candidate apply confirmed, 3 source-completed next-items → 0, tables/columns/types unchanged.
- `query-plans.json`: bounded actual read-only execution observations, not production SLA.
- `database/council_pgadmin_demo.sql`: Data → signal → personal plan / teacher follow-up; separate synthetic identities.

Production path stays Flutter → authorized secure API/Moodle Web Services → DLU Moodle. Neon candidate is staging evidence and development infrastructure, **not** a verified copy of DLU production. A dedicated least-privilege deployment DB role remains required before production, because the current candidate owner has broader privileges than runtime needs.
