# Database hardening audit

Kiểm chứng ngày 07/10/2026, trên **candidate dữ liệu mô phỏng được duyệt**. Không kết nối database DLU production; không thay Render secret. Catalog/query-plan evidence không chứa credential hoặc dump dữ liệu người dùng.

## Catalog thực tế

| Thành phần | Kết quả sau migration 002 |
| --- | ---: |
| Schemas | 3: `lms`, `app`, `derived` |
| Physical tables | 42: 35 LMS source + 7 app-owned |
| Derived views | 20 |
| Physical columns | 588 |
| Primary / foreign keys | 42 / 45 |
| Unique / check constraints | 15 / 29 |
| Indexes | 165 |

Mốc GROUP gốc 39 bảng/20 views là lịch sử, không phải catalog hiện tại. PostgreSQL còn lưu NOT NULL dưới loại constraint riêng; không cộng các constraint này vào CHECK.

## Findings và sửa tối thiểu

| Severity | Bằng chứng | Quyết định |
| --- | --- | --- |
| HIGH | 94 assignment learning-items mất `task_status`: module `assign` không khớp task type `assignment` | 002 sửa JOIN bằng CASE; 94 → 0 missing status, không đổi chữ ký view |
| MEDIUM | Legacy risk view biến NULL inactivity thành 999 ngày; zero tracked activities vẫn cộng điểm progress | 002 bỏ sentinel 999 và chỉ cộng progress khi denominator > 0 |
| MEDIUM | Plan title / timestamp order / resolved follow-up chỉ dựa vào service | 002 thêm 5 CHECK phù hợp hành vi thực tế; 0 row vi phạm trước migration |
| MEDIUM | Sau khi sửa JOIN, 3 `student_continue_learning` candidates có task source đã completed nhưng tracker chưa cập nhật | 003 rehearse/rollback rồi apply được duyệt: 3 → 0; resource/folder và NULL state semantics giữ nguyên |
| MEDIUM | Một số GROUP raw views không kiểm tra enrolment time window/user suspension/course role đầy đủ | Views là read-model, không là authorization; API recheck active actor + current course role + active enrolment. Không expose trực tiếp view như API |
| MEDIUM | Candidate owner có quyền ghi LMS và bypass RLS | Không giả claim least-privilege DB. Staging dùng guarded statements + API scope; production cần dedicated role SELECT nguồn / WRITE app trước deploy DLU |
| LOW | 1 FK `lms.enrol.roleid` không có leading index; bảng enrol chỉ 10 rows | Không thêm index không có bằng chứng tải; FK được kiểm chứng không orphan |

002 và 003 áp dụng sau kiểm tra hash chính xác, rehearsal trong transaction rollback, backup riêng và duyệt của điều phối. **42 table row digests và toàn bộ column/type signatures giữ nguyên** trong từng migration; tổng cộng chỉ 3 view definitions + 5 CHECK thay đổi. Không INSERT/UPDATE/DELETE vào LMS hay app trong migration.

## App ownership và lifecycle

- `app.study_plan_items`: UUID PK; owner → LMS user, assignment → LMS assign, course → LMS course, đều FK RESTRICT. UNIQUE(owner, assignment) ngăn double-create. Duration 5–480, score 0–100, enum priority/status; note ≤500. Personal `handled` **không** có nghĩa nộp bài LMS.
- `app.teacher_interventions`: teacher, student, course FK RESTRICT; nonempty title/note, bounded varchar, controlled action/status, JSON reason array và snapshot object. Partial UNIQUE(teacher, course, student) với status≠resolved ngăn hồ sơ active trùng. Resolved phải bỏ follow-up date; lịch hẹn không trước ngày tạo.
- `app.intervention_followups`: UUID PK, parent FK RESTRICT, nonempty note, controlled outcome, bounded progress và nonnegative counters; append-only qua API. `pending_tasks` và `overdue_tasks` là **hai buckets riêng**, không đặt constraint `overdue <= pending` (5 snapshot hiện tại minh họa điều này).
- Bốn app tables từ GROUP (`learning_goals`, `learning_reminders`, `notifications`, `notification_preferences`) giữ mô hình gốc. User/course refs được audit read-only: 0 orphan; chưa đổi logical reference thành FK hàng loạt.
- Polymorphic source `(source_type, source_id)` không ép vào một FK giả. Reminder/notification types hiện có: assignment/course/quiz; 0 incomplete pairs. 52 course-module instance refs đều có source tương ứng trong đúng course.

## Toàn bộ 20 views

Tất cả view SELECT thực tế thành công; **0 duplicate semantic keys** trong dataset hiện tại. Điều này không phải bằng chứng mọi dữ liệu Moodle tương lai tự động hợp lệ.

| View | Review / interpretation |
| --- | --- |
| `student_course_progress` | distinct course enrolments, tracked/completed denominator; zero tracker count không là bằng chứng tiến độ thấp |
| `student_engagement` | NULL last activity giữ unknown; recorded event count không là dự báo thất bại |
| `unified_tasks` | latest official submission/quiz attempt; 63 submitted assignment tasks đều completed, 21 chưa có submission, 24 chưa có quiz attempt |
| `student_task_summary` | completed/pending/overdue disjoint buckets; no fan-out in current source |
| `student_course_learning_items` | 002 sửa assign↔assignment; 428 rows không duplicate module/user/course |
| `student_continue_learning` | tracker + next section order; 003 loại completed assign/quiz; 0 invalid next-items sau sửa |
| `student_course_overview` | optional engagement/attendance; no-attendance remains NULL |
| `student_dashboard` | student-level aggregates; numeric defaults đọc cùng denominator, không coi absence là failure |
| `student_grade_overview` | 60 NULL grades vẫn unknown; 11 điểm 0 giữ 0; NULLIF denominator, 0 out-of-range |
| `student_grade_category_summary` | average bỏ NULL, graded count chỉ non-NULL; category grouping không fan-out |
| `student_attendance_summary` | NULLIF max score; 16 attendance/user rows, current marked count matches available sessions; absence of record không tự động absent |
| `student_learning_analytics` | grade/attendance optional; no-grade/no-attendance không thành điểm 0 |
| `student_risk_indicator` | legacy rule-based only; 002 removes invented inactivity/empty progress. Không là predictor/authority hoặc current inbox rank |
| `teacher_course_overview` | course context scoped at API; student count là enrolments/course, không unique persons toàn trường |
| `teacher_assignment_monitoring` | latest submission + attempt grade; status semantics không thay đổi grading trên LMS |
| `teacher_quiz_monitoring` | latest quiz attempt; unknown grade NULL; attempts/status không phải app quiz engine |
| `teacher_student_monitoring` | exposes tracker denominator for API unknown-signal guard; current API rechecks active student enrolment |
| `teacher_course_analytics` | grade/attendance nullable; source metrics bounded to course, no current join fan-out |
| `teacher_grade_overview` | graded/pass/fail counts respect NULL result; optional grade average |
| `teacher_dashboard` | sum course enrolments, not fabricated distinct student count; read-only aggregate |

Important raw-view caveats: attendance view is per recorded attendance activity (future multi-activity/course data must be aggregated intentionally); engagement `active_days` is calendar-day aggregation in DB session timezone (candidate `GMT`). These fields are **not current priority signals**. API ranking uses deadlines, actual task state and known tracked progress only. Council SQL sets Vietnam timezone explicitly and labels unknown progress as NULL. Do not advertise unverified attendance coverage or school-day analytics as live DLU facts.

## Index review và EXPLAIN

`EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` chạy bounded SELECTs, READ ONLY. Current small synthetic dataset/warm-cache observations, không production SLA:

| Query | Execution ms | Index decision |
| --- | ---: | --- |
| Student recommendation inputs | 3.778 | Existing source completion unique/index + small scans; không thêm speculative index |
| Student plan owner/schedule | 0.041 | `study_plan_owner_schedule_idx` được dùng |
| Teacher monitoring inputs | 40.061 | Derived aggregate expansion là phần chính; tiny tables, không có spill/repeated remote N+1 |
| Teacher due follow-up | 0.037 | Existing active-scope/owner indexes; không thêm duplicate status/date index |
| Follow-up history | 0.091 | `intervention_followup_history_idx` được dùng |

165 existing indexes giữ baseline; redundant-looking single-column/unique prefixes được ghi nhận, không DROP tự động vì không có workload/write-cost evidence để justify. Không dùng `enable_seqscan=off` để tạo kết quả nhanh giả.

## Time / NULL / security boundary

LMS source giữ Moodle-oriented epoch seconds; 0 means unset ở date fields được API `nullif(...,0)` trước `to_timestamp`. App datetimes là `timestamptz`, API offset-aware ISO instants; display/Today grouping ở Vietnam local time. Không ép historical due date sang tương lai cho demo. Không dùng missing grade/progress/engagement như điểm thấp hoặc inactivity lớn.

Catalog không có endpoint production, password, token hay database connection string. Candidate credential chỉ được đọc trong guarded configured workflow. DB owner bypass RLS là limitation thật của staging; API tests mới chứng minh principal/course isolation, SQL demo không thay thế server authorization.

## Commands / evidence / rollback

```powershell
node tool/perfection_database_audit.mjs
node tool/perfection_database_semantics.mjs
node tool/perfection_database_migration.mjs rehearse 002
node tool/perfection_database_migration.mjs apply 002
node tool/perfection_database_migration.mjs rehearse 003
node tool/perfection_database_migration.mjs apply 003
node tool/perfection_database_demo.mjs
```

Migration runner là công cụ one-time có guards; **không chạy lại migration đã applied**. Current canonical results: `evidence/database/perfection-final/catalog.json`, `semantics.json`, `query-plans.json`, `migration-rehearsal.json`, `migration-applied.json`, `003-migration-rehearsal.json`, `003-migration-applied.json`, `council-sql-verification.json`.

Private before-view backup: `D:\DLU-LMS\Backups\perfection-2026-10-07\before-views.json`, SHA256 `8D7B767F996C0F0EDA45962FBE8D7228260D40427E98494A60151B883C640905`. `before-003-views.json` là backup riêng, không ghi đè backup trước 002. Not committed. If a backend rollback is needed, deploy the previous reviewed API build; new columns/types are unchanged and checks agree with the previous workflow. Keep tables/data/checks. View-definition reversion from private backup is a **separate reviewed candidate-only operation**, not an automatic destructive down migration; never drop workflow tables or reset data.

Council queries: `database/council_pgadmin_demo.sql` — 12 SELECT resultsets execute PASS in READ ONLY transaction, bounded grids, explicit columns. pgAdmin visible workspace verification is tracked by the root QA task; a SQL runner PASS alone does not certify pgAdmin UI.

**Current database status:** schema/integrity/index/derived/NULL review PASS for current candidate and scoped API contract, with the explicit raw-view/production caveats above; pgAdmin UI NOT_VERIFIED until actual visible preparation.
