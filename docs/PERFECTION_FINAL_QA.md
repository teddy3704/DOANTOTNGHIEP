# Perfection hardening QA — 07/10/2026

STATUS: **PARTIAL** — database, deployed API, code and mobile workflows PASS;
visible pgAdmin candidate preparation awaits human credential handoff. Branch `innovation-perfection-hardening`
from preserved innovation milestone `2e04089`; `main` remains `c773b7e`.
Historical innovation/runtime PASS is retained, not reused as proof of this build.

## Completed evidence

| Gate | Actual result |
| --- | --- |
| Candidate catalog | PASS: 3 schemas; 42 tables (35 `lms`, 7 `app`); 20 views; 588 columns; 42 PK; 45 FK; 29 CHECK |
| Migration 002 | PASS: rehearsal/rollback then reviewed apply; 94 lost assignment task states corrected to 0; 5 CHECK added |
| Migration 003 | PASS: rehearsal/rollback then reviewed apply; 3 completed next-item false candidates corrected to 0 |
| Original data integrity | PASS: all 42 table row digests and column/type signatures unchanged in both migrations; three view definitions changed deliberately, not an unchanged-view claim |
| View/query review | PASS: all 20 views selectable; current semantic keys checked; bounded read-only query plans retained without speculative index changes |
| Council SQL | PASS: 12 SELECT result sets in READ ONLY transaction; SQL execution is not pgAdmin UI verification |
| Backend final checks | PASS: 96/96 tests (10.009s), typecheck/build/format-check; npm audit zero vulnerabilities |
| Flutter targeted checks | PASS: 107/107 across 13 related test files; selected-file format and scoped diff check PASS |
| Flutter final format/analyze/tests | PASS: 156 files/0 changes, analyze zero issues (20.7s), 245 tests PASS + 1 opt-in live skipped (25s); actual staging payload separately PASS |
| Responsive support UI | PASS automated at 320/390px and text scale 1.3/1.5; keyboard/forms, profile change before write and validation recovery covered |
| Real local/staging smoke | 181/181 checks each PASS; lifecycle/persistence/negative scope tests; no academic writes |
| Render | c5231e2 Live, dep-db33it7lk1mc739akldg, existing service; branch changed only, secret/database unchanged |
| Runtime | Student plan/handled/cancel/restore/isolation; Teacher action/follow-up/history/restart; actual network failure/recovery PASS |

Database evidence: `evidence/database/perfection-final/catalog.json`,
`semantics.json`, `query-plans.json`, `migration-applied.json`,
`003-migration-applied.json`, `council-sql-verification.json`.
Scope/caveats: [database audit](DATABASE_HARDENING_AUDIT.md),
[backend audit](BACKEND_HARDENING_AUDIT.md).

## Actual code corrections

- Unknown academic deadline remains `null`, never 1970/overdue. Student and
  Teacher work DTOs deliberately widen `dueAt` to `string|null`; Flutter shows
  “Chưa đặt hạn”, sorts known dates first and offers no academic-deadline reminder.
- Priority rules do not infer inactivity, zero grades or low progress when
  tracking denominator is absent. Existing numeric snapshot DTO limitation is
  retained explicitly; zero is not independently treated as an unknown signal.
- Active actor/course/enrolment is rechecked; resolved/handled lifecycle is not
  reopened by stale writes. Scoped transaction guard prevents identical follow-up
  retries within five seconds; it is not durable cross-client idempotency.
- Student editor pins its initial owner/coordinator; role/profile changes cannot
  send the old form as the new student. Duplicate pending saves remain disabled.
- API timestamps require valid calendar/time fields and an explicit offset.
  Teacher custom date picker handles an open form becoming stale across days.
- Loading provides a slow-response hint after eight seconds; staging request
  deadline is 60 seconds with cancellation, safe error/retry and no silent write
  retry or fixture fallback. Private inherited HTTP headers are removed.
- `/health` verifies essential schema surfaces, not only SELECT 1;
  `/health/live` is process liveness only. Structured backend logs use safe
  serializers and fixed error codes, not raw driver/request-body output.

## Pending final gates

| Gate | Status / required evidence |
| --- | --- |
| Full backend quality/security | PASS: 96 tests, build/typecheck/format, audit zero; evidence/perfection/backend-gates.json |
| Full Flutter quality | PASS: final 245 tests, format/analyze, separate live payload as above |
| Render hardening deployment | PASS: existing service srv-dalmjc6k1f9s738oqua0, backend c5231e2, Live 07/10 19:22:12 +07; actual staging 181 checks |
| Final emulator/runtime | PASS core workflows; current process 160 log lines, zero matched crash/ANR/RenderFlex/navigation/uncaught-async or secret patterns (bounded scope) |
| Final APK | PASS: final 21.1s corrective build/install; vn.edu.dlu.lmsmobile, min24/target36, 221247876 bytes; metadata in evidence/perfection/apk.json |
| Final mobile evidence | Actual screenshots in evidence/mobile/perfection-final; 01–12 pre-corrective QA, 13 onward accepted final artifact. 04 validation/11 postpone editor correctly named |
| pgAdmin visible preparation | PENDING: human selects/connects the existing approved candidate; never create a local database or expose connection credentials |
| Final Git/secret safety | Candidate/index scan PASS:480 files, zero actual/index secret matches/private config/forbidden artifacts; diff check PASS. Focused non-force commit/push receipt and clean preflight returned in final handoff |

Do not run already-applied migrations again or reset the database for demo.
Preflight: `powershell -File scripts/council_preflight.ps1`; a deliberate dirty
override is diagnostics only and does not turn a dirty release into READY.
Preflight requires final APK SHA256/package to match `evidence/perfection/apk.json`;
manifest generated from the actual final build, not a stale artifact.

## Runtime correction and accepted artifact

Slow Render card writes disposed the autoDispose coordinator before post-write
checks, reporting a false login error after a successful plan update. Card now
holds the original-owner subscription across await and delete confirmation.
Two regression tests and the full suite PASS. Corrected emulator markHandled,
reminder cancellation, confirmed delete and exact restore after switching roles PASS.
Rejected QA APK preserved separately; old innovation APK unchanged.

Accepted APK SHA256:
`C507877E53260B3F2C267DB87174864F1D20CF792BE3BEFF9D5E68E63AEBD26C`.
Before corrective build C33.76/D86.62GB, after C33.76/D86.26GB; tooling/cache/build
remain on D. No new AVD, package expansion or Android Studio. Build warnings:
flutter_timezone KGP future compatibility and SDK XML parser maintenance.

Student SV001 real API create/edit45→50/postpone08Oct/restart observed in QA;
final create/handled/cancel/delete and SV002 isolation PASS. Teacher GV001 sees
2 courses/8 assignments/4 students; action note → 10Oct follow-up → app restart →
update/history PASS. Snapshot stays 29%/4 overdue, no fabricated improvement.
Own QA plans cleaned after evidence; Teacher append-only QA history retained;
existing reminders and academic records untouched. GV002 verified by API, not
mobile selector (UI offers SV001/SV002/GV001). Student tracked activity progress
is not proof of official assignment submission.

Network: emulator Wi-Fi/data temporarily disabled; restart shows explicit failure,
no fixture/infinite spinner; restored connectivity and selector reload PASS.
Offline startup returns to staging selector, no offline academic browsing claim.
Official assignment launcher opens verified DLU LMS HTTPS origin; no invented
private URL or academic write. Reminder generic/private content delivered19:31
during QA; accepted final artifact delivered20:04 for20:02 schedule and tap
opened app Today correctly (30/31 screenshots). Generic launch only, not a
specific assignment deep link; inexact Android scheduling permits lateness.

Measured warm synthetic DB plans: recommendations3.778ms, plan0.041ms,
Teacher monitor40.061ms, due followup0.037ms, history0.091ms. Staging HTTP samples:
recommendation153–651ms, plan167–267ms, attention463–1300ms. Not load/SLA proof.
Index review adds no speculative index. Render Free cold start requires bounded
retry; 60s deadline/8s loading hint are deliberate. Preflight certifies public
staging/artifact, not pgAdmin or DLU auth. See PERFECTION_FORENSIC_AUDIT.md.

## Preserved limits

DLU Authentication/Web Services: **TO_VERIFY_DLU**. Staging identity aliases are
synthetic selectors, not DLU credentials. `main.dart` remains fail-closed and does
not inject staging repositories. Official submission, quiz, grading and academic
administration remain LMS ONLY. Candidate owner currently bypasses RLS and can
write source tables; guarded API statements are not a production least-privilege
database role. A dedicated SELECT-source/WRITE-app role is a production prerequisite.

Baseline innovation artifact/evidence remains preserved separately in
`INNOVATION_FINAL_QA.md`; its SHA256 must not be described as this pending APK.
