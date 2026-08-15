# Test Plan

**Status:** Schema/synthetic Student DEV milestone executable; live API contract tests blocked externally.

**Current executable test result:** `PASS — validator, analyze 0 issues, 32 tests, production/DEV debug APK builds, Android 15 production + expanded Student DEV emulator smoke`.

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

## 4. Widget test matrix

Mỗi critical screen phải kiểm thử:

| State | Expected behavior |
|---|---|
| Loading | Progress/skeleton có semantics phù hợp; không stale private data |
| Empty | Message/action phù hợp, không mô tả nhầm permission error là empty |
| Error | User-friendly classified message; không lộ raw exception/token |
| Retry | Retry đúng request; tránh duplicate WRITE |
| Success | Data formatting, navigation và capability-aware actions đúng |

Critical flow backlog: Splash, Login, Dashboard, Courses, Course Detail, Assignment Detail, Grades, Calendar, Profile và teacher-only screens khi được triển khai.

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
