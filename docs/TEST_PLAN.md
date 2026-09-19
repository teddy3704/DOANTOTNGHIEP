# Test Plan

## Candidate backend gate

- `node tool/restore_candidate.mjs`: one guarded, transactional import PASS.
- `node tool/verify_candidate.mjs`: catalog counts, 20 views, four app tables and
  NULL auth fields PASS; `node tool/smoke_candidate.mjs`: 11 ownership/duplicate/
  aggregate-bounds checks PASS.
- `node --env-file=.env.candidate --experimental-strip-types scripts/candidate-smoke.ts`
  (inside integration-api): real local HTTP Student/Teacher endpoints and negative
  controls. Initial bad unauthorized-course expectation corrected against actual
  enrolments; `--isolation-only` rerun PASS. No academic writes performed.
- Backend final formatting/typecheck/build PASS, full suite **54 tests PASS**.
  Candidate OpenAPI/Postman exported; Postman execution is not claimed here.
- Flutter unchanged: do not repeat its 150-test/APK gate until actual Teacher API
  integration changes Flutter source. Public candidate deployment not yet verified.

## Final support gate — 19/09/2026

Format/analyze and 150 tests PASS; staging APK build/install PASS. Runtime covers
Student Render and Teacher scoped read-only fixture, role switching, reminder
persistence/toggle/scheduling and HTTPS official-LMS handoff. Future notification
delivery, DLU production API and Teacher deployed API are not claimed verified.
SQL catalog checked once; seven council demo SELECTs execute read-only. Word
claim alignment and offline demo artifacts are separate from production gates.
Exact commands, artifact hash and evidence: `FLUTTER_TEST_RESULT.md`.

**Status:** Production-polished synthetic Student DEV milestone and secure local Supabase foundation executable; live Moodle/Supabase connected tests blocked externally.

**Current executable test result:** `PASS — Moodle fixture validator, Supabase foundation validator, dart format 80 files/0 changed, analyze 0 issues, 73 tests, final production/DEV debug APK builds and Android 15 smoke tests`.

## Student Support Render staging gate — 2026-09-18

- `RENDER_STAGING_GATE=PASS`: public `/health`, `/docs` and `/openapi.json` each
  returned HTTP 200; OpenAPI 3.0.3 exposes 11 GET operations.
- `POSTMAN_STAGING_GATE=PASS`: the Render staging environment completed 17
  requests and 85/85 assertions with zero failed/skipped/errors. A separate
  status-only smoke run passed ten scoped read endpoints and six expected
  401/404/404/400/404/404 negative cases.
- These results prove only the non-production API deployment/contract. They do
  not prove Moodle DLU authentication, live data, write permission or Flutter UI.
- `STAGING_FLUTTER_CONSUMER_GATE=PASS`: config/origin/route-isolation unit tests,
  typed mapper/repository tests and read-only UI widget smoke passed together with
  `dart format .`, `flutter analyze` and `flutter test` (93 tests). The Android
  emulator verified Dashboard, Courses, Course Detail, Resource Detail,
  Assignment Detail, Grades, Calendar and Profile.
- This consumer remains deliberately read-only. It does not provide DLU password
  login, upload, submission, grading or another write workflow, and `main.dart`
  does not select it as a production fallback.

## Student Support staging UI extension — pending combined gate

The following focused coverage is part of the current read-only extension. These
tests describe the code under review; final counts and PASS/FAIL are recorded
only after one combined format/analyze/test/build/emulator run.

1. `StagingStudentIdentityProvider` restores only an allowlisted sample scope,
   clears stale data and broadcasts invalidation; it stores no password or token.
2. A staging 401 invalidates the selected scope, and `AuthController` returns to
   the unauthenticated selector state. The staging Login regression asserts that
   no password controls are rendered.
3. Assignment list widget tests cover loading, filtering/state copy, detail-route
   navigation, retry and compact-phone layout. They do not exercise a mutation.
4. Progress widget tests cover accessible course summaries plus loading, empty,
   error and retry states from `CourseRepository` data.
5. App-shell tests cover five Student Support destinations and Calendar as a
   contextual route from Dashboard rather than an additional primary destination.
6. `OfficialLmsLauncher` tests permit only the canonical HTTPS official LMS
   origin, reject arbitrary/non-HTTPS targets and surface a safe failure when the
   platform cannot open the handoff. No activity URL is synthesized.
7. Local reminder tests cover secure minimal persistence, owner isolation,
   immutable academic references, duplicate/time validation and scheduler rollback.
   Scheduler tests cover runtime notification permission, generic copy,
   deterministic cancellation and safe error mapping. Editor and manager widget
   tests cover create/update, loading, enable/disable and confirmed deletion.

`flutter analyze` currently reports no issues and the complete `flutter test`
suite passes **137 tests**. The extension remains pending its final `dart format`,
debug APK and Android emulator walkthrough; notification delivery is not inferred
from unit/widget tests.

## Product UI polish gate — 2026-08-16

1. Automated demo flow bao phủ Login → Trang chủ → Khóa học → Course Detail → Assignment → Grades → Lịch → Hồ sơ và kiểm tra logout.
2. App shell test khóa đúng bốn destination `Trang chủ`/`Khóa học`/`Lịch`/`Hồ sơ` cùng hành vi phone/large layout.
3. Dashboard, Courses, Course Detail, Assignment, Grades, Calendar và Profile có widget tests cho các state quan trọng; retry được test ở màn hình có data request.
4. Presentation-copy regression quét widget tree để ngăn các từ kỹ thuật hoặc nhãn phát triển bị render; production Login tiếp tục không có credential fields và không lộ raw blocker code.
5. Fixture repository tests từ chối Course Detail/Assignment/Grades không thuộc enrolment và khóa cách tính progress theo visible modules.
6. Calendar test khóa thứ tự/group ngày và friendly event labels; Course Detail test khóa nullable deadline và resource sheet behavior; Profile test khóa theme setting/logout và identity tối thiểu.
7. Emulator evidence gồm 8 ảnh tại `docs/screenshots/production-polish/`, theo thứ tự `01-login.png` đến `08-profile.png`.

Kết quả đã chạy cho code product-polish:

| Check | Result |
|---|---|
| `dart format .` | PASS — 66 files, 0 changed |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 50/50 |
| DEV + production-entrypoint debug APK | PASS — both built on D |
| Android 15/API 35 direct walkthrough | PASS — full student presentation flow |
| Production APK fail-closed smoke | PASS — 0 credential fields, 0 technical/dev copy match |

Default tests vẫn chạy offline, không gọi DLU, không dùng account/token thật và không coi synthetic fixture là live integration.

## Moodle subset and canonical fixture gate — 2026-08-15

1. Chạy `dart run tool/generate_moodle_sample_data.dart` hai lần và so sánh JSON/SQL hash.
2. Chạy `dart run tool/validate_moodle_sample_data.dart` để kiểm table count, PK uniqueness, FK/local-convention integrity, enrolment uniqueness, required fields, assignment/grade state coverage và privacy markers.
3. Parser asset phải xác nhận seed `202608`, 20 selected tables, 23 synthetic users, 4 categories và 6 courses.
4. Repository tests bao phủ user→enrolment→course, course→sections/activities, resource metadata, assignment/submission states, grade mapping và upcoming events.
5. Widget tests bao phủ loading/populated/error/retry cho Assignment; loading/populated/empty/error/retry cho Grades; DEV flow bao phủ navigation Assignment và Grades.
6. Production repository tests xác nhận mọi student repository mới trả `MOODLE_WEB_SERVICES_NOT_ENABLED`, không trả fixture.

Default tests chạy offline, không dùng DLU session, token, credential, private content hoặc network call.

## 1. Objectives

- Chứng minh parsing/repository/error logic đúng với contract đã xác minh.
- Chứng minh UI luôn có loading, empty, error/retry và success behavior phù hợp.
- Chứng minh token/PII không bị log hoặc cache sai.
- Chứng minh student/teacher boundaries được Moodle enforcement và client xử lý đúng.
- Chứng minh app analyze/test/build thành công bằng CLI, không Android Studio.

## 2. Test pyramid

| Level | Scope | Tools dự kiến | Khi chạy |
|---|---|---|---|
| Static | Format, lints, type/null safety | `dart format`, `flutter analyze` | Mỗi task/CI |
| Unit | DTO parsing, mapper, error mapping, repositories, use cases, redaction | `flutter_test`, `mocktail` nếu cần | Mỗi task/CI |
| Widget | Critical screen states, navigation guards, accessibility basics | `flutter_test` | Mỗi feature/CI |
| Contract | Sanitized Moodle response schemas and exception envelopes | Fixture-driven + approved live probes | Sau API discovery |
| Integration | Login/session/course flow, secure storage, file behavior | `integration_test`, test LMS/account | Milestone; authorized environment |
| Build/device | Debug APK and physical/emulator smoke | Flutter/ADB CLI | Milestone |
| Security/manual | Permission negatives, log/PII review, deep links, network failure | Checklist + approved tooling | Phase 8/release |

## 3. Unit test backlog

### Core/network

- Base URL validation and HTTPS production enforcement.
- Timeout/network/HTTP/Moodle exception classification.
- Invalid/expired token → `AuthenticationFailure`.
- Capability/access error → `PermissionFailure`.
- Unexpected response → `ParsingFailure`, no raw PII leak.
- Retry only idempotent read request and only transient failures.
- Redactor removes token/password/tokenized URL/PII fields.

### Authentication

- Authentication state transitions.
- Token stored only after approved auth result and verified site/user info.
- Failed verification removes partial session.
- Logout clears token and user-scoped cache.
- Concurrent session/user switch cannot expose prior user's data.

### Feature repositories

- Moodle DTO → domain entity mapping for missing/optional/version-specific fields.
- Empty course/assignment/grade/event collection.
- Permission and partial-data cases.
- Production repository never falls back silently to mock.

### App-owned local reminders

- Persist and restore only opaque owner/course/assignment references, timestamps
  and enabled state; assert academic title/grade/submission/password fields are
  absent.
- Reject cross-owner enable/update/delete, changing an academic reference,
  duplicate reminders, reminder times at/after a due time, and enabled reminders
  in the past.
- On persistence failure, restore the previous device scheduler state where the
  platform permits it; map storage/scheduler failures to a safe Vietnamese
  message.
- Request Android notification permission only when an enabled reminder is
  scheduled. Assert the scheduled copy is generic and never includes an
  assignment/course/file/grade value.

## 4. Widget test matrix

Mỗi critical screen phải kiểm thử:

| State | Expected behavior |
|---|---|
| Loading | Progress/skeleton có semantics phù hợp; không stale private data |
| Empty | Message/action phù hợp, không mô tả nhầm permission error là empty |
| Error | User-friendly classified message; không lộ raw exception/token |
| Retry | Retry đúng request; tránh duplicate WRITE |
| Success | Data formatting, navigation và capability-aware actions đúng |

Critical student presentation flow hiện đã được tự động hóa: Splash, Login, Dashboard, Courses, Course Detail, Assignment Detail, Grades, Calendar và Profile. Teacher-only screens vẫn là backlog và chỉ được test sau capability/environment approval.

The current extension adds widget coverage for the local reminder editor and
manager. Manual Android verification must still prove the permission prompt,
scheduled delivery, enable/disable and deletion behavior without claiming a
Moodle notification.

## 5. API contract verification

Không ghi test `PASS` chỉ từ generic Moodle documentation. Mỗi function cần:

- live DLU function availability evidence;
- synthetic/sanitized success response fixture;
- empty response fixture;
- invalid-token and permission-denied fixture;
- version-specific optional/missing field coverage;
- student and teacher context result where applicable.

Fixtures không chứa tên/email/student ID/grade/submission thật.

## 6. Integration scenarios

### Read-only milestone

1. Launch → Splash.
2. Login bằng approved DLU flow.
3. Verify site/user info.
4. Dashboard hiển thị identity tối thiểu.
5. My Courses lấy dữ liệu thật.
6. Course Detail/content lấy dữ liệu thật.
7. Invalid/expired token chuyển về safe re-authentication.
8. Offline/timeout hiển thị retry và không blank screen.

### Student permission negatives

- Không đọc grades/submissions/profile của user khác.
- Không xem hidden/restricted course content.
- Không gọi teacher/grading action.

### Teacher scenarios

- Read roster/submission only trong course/context được phép.
- WRITE grading/feedback chỉ trên staging/test với explicit approval.
- Duplicate request/retry không tạo duplicate mutation.

## 7. Non-functional tests

- Accessibility: text scaling, semantics, contrast, touch target, keyboard where applicable.
- Responsiveness: common Android phone sizes/orientations; tablet later if scoped.
- Performance: first meaningful screen, large course/assignment lists, image/file memory behavior.
- Reliability: slow network, timeout, connection loss, server 5xx, malformed payload.
- Privacy: screenshot/log/cache artifacts không chứa secret hoặc unnecessary PII.
- Localization/time: Vietnamese text, timezone handling, daylight/time boundary, server timestamps.

## 8. Phase quality gates

Khi Flutter project tồn tại:

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

| Gate | PASS condition |
|---|---|
| Format | Không có file cần format lại |
| Analyze | 0 error; warning policy được xử lý/ghi nhận rõ |
| Tests | 0 failing test; skipped tests có lý do/blocker |
| Debug build | APK build thành công bằng Android CLI toolchain |
| Live integration | DLU-approved environment/account và evidence record tồn tại |
| Release build | Signing/config hợp lệ do owner cung cấp; không secret giả |

Không gọi phase `PASS` nếu bất kỳ required gate nào fail.

## 9. Phase 0 verification

| Check | Result |
|---|---|
| Repository inventory | PASS — initial repository empty except `.git` |
| Git status/version | PASS |
| Flutter/Dart doctor | FAIL — commands unavailable |
| Android SDK/ADB/device | FAIL/BLOCKED — commands unavailable |
| Flutter analyze/test/build | N/A — no project and no toolchain |
| Documentation consistency | PASS — required files, relative links, secret patterns and whitespace checked |

## 10. Phase 2 verification

- Unit tests cover HTTPS/dev-fixture config guards, network path/auth fail-closed behavior, auth state and unconfigured production repositories.
- Widget test covers DEV flow from login through dashboard, courses, course detail and profile at 390×844.
- Widget test asserts the Splash state before DEV session restoration completes.
- Courses widget tests verify loading → empty and classified error → retry behavior.
- Production and development Android debug entrypoints both build successfully.
- Android 15/API 35 x86_64 emulator smoke test covers Splash, login, dashboard, courses, course detail, profile and logout.
- PID-scoped runtime log review reports 0 crash, ANR, Flutter exception or RenderFlex overflow.
- Physical-device smoke remains TODO when a device is available; it no longer blocks the emulator demo milestone.

## 11. Phase 3B verification — 2026-08-14

- Production Login widget test verifies both integration blockers, no DEV label, no credential field and no submit button.
- Viewport regression test resizes Login below its outer padding after Splash to prevent the emulator cold-launch `negative minimum height` bug from returning.
- Config tests reject missing host, userinfo, path, query, fragment and non-HTTPS base URLs; canonical origin normalization is verified.
- Network diagnostic tests use synthetic sentinels to prove raw Dio exceptions, headers, request/response body, query values, arbitrary PII slugs and cross-origin paths do not leak.
- Origin-gate regression injects a mismatched Dio base URL and proves the request is rejected before authorizer/network execution, then rechecked after authorization.
- Provider lifecycle test proves Courses, Course Detail and Profile data providers dispose and reload instead of retaining data across released session/listener boundaries.
- `dart format .`: PASS — 40 files, 0 changed on final run.
- `flutter analyze`: PASS — 0 issues.
- `flutter test`: PASS — 21/21.
- `flutter build apk --debug`: PASS for production; DEV fixture was also built/run separately.
- Production emulator smoke: blocker semantics present, 0 editable credential fields, visual review PASS and PID log scan found 0 crash/widget exception/overflow.
- DEV emulator smoke: synthetic Login → Dashboard → Courses → Course Detail → Profile → Logout PASS; PID log scan found 0 matching runtime error.
- Live DLU API tests remain uncreated by design because Web Services currently return `enablewsdescription`; default tests never call production DLU.

## 12. Supabase foundation verification — 2026-08-16

- Offline validator yêu cầu đúng một `mobile_preferences` migration, UUID PK, theme allowlist, RLS enable + force, ba own-row policy, column-scoped grants và không clone Moodle/anon/DELETE/`using(true)`.
- Flutter unit tests cover HTTPS/key allowlist, opaque/user/secret/service-role rejection, missing-config fail-closed, injected JWT callback, anonymous/missing identity, owner filter, ownership mismatch, typed DTO/repository và malformed response.
- Error tests cover sanitized PostgREST auth (`PGRST301/302/303`), RLS (`42501`), timeout (`PGRST003`), unavailable (`PGRST000/001/002`), defensive `429` rate-limit và unknown client/backend failures.
- `supabase/tests/database/mobile_preferences_rls.test.sql` có 28 pgTAP assertions cho policy/grant, fixed invoker RPC, cross-owner INSERT và owner A/owner B/anonymous/anon contexts. File này chỉ chạy trên local/dev Postgres đã apply migration; chưa chạy vì không cài Docker và repository chưa link project remote.
- Final offline gate: format 80 files/0 changes, analyze 0 issues, Flutter tests 73/73, static Supabase validator PASS.
- Production + development debug APK build PASS sau dependency update; emulator production fail-closed và DEV Dashboard smoke đều có 0 runtime error match/0 user-visible technical string.
- Remote gate còn BLOCKED: apply migration trên non-production project, pgTAP connected run, Security/Performance Advisors và one-login identity isolation tests.
