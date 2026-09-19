# Database model reconciliation — 2026-09-19

**GROUP_SCHEMA_VERIFICATION = PASS. CANDIDATE_DATABASE = PASS.**
**DATABASE_TARGET = GROUP_39_20 (development target only).**

## Restored candidate and API result

Restored transactionally into `lms_mobile_learning_candidate` on the isolated
candidate branch using the private candidate configuration. Actual PostgreSQL
catalog: **3 schemas, 39 tables (35 LMS + 4 app), 20 derived views, 39 PK,
38 FK, 548 columns**. All 20 views executed. App row counts: reminders 23,
notifications 28, preferences 10, goals 6. User/enrol auth fields: zero non-NULL.

Eleven targeted ownership/duplication/bounds checks returned zero violations.
Task states: completed 88, overdue 62, pending 6. Teacher 101 owns courses 11/12;
Teacher 102 owns 13/14/3000015; shared teaching of 3000015 is legitimate.
These are synthetic development records, not DLU production records.

**STUDENT_API_COMPATIBILITY = PASS for the current contract and tested dataset.**
The new `GroupStudentDataSource` preserves public DTOs/routes, applies active
enrolment/course-context role/visibility guards, and keeps unknown file metadata
NULL. Assignment codes are adapter-owned `A-<id>` references, never Moodle links.
The fixed aliases SV001/SV002 map to reviewed synthetic users 201/202. Public
emails use `example.test` aliases instead of forwarding group-seed email values.
Both profiles, all collections, overview and own-course content returned 200.
Grades differ (5 vs 4 items); course sets match independent enrolment queries.

**TEACHER_API = PASS locally, NOT_ENABLED on Render.** GV001/GV002 map to users
101/102. Added GET-only profile, overview, courses, assignments and per-course
student monitoring. Teacher A/B cross-course requests returned 404, missing/raw/
unknown/mixed-role identities returned 401, identity query overrides returned
400, and grading POST returned 404. The API always uses read-only transactions.

Initial smoke wrongly expected shared course 3000015 to be denied to Students;
the real enrollment includes it. Corrected the test to derive negative scope
independently; targeted rerun PASS (course 13 denied), without changing data to
fit the test. Other full HTTP checks passed. Backend suite **54/54 PASS**;
TypeScript build/typecheck and formatting PASS. HTTP used a real loopback server
against candidate, not fake database responses. Candidate OpenAPI/Postman exports
are separate; running Postman itself against candidate is not claimed.

No current Neon data, Render secret, main branch or Flutter source changed.
Render remains **CURRENT_22_10** until the gated switch; Teacher Flutter stays
fixture until the deployed Teacher API is verified. Rollback/switch procedure:
`STAGING_DATABASE_SWITCH_PLAN.md`. Earlier blocked notes below are historical.

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
  The sanitized candidate seed is now prepared locally; it has not been imported.
- Physical FK counts must not include polymorphic `course_modules.instance`
  mappings. Support risk scores must not be represented as AI predictions.

## Candidate checkpoint

### Latest continuation

The user confirmed candidate credential remediation. Created the empty database
`lms_mobile_learning_candidate` on `candidate-group-39-20`, using its existing
owner. A real SQL Editor query returned that exact database name and zero
`lms`/`app`/`derived` schemas. The cloned `lms_mobile_learning` database was not
modified. Current Render and its source database remain unchanged.

Prepared ignored local files in `database/candidate/`:
`mock_data_sanitized.sql` and `restore_candidate.sql`. Sanitized all 18 user
password/secret fields and 10 enrolment password fields to NULL. The restore
is transactional, refuses any database except the named candidate, and refuses
pre-existing target schemas. Original schema definitions are retained; seed
loading precedes post-data constraints to respect foreign-key dependencies.
Only psql restrict directives and unnecessary row-security-off settings were
removed. Original group inputs are unchanged.

Browser access to the temporary loopback SQL transport was blocked by the client;
no alternate browser/network bypass was attempted. The temporary server was
stopped. No restore statement was submitted. Catalog counts and data smoke tests
remain NOT_RUN; no claim of candidate PASS or cross-user isolation is made.

**ACTION_REQUIRED_CANDIDATE_DATABASE:** privately populate
`D:\DoAnTotNghiep-flutter-student-support\integration-api\.env.candidate` with
`CANDIDATE_DATABASE_URL` for the candidate branch and database. The placeholder
file is ignored, contains no credential, and must not use the current runtime
connection. This enables the authorized CLI restore/verification without exposing
credentials through browser output. Do not post the value in chat.

No Teacher endpoint, Flutter change, Render switch or staging switch plan yet;
candidate verification remains the prerequisite. Offline counts were not rerun.

### Prior branch creation (historical)

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
