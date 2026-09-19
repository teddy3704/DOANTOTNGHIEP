# Database model reconciliation — 2026-09-19

**GROUP_SCHEMA_VERIFICATION = PASS (offline DDL only).**
**CANDIDATE_DATABASE = BLOCKED. DATABASE_TARGET = UNRESOLVED.**

## Verified inventories

| Metric | CURRENT_RUNTIME_MODEL (previous catalog check) | GROUP_TARGET_MODEL (supplied DDL) |
|---|---:|---:|
| Schemas | 1 (`lms`) | 3 (`lms`, `app`, `derived`) |
| Physical tables | 22 | 39 |
| LMS tables | 22 | 35 |
| App tables | 0 | 4 |
| Views | 10 (`lms`) | 20 (`derived`) |
| Primary keys | 22 | 39 |
| Physical foreign keys | 35 | 38 |
| Physical-table columns | 135 | 548 |

Input: `D:\DoAnTotNghiep-group\lms_mobile_learning_schema.sql`, read-only.
SHA256: `cbcf93bf99bb3fe3153980ddc9ca0e976f374b26fd3c436e30e9cee0e07a1867`.
Command: `node tool/inspect_group_schema.mjs D:\DoAnTotNghiep-group\lms_mobile_learning_schema.sql`.
The inspector cross-checks CREATE TABLE definitions against pg_dump headers.
These are definition counts, **not proof of a successful restore or query**.
The two Word files and mock SQL match the previously reviewed copies by hash;
originals were not modified. No repeated Word analysis was needed.

## Differences and disposition

- **KEEP:** current 22/10 runtime; Node/Fastify backend; Student API contract;
  scoped role/context and enrolment semantics; official operations on DLU LMS.
- **ADD:** group definitions contain all 13 requested Student read models and
  7 Teacher read models, including `unified_tasks`, `student_dashboard`,
  `teacher_dashboard` and `teacher_student_monitoring`. App tables are
  `learning_goals`, `learning_reminders`, `notification_preferences`,
  `notifications`. Their runtime behavior is not yet verified.
- **CHANGE:** plural current table names and `lms.vw_*` read models differ from
  group `lms.user`, Moodle-style entities and `derived.*` views.
- **INCOMPATIBLE / NEEDS_ADAPTER:** a direct connection switch is not safe.
  Preserve Flutter contracts through a backend adapter after catalog/smoke
  verification; Teacher API is still NOT_IMPLEMENTED, Flutter Teacher = fixture.
- The group `lms.user.password` column is nullable. A future sanitized seed must
  use NULL for password/secret, never implement login from mock credentials.
  No sanitized candidate seed has been imported or created at this checkpoint.
- Physical FK counts must not include polymorphic `course_modules.instance`
  mappings. Support risk scores must not be represented as AI predictions.

## Candidate checkpoint

No existing local PostgreSQL server/tool installation was found in the targeted
checks. Created one Free Neon child branch, **candidate-group-39-20**, in the
existing Singapore project. Branch ID: `br-sweet-bread-b3o5dkrz`; no auto-delete.
It is a clone of the existing development branch, **not an empty 39/20 database**.
No schema restore, seed import, catalog smoke test or API adapter was performed.
Current Neon and Render configuration were not changed.

Neon's automatically opened connection dialog exposed a credential in a tool
result. It was immediately hidden/closed; the value was not copied into files,
source, documentation or screenshots, and was not used for a connection.
Human credential rotation is required before resuming candidate work.

**ACTION_REQUIRED_CANDIDATE_DATABASE:** the user must rotate the exposed role
credential on the candidate branch directly in Neon, without posting the value
in chat; keep the current branch and Render secret unchanged.

Next, create an empty database on this isolated branch, restore only the supplied
DDL and sanitized seed, verify catalog and targeted Student/Teacher views, then
implement and test the minimum read-only adapter. Do not switch Render until all
candidate, Student compatibility and backend gates pass. A final staging switch
plan is not yet authorized by those gates.
