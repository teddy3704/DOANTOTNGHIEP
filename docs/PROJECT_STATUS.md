# Project Status

## Candidate restore and local Student/Teacher API — PASS

Actual candidate catalog matches 3 schemas / 39 tables / 20 views / 39 PK /
38 FK / 548 columns. All views and four app tables queried; 11 scope/duplicate/
bounds checks PASS. NULL auth fields verified. Node/Fastify GROUP_39_20 adapter
preserves Student contracts and adds minimum scoped read-only Teacher API.
Real local HTTP positive/negative checks PASS after correcting one erroneous
negative-course fixture; backend **54 tests PASS**, typecheck/build/format PASS.

Target development model: GROUP_39_20. Current Render/current Neon: **22/10,
unchanged**. Teacher API local PASS, public deployment pending. Flutter remains
unchanged (Student Render + Teacher fixture); prior 150 Flutter tests/APK retained.
Next: backward-compatible backend deployment and gated secret switch according
to `STAGING_DATABASE_SWITCH_PLAN.md`, then deployed Teacher verification before
Flutter injection changes. Details: `DATABASE_MODEL_RECONCILIATION.md`.

## Candidate continuation — credential remediation confirmed

**ACTION_REQUIRED_CANDIDATE_DATABASE:** user confirmed credential remediation;
created `lms_mobile_learning_candidate` on the existing isolated candidate branch.
SQL Editor verified its exact name and zero target schemas. Prepared ignored,
sanitized seed/transactional restore files; no import yet. CLI requires candidate
connection in ignored `integration-api/.env.candidate`; current `.env` is not used.
Browser loopback file transport was blocked, so no bypass was attempted.
Render/current Neon/Flutter/main unchanged. Catalog/smoke/Teacher API gates remain
pending. See `DATABASE_MODEL_RECONCILIATION.md`; prior blocker details are history.

## 2026-09-19 — Group schema received; isolated candidate checkpoint

**PARTIAL / ACTION_REQUIRED_CANDIDATE_DATABASE.** Offline group DDL verification
PASS: 3 schemas, 35 LMS + 4 app tables, 20 derived views, 39 PK, 38 FK, 548 columns.
The missing schema is now available in read-only `D:\DoAnTotNghiep-group`.
Created Free Neon branch `candidate-group-39-20`; no restore/import or switch.
Candidate runtime verification is BLOCKED pending human credential rotation
after an automatically opened connection dialog exposed a secret in tool output.
No secret is reproduced in project files. Current Neon and Render are untouched.

Student compatibility with the group model: NEEDS_ADAPTER. Teacher API remains
NOT_IMPLEMENTED; Student Render / Teacher scoped fixture and the previous 150
tests/analyze/APK PASS are preserved, not rerun. No Flutter/backend source changed.
Details and exact continuation: `DATABASE_MODEL_RECONCILIATION.md`.
Older “group schema missing” entries below are historical and superseded.

## 2026-09-19 — Council alignment and current result

**PARTIAL overall.** Student runtime PASS; Teacher read-only fixture runtime
PASS, Teacher API not deployed. Active worktree remains
`D:\DoAnTotNghiep-flutter-student-support` / `flutter-student-support-v1`.

- Final format/analyze PASS; 150 tests PASS. APK/runtime evidence:
  `FLUTTER_TEST_RESULT.md`. Original C: and D: source checkouts preserved.
- User granted Android notification permission. Save/restore across role change
  and restart, enable/disable, and Android scheduling verified. Delivery at the
  future reminder time is not claimed. Both roles opened the official LMS.
- Catalog checked once: **lms only; 22 tables; 10 views; 22 PK; 35 FK; 135 columns**.
  Group report's 3-schema/39-table model is a different baseline. Word originals
  unchanged; exact corrections in `REPORT_ALIGNMENT_NOTES.md`.
- One authoritative backend: Node/Fastify, existing Render health PASS. Student
  uses Render; Teacher uses explicit scoped fixture, never production fallback.
- `demo/` contains tested SELECTs, checklist and council script. Local backup:
  current DDL/seed/OpenAPI and separate auth-disabled group seed copy. No SQL
  import, academic write, backend replacement or redeployment.
- Remaining: group schema export; Teacher API/contract integration; DLU-approved
  auth/Web Services. Obtain the schema and agree a separately tested migration;
  do not overwrite working Neon to make report counts match.

Entries below are historical; their pending runtime notes are superseded here.

## 2026-09-18 — Current Student + Teacher Support checkpoint

**PARTIAL: code/quality/APK PASS; final runtime walkthrough awaiting Android
notification permission.** Continue in existing isolated worktree
`D:\DoAnTotNghiep-flutter-student-support`, branch `flutter-student-support-v1`.
Original C: and dirty D: source checkouts are preserved. Only requested evidence
artifacts are added under `D:\DoAnTotNghiep\evidence\mobile`.

- Format/analyze PASS; 150 tests PASS; final staging APK built and installed.
- Student = verified Render read API. Teacher = explicit canonical Moodle-like
  read-only fixture with course-context scoping; not a deployed Teacher endpoint.
- No Mobile academic writes, independent account system or production fallback.
- Student runtime checked through reminder editor; Android Allow prompt currently
  needs human input. Teacher runtime and LMS handoff remain pending, not PASS.
- DLU production auth/Web Services: TO_VERIFY_DLU. Render/Neon/Postman gates
  remain unchanged; not recreated or retested unnecessarily.
- Exact evidence and next step: `FLUTTER_TEST_RESULT.md`. No final commit yet.

The entries below record earlier checkpoints; this section is current.

## 2026-09-18 — Student Support staging UI extension

**STATUS: IN PROGRESS — local read-only implementation; analysis and the full
test suite pass, while the final APK/emulator gate is pending.** This extension stays inside the explicit
`main_staging.dart` composition root. It does not alter `main.dart`, add DLU
authentication, or claim a production Moodle contract.

- The staging Login now selects one approved sample student scope instead of
  rendering password controls. Only the non-secret sample student code is kept
  in platform-backed storage; it is neither a DLU account nor an authorization
  grant. Invalid or rejected staging identity responses clear that local scope
  and return the app to its selection state.
- Student Support navigation now exposes **Trang chủ**, **Khóa học**, **Bài
  tập**, **Tiến độ** and **Hồ sơ**. Calendar remains a contextual route from
  the Dashboard, not a hidden sixth primary destination.
- The new Assignment list uses only the documented read endpoints for status,
  deadlines and published grades. It has no submit, upload, grading or other
  mutation control. Assignment Detail can hand the user to the canonical
  official LMS home through the platform external-browser mechanism; it does
  not synthesize an activity URL or fabricate a DLU deep link.
- The Progress screen is a read-only course summary using server-supplied
  progress values; it has no completion-update control or locally inferred GPA.
- SV-10 is now an **app-owned local reminder** extension. Assignment Detail can
  create or edit a reminder before its due time, while Profile links to the
  owner-scoped reminder manager for enable/disable and deletion. The local record
  contains only opaque owner/course/assignment references, due/reminder times and
  the enabled setting; it does not persist assignment text, grades, submissions,
  credentials or a Moodle payload.
- A user-enabled reminder is scheduled as a generic Android local notification
  after the platform permission request. It is not a Moodle notification and does
  not send a Render, Neon or Moodle write request. Device delivery and the final
  APK/emulator walkthrough remain pending, so this is not yet claimed as an
  emulator-verified notification feature.
- Focused unit/widget coverage has been added for selection/invalidation,
  read-only navigation, assignment/progress states, official-LMS origin
  allowlisting and local reminder persistence/scheduling/editor/list behavior.
  `flutter analyze` reports no issues and `flutter test` passes all 137 tests.
  `dart format .`, Android build and emulator re-verification must still run
  together before this extension is promoted to `PASS`.

## 2026-09-18 — Render staging verification

**STATUS: PASS — development/staging deployment only.** The dedicated branch
`integration-api-render-staging` is deployed at
`https://dlu-lms-student-support-staging.onrender.com`; it remains separate from
`main`, with no merge, force-push, production LMS request, database migration or
seed operation.

The Render Node Free service uses root `integration-api`, Node 24.15.0, the
documented build/start commands and `/health`. Its verified source commit is
`e241f8a`. The database secret was entered privately by the user; no secret value
was read, copied, logged, photographed or committed.

Public `/health`, `/docs` and `/openapi.json` returned HTTP 200. The OpenAPI
document is 3.0.3, uses same-origin `/`, and exposes 11 GET operations. A public
19-check smoke run passed: ten read-only student endpoints returned 200 and all
six expected negative security cases returned 401/404/400/404/404 as designed.
Postman ran the staging environment successfully: 17 requests, 85/85 assertions,
zero failed/skipped/errors. The reviewed Render deployment log contained no
database credential or connection string.

**RENDER_STAGING_GATE: PASS. POSTMAN_STAGING_GATE: PASS.
STAGING_FLUTTER_CONSUMER_GATE: PASS (read-only).** The isolated clean worktree's
explicit `main_staging.dart` composition root is separate from `main.dart` and
uses the Student Support staging API boundary only. `dart format .`,
`flutter analyze` and `flutter test` (93 tests) passed; Android emulator
verification covered Dashboard, Courses, Course Detail, Resource Detail,
Assignment Detail, Grades, Calendar and Profile. The consumer has no DLU password
login, upload, submission, grading or other write workflow, and none is
fabricated. It is not evidence of production Moodle authentication or write access;
production Moodle remains `BLOCKED_EXTERNAL`. Earlier database/API/local Postman
results are retained, not restated as production Moodle verification. Authoritative
evidence: `INTEGRATION_STATUS.md` and `ADVISOR_EVIDENCE_INDEX.md`.

**Cập nhật:** 2026-09-18 (Asia/Saigon)

**Milestone:** Production UX Polish + Moodle Schema/Synthetic Student Core + Secure Supabase Foundation

**Trạng thái milestone:** `PASS_LOCAL / BLOCKED_EXTERNAL` — product UI, deterministic synthetic data, 73 automated tests, Android emulator và local Supabase migration/RLS/client contract đều PASS; remote services còn gated

**Trạng thái production live:** `PARTIAL / BLOCKED_EXTERNAL` — DLU Web Services vẫn disabled; live API/auth integration chưa được phép triển khai

## Executive summary

Repository greenfield đã được scaffold thành Android-only Flutter project, application ID tạm thời `vn.edu.dlu.lmsmobile`. Phase 2 foundation và UI demo flow đã chạy qua format/analyze/test/debug build, Android 15 emulator smoke test và runtime log review.

Production entrypoint không phụ thuộc mock; do DLU authentication/Web Services chưa được xác nhận, production repository fail closed và hiển thị thông báo thân thiện, không lộ blocker code hay trường credential. Development entrypoint riêng inject dữ liệu synthetic có nhãn nội bộ để kiểm thử/demo nhưng không đưa các nhãn `DEV`/`FIXTURE`/`MOCK` hoặc chi tiết kỹ thuật ra giao diện sinh viên.

Theo chỉ đạo mới nhất của GVHD, phase database không cần database/dump/data thật của DLU. Nhóm đã phân tích trực tiếp teacher-provided SchemaSpy Moodle LMS 3.9/MySQL 5.7.31, chốt `MOODLE_SUBSET_V1` gồm 20 bảng, tạo `PROJECT_SUBSET_SCHEMA`, seed/JSON deterministic với seed `202608`, validator integrity/privacy và tài liệu feature→table/join/ERD/CRUD. Nguồn này được gắn `TEACHER_SCHEMA_REFERENCE`, không bị gọi là production schema DLU.

DEV app đã bỏ hard-code fixture rời rạc và dùng một canonical JSON qua `SyntheticFixtureDataSource`. Student flow hiện render nhất quán Trang chủ/Khóa học/chi tiết học phần/tài nguyên/Bài tập/Điểm/Lịch/Hồ sơ. Product-polish milestone đã thay nội dung thiên về kỹ thuật bằng ngôn ngữ sinh viên, chuẩn hóa hierarchy/tokens/loading state và chốt navigation responsive `Trang chủ` / `Khóa học` / `Lịch` / `Hồ sơ`. Production composition root không inject các adapter này và tiếp tục fail closed.

Phase 3B đã dùng chính browser session hiện có để xác minh read-only Dashboard, My Courses, một course đại diện, Profile, Calendar, own-grades navigation, notifications/messages navigation và course activity/resource metadata. Không lưu tên user/course, ID, grade, message, cookie/token hoặc `sesskey`.

Hai token/mobile site-check request không credential trả `errorcode=enablewsdescription`; REST entrypoint trả `403`. Vì vậy DLU hiện báo Web Services chưa được bật, `0` function đạt `VERIFIED_API`, mobile auth strategy vẫn `UNKNOWN`, và không có live DTO/repository nào được dựng từ HTML. Flutter production đã được harden để không hiển thị username/password; DEV fixture vẫn tách riêng.

## Repository audit

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Git repository | `.git` tồn tại; `main`; Phase 2 baseline commit `67953f8` | DONE |
| Uncommitted work | Không có file tracked/untracked tại thời điểm audit ban đầu | DONE |
| `README.md` | Không tồn tại trước audit; đã tạo entry point Phase 0 | DONE |
| `pubspec.yaml` | Flutter/Riverpod/go_router/Dio/secure storage/Supabase typed client | DONE |
| `lib/` | Feature-first foundation + demo milestone UI | DONE (Phase 2 scope) |
| `test/` | 73 unit/widget tests | DONE |
| `android/` | Android-only scaffold, `vn.edu.dlu.lmsmobile`, security baseline | DONE (debug) |
| `docs/` | Không tồn tại trước audit; baseline được tạo ở Phase 0 | DONE |
| `.gitignore` | Không tồn tại trước audit; baseline bảo mật được tạo | DONE |
| Environment/config files | `AppConfig` + Dart define, no committed secret | DONE |
| Existing UI/API/models | Implemented foundation; live DLU DTOs deferred | PARTIAL |
| `AGENTS.md` | Không tồn tại trước audit; đã tạo | DONE |

## Environment audit

| Command/component | Kết quả quan sát | Trạng thái |
|---|---|---|
| `git --version` | `git version 2.54.0.windows.1` | PASS |
| `flutter --version` | Flutter 3.44.9 stable | PASS |
| `dart --version` | Dart 3.12.2 | PASS |
| `flutter doctor -v` | Flutter/Windows/Android/network/device PASS; no issues | PASS |
| `java` | Temurin OpenJDK 17.0.20+8 | PASS |
| Android CLI | Command-line Tools 22.0; SDK/build-tools 36 | PASS |
| `adb version` | ADB 37.0.1 | PASS |
| `adb devices -l` | `emulator-5554` online, Android 15/API 35 x86_64 | PASS |
| `flutter devices` | `sdk gphone64 x86 64`, Android 15/API 35 | PASS |
| `ANDROID_HOME` | `D:\DLU-LMS\Android\Sdk` | PASS |
| `ANDROID_SDK_ROOT` | `D:\DLU-LMS\Android\Sdk` | PASS |
| `ANDROID_AVD_HOME` | `D:\DLU-LMS\Android\AVD` | PASS |
| `ANDROID_EMULATOR_HOME` | `D:\DLU-LMS\Android\EmulatorHome` | PASS |
| `GRADLE_USER_HOME` / `PUB_CACHE` | `D:\DLU-LMS\Caches\Gradle` / `D:\DLU-LMS\Caches\Pub` | PASS |

Toolchain được cài user-local, không dùng Android Studio. Hướng dẫn/trạng thái máy hiện tại nằm tại [ENVIRONMENT_SETUP-DESKTOP-BMK6MGL.md](ENVIRONMENT_SETUP-DESKTOP-BMK6MGL.md).

## DONE

- Audit toàn bộ nội dung repository hiện có (repository ban đầu rỗng).
- Ghi nhận Git state và toolchain state.
- Thiết lập quy tắc dự án lâu dài trong `AGENTS.md`.
- Tạo baseline documentation, architecture proposal, API/database discovery skeleton, security plan và test plan.
- Tạo `.gitignore` chặn secret, signing key, database dump và output sinh tự động.
- Lập backlog Phase 0 → Phase 9 và blocker register.
- Cài và xác minh Flutter/Dart/JDK/Android CLI toolchain; chấp nhận Android licenses.
- Scaffold Flutter Android project với package ID `vn.edu.dlu.lmsmobile`.
- Triển khai Material 3, Riverpod, go_router, Dio client boundary, error taxonomy và secure token storage abstraction.
- Triển khai Splash → Login → Dashboard → Courses → Course Detail placeholder → Profile.
- Tách `main.dart` production khỏi `main_development.dart` DEV fixture.
- Build production shell và DEV fixture debug APK thành công.
- Cài `system-images;android-35;google_apis;x86_64` revision 9 và tạo `DLU_LMS_Pixel` hoàn toàn trên D.
- Boot AVD bằng WHPX; `adb devices -l`, `flutter devices` và `flutter doctor -v` nhận emulator Android 15/API 35.
- Chạy thực tế DEV app qua Splash/Login/Dashboard/Courses/Course Detail/Profile/Logout; runtime log có 0 crash, ANR, Flutter exception hoặc overflow.
- Thay native Android splash/logo Flutter mặc định bằng generic academic mark theo palette app; đây chưa phải logo DLU chính thức.
- Chụp bộ screenshot emulator tại `docs/screenshots/emulator/`.
- Hoàn tất Phase 3A public read-only discovery cho `https://lms.dlu.edu.vn/`: DNS/HTTPS/TLS/redirect, Moodle identity, public structure và login surface.
- Xác minh login page có local username/password form và `Google Login` qua Moodle OAuth2; không nhập credential và không suy đoán backend auth/mobile-token support.
- Tạo evidence docs tại `docs/live-dlu/`; không lưu cookie value, token, credential hoặc PII.
- Phase 3A quality gate PASS: `dart format` 39 files/0 changed, analyze 0 issues, 13 tests PASS; OneDrive cloud-placeholder conflict được bảo toàn dưới ignored stale path và build target D không bị xóa.
- Xác minh authenticated session và lập feature/network/data/evidence/traceability maps với exact evidence labels; browser session được bàn giao lại tại `/my/` vẫn authenticated.
- Xác minh `MOODLE_WEB_SERVICES_NOT_ENABLED` qua `/login/token.php?appsitecheck=1` trả `enablewsdescription`; REST entrypoint trả `403`; không gửi credential/token/service shortname.
- Production Login không còn thu username/password khi auth strategy chưa được xác nhận; hiển thị hai blocker `AUTHENTICATION_METHOD_UNCONFIRMED` và `MOODLE_WEB_SERVICES_NOT_ENABLED`.
- `AppConfig` chỉ nhận credential-free HTTPS origin; client chặn origin lệch trước authorization và kiểm tra lại trước network; network failure không giữ raw Dio exception/header/body/query/cross-origin path và có sentinel redaction tests.
- Course/detail/profile Riverpod providers dùng `autoDispose`; regression test xác minh cache được giải phóng và tải lại giữa listener/session boundaries.
- Sửa runtime launch bug `negative minimum height` phát hiện trên emulator và thêm regression viewport test.
- Phase 3B final gate PASS: format 40 files/0 changed, analyze 0 issues, 21 tests PASS, production + DEV debug APK builds PASS.
- Emulator PASS: production blocker có 0 credential field và 0 runtime-error match; DEV synthetic flow Login → Dashboard → Courses → Course Detail → Profile → Logout PASS, 0 runtime-error match.
- Truy cập trực tiếp teacher schema source `moodleschema.zoola.io`: Moodle LMS 3.9, generated 2020-08-12, MySQL 5.7.31; phân loại tách biệt khỏi DLU live evidence.
- Chốt `MOODLE_SUBSET_V1` đúng 20 bảng (13 CORE, 7 SUPPORTING), cùng Feature Table Matrix, Table Catalog, Join Paths, ERD core/extensions, CRUD Matrix, Source Manifest và Synthetic Data Policy.
- Tạo deterministic generator/validator Dart, canonical JSON, MySQL `PROJECT_SUBSET_SCHEMA` và seed SQL; hai lần generation byte-identical; validator PASS.
- Dataset synthetic có 3 giảng viên, 20 sinh viên, 4 category, 6 course, 33 section, 18 assignment và đủ trạng thái deadline/submission/grade; mọi email dùng `example.test`, không password/secret/PII thật.
- Refactor DEV repositories sang shared `SyntheticFixtureDataSource`; production repositories cho course content/assignment/grade/calendar tiếp tục fail closed.
- Student DEV core hoàn tất: Dashboard upcoming assignment/calendar, Course sections/resources, Assignment + submission status, Grades và optional profile fields.
- Visual emulator QA đã sửa tương phản Assignment/Grades/Profile và thêm regression assertions cho `onPrimaryContainer`; screenshots tương ứng đã được chụp lại.
- Quality gate: format 56 files/0 changed, analyze 0 issues, validator PASS, 32 tests PASS, DEV + production debug APK PASS.
- Android 15/API 35 emulator PASS cho Dashboard → Courses → Course Detail/Resources → Assignment/Submission → Grades → Profile; PID log scan 0 lỗi runtime. Production emulator re-check có 0 credential field/DEV fixture và blocker đúng.
- Hoàn tất pre-edit inventory tại `docs/PRODUCT_UI_AUDIT.md`; mọi quyết định KEEP/REMOVE/REWRITE/REDESIGN được đối chiếu với UI đang chạy trước khi sửa.
- Chốt product navigation thành `Trang chủ` / `Khóa học` / `Lịch` / `Hồ sơ`; phone dùng `NavigationBar`, màn hình rộng dùng `NavigationRail`, còn Course Detail/Assignment/Grades là route theo ngữ cảnh.
- Redesign Login, Dashboard, Courses, Course Detail, Assignment, Grades, Calendar và Profile theo Material 3, central spacing/radius/layout tokens và shared contextual skeleton/section components.
- Loại chi tiết backend, blocker code, token/endpoint/repository/schema, fake notification và điểm trung bình/biểu đồ suy diễn khỏi UI; error mapper chỉ trả thông báo tác vụ thân thiện.
- Profile chỉ hiển thị identity tối thiểu đã có trong domain data, cho đổi giao diện local `Hệ thống`/`Sáng`/`Tối` và đăng xuất; không hiển thị internal ID hoặc hạ tầng.
- DEV repository chặn đọc Course Detail/Assignment/Grades ngoài các course đã enroll; progress chỉ tính nội dung thực sự được hiển thị.
- Product-polish automated gate PASS: `flutter analyze` 0 issues và `flutter test` 50/50.
- Android emulator walkthrough PASS cho Login → Trang chủ → Khóa học → Course Detail → Assignment → Grades → Lịch → Hồ sơ; bộ 8 ảnh sạch nằm tại `docs/screenshots/production-polish/`.

### Latest emulator re-verification — 2026-08-12 22:47 ICT

- Không tải/cài lại toolchain: Emulator 37.1.11, Android 35 Google APIs x86_64 image revision 9 và AVD `DLU_LMS_Pixel` hiện có đều hợp lệ trên D.
- Xác minh lại toàn bộ path nặng nằm trên D: Android SDK/emulator/AVD, Gradle cache, Pub cache, generated build output và APK artifacts.
- `flutter run -d emulator-5554 -t lib/main_development.dart --no-resident` PASS; kiểm thử trực tiếp Splash → Login → Dashboard → Courses → Course Detail → Profile PASS.
- PID-scoped logcat có `0` crash, ANR, Flutter exception, RenderFlex/overflow, unhandled exception hoặc platform exception; không phát hiện lỗi source cần sửa.
- Làm mới đủ 6 ảnh trong `docs/screenshots/emulator/`; ảnh chỉ dùng synthetic `DEV FIXTURE`.
- `dart format .` PASS (39 files, 0 changed), `flutter analyze` PASS (0 issues), `flutter test` PASS (13 tests).
- Build lại DEV fixture và production-entrypoint debug APK trên D; cả hai giữ package `vn.edu.dlu.lmsmobile`, minSdk 24, targetSdk 36.
- Khi bàn giao: C còn `20.85 GB`, D còn `74.98 GB`; storage gate C ≥ 15 GB PASS.

### Production UI polish verification — 2026-08-16

- Chạy app qua development composition root với canonical synthetic dataset; dữ liệu vẫn là `SYNTHETIC_DATA` ở data/test layer nhưng UI không hiển thị nhãn phát triển hoặc lời giải thích implementation.
- Flow trực tiếp PASS: Login → Trang chủ → Khóa học → Course Detail → Assignment → Grades → Lịch → Hồ sơ.
- Dashboard ưu tiên việc cần làm, học phần hiện tại và lịch sắp tới; Courses hỗ trợ search/filter; Calendar group theo ngày và không hiển thị raw event type/ID.
- Course Detail/resource sheet xử lý layout cuộn an toàn và assignment không còn force-unwrap deadline nullable.
- Grades chỉ hiển thị điểm Moodle đã phát hành, không dựng aggregate khi chưa xác minh weighting.
- Screenshots mới: `docs/screenshots/production-polish/01-login.png` đến `08-profile.png`.
- `dart format .`: PASS — 66 files, 0 changed. `flutter analyze`: PASS — 0 issues. `flutter test`: PASS — 50/50.
- Build product-polish DEV và production-entrypoint debug APK trên D: PASS — mỗi file 193,806,149 bytes. Production APK smoke PASS với 0 credential field và 0 technical/dev copy match.
- Tắt Android native default focus highlight trên Flutter view tree; recapture ảnh `02`–`08` trực tiếp từ emulator, không hậu kỳ và không còn viền focus xanh.
- Storage sau final rebuild: C `57.52 GB`, D `71.44 GB`; `build/` inactive ngoài OneDrive synced root.

### Secure Supabase backend foundation — 2026-08-16

- Hoàn thành `docs/supabase/APP_OWNED_DATA.md` trước schema decision; chỉ `mobile_preferences` được chọn, còn bookmark/notification metadata tiếp tục deferred và mọi Moodle academic table bị cấm clone.
- Supabase CLI 2.114.0 tạo local config + migration `20260815172943_create_mobile_preferences.sql`; không `link`, restore, push, deploy hoặc chạy Docker.
- Migration tạo đúng 1 table, UUID owner PK, theme allowlist, database timestamps; revoke mặc định, RLS enable + force và 3 policy own-row/non-anonymous cho select/insert/update; không `anon`/DELETE/service grant. RPC hẹp invoker derive `auth.uid()` và chỉ cập nhật theme atomic.
- Flutter có `supabase_flutter` 2.17.2, HTTPS + exact publishable-key allowlist, injected one-login identity/JWT boundary, typed DTO/repository/data source và sanitized error mapping. Không widget query, Supabase login thứ hai, global init hoặc default network call.
- Offline validator PASS: 1 app-owned table, 3 RLS policies, 28 pgTAP assertions. `dart format .` PASS 80 files/0 changed, analyze 0 issues, tests 73/73.
- Build sau dependency update PASS cho production + DEV debug APK (193,844,724 bytes/file). Production emulator có 0 credential field/0 technical string; DEV login → Dashboard + 4 nav labels PASS; cả hai runtime scan 0 lỗi.
- Project/account connector có nhiều project cũ không được định danh là DLU LMS Mobile; không tự chọn/khôi phục project. Remote apply và connected RLS test vẫn `BLOCKED_EXTERNAL`.
- Storage sau final rebuild: C `57.41 GB`, D `70.01 GB`; npm/Flutter/Pub/Gradle/build/APK đều ưu tiên D.

## IN PROGRESS

- Product UI polish + schema/synthetic Student DEV milestone đã hoàn tất và quality-gated ở code/test/emulator.
- Hoàn thiện extension Student Support staging chỉ đọc: sample identity selector,
  invalidation khi API trả 401, Bài tập, Tiến độ, Calendar contextual và safe
  handoff sang LMS chính thức. Đã thêm nhắc việc cục bộ do người học quản lý từ
  Bài tập/Hồ sơ; chờ format, APK và combined emulator gate của code hiện tại.
- Live Flutter authentication/current-user/courses integration vẫn cố ý chưa triển khai cho đến khi DLU bật/phê duyệt application-layer service/auth flow.
- Supabase local foundation đã code/test nhưng chưa được remote-enable hoặc nối UI; project selection và one-login identity mapping vẫn là external gate.

## BLOCKED

| Blocker code | Ảnh hưởng | Bằng chứng/thông tin cần có | Nguồn cung cấp phù hợp |
|---|---|---|---|
| `AUTHENTICATION_METHOD_UNCONFIRMED` | Public page có form local + Google OAuth2 nhưng chưa chứng minh backend/policy mobile | Xác nhận token login chuẩn, approved browser OAuth/SSO hoặc phương thức do DLU hỗ trợ | DLU LMS/identity administrator |
| `MOODLE_WEB_SERVICES_NOT_ENABLED` | Token/mobile site check trả `enablewsdescription`; không thể chạy API POC | DLU phê duyệt và bật Web Services + selected REST/mobile/external service, ưu tiên staging/test | DLU LMS administrator |
| `TEST_ACCOUNT_REQUIRED` | Sau enablement, cần kiểm chứng least-privilege student/teacher contexts | Student test identity trước; teacher account chỉ sau Student core PASS | DLU/GVHD |
| `MOODLE_API_TOKEN_REQUIRED` | Sau enablement, chưa có credential/token scope được phê duyệt | Approved short-lived test token/interactive auth; không gửi qua Git/docs/chat | DLU LMS administrator |
| `MOODLE_VERSION_REQUIRED_FOR_PLUGIN` | Không thể đánh giá/code custom plugin | Moodle, PHP và DB versions; plugin policy | DLU LMS administrator |
| `PACKAGE_IDENTITY_OWNERSHIP_UNCONFIRMED` | Package tạm đã dùng nhưng chưa có ownership/branding approval | DLU xác nhận application ID/branding/release ownership | DLU/GVHD/người dùng |
| `SUPABASE_PROJECT_CONNECTION_REQUIRED` | Không thể apply migration/chạy pgTAP/advisors hoặc bật app-owned sync trên project thật | Chọn/tạo project Supabase non-production dành riêng cho DLU LMS Mobile và xác nhận identity bridge có stable UUID `sub` | Project owner + DLU identity/backend owner |
| `SUPABASE_IDENTITY_MAPPING_REQUIRED` | Không thể cấp authenticated Supabase session bằng trải nghiệm một lần đăng nhập | Contract backend/issuer đã xác minh để cùng principal DLU nhận stable UUID `sub`, refresh/revoke/logout rõ ràng | DLU identity/backend owner + project owner |

`REAL_DLU_DATABASE: NOT_REQUIRED_FOR_CURRENT_PHASE` — GVHD đã yêu cầu dùng teacher-provided schema + AI-generated synthetic data. DLU physical schema/version/prefix vẫn `UNKNOWN` nhưng không chặn development/reporting phase hiện tại.

Không yêu cầu production admin password và không cần production database READ/WRITE access.

## Technical debt / risks hiện tại

1. Authentication topology của DLU chưa rõ; token/mobile site check hiện xác nhận Web Services disabled và không thể đi tiếp trước admin enablement.
2. Moodle version/function exposure/capabilities chưa rõ; API matrix mới là discovery backlog.
3. Chưa có branding/release signing ownership approval; UI dùng generic school icon, không dùng logo DLU chính thức.
4. Workspace nằm trong OneDrive và OneDrive không hỗ trợ junction trong synced root. Junction `build/` hiện được giữ ngoài OneDrive tại `%LOCALAPPDATA%\DLU-LMS\WorkspaceLinks`, chỉ kích hoạt trong lúc wrapper tạm dừng OneDrive rồi được tháo trước khi sync chạy lại. Build thật vẫn ở `D:\DLU-LMS\Build\DoAnTotNghiep`.
5. `flutter_secure_storage` được pin 10.3.1 vì 11.0.0 yêu cầu compile SDK 37 trong khi current stable project/toolchain dùng SDK 36; cần review lại khi API 37 tooling ổn định.
6. Emulator Android 15/API 35 đã PASS; chưa có smoke test trên thiết bị Android vật lý.
7. Hai generated/staging directories đã xác minh là không cần (`1.90 GB` build backup và `1.06 GB` interrupted SDK staging) vẫn còn trên D vì local delete policy chặn lệnh trước khi thực thi; không ảnh hưởng gate C ≥ 15 GB.
8. Supabase account connector thấy nhiều project cũ đều inactive nhưng không có project nào được phê duyệt/linked cho repository; không được tự khôi phục hoặc chọn theo tên phỏng đoán.

## TODO / backlog Phase 0 → Phase 9

| Phase | Mục tiêu | Exit criteria | Trạng thái |
|---|---|---|---|
| 0 | Audit repository/environment; governance/docs | Toolchain status và blockers rõ; docs baseline verified | PASS |
| 1 | Moodle/system analysis | Use cases, role/capability evidence, live function inventory, auth decision | PARTIAL — authenticated UI verified; API/version/capability blocked |
| 2 | Flutter foundation | App scaffold, Material 3, router, config, errors/network/storage, shell tests | PASS |
| 3 | Moodle authentication | Login → token/session → site/user info → dashboard trên account test | BLOCKED — auth/API/test account |
| 4 | Courses | Courses thật theo user/capability | BLOCKED — Phase 3 + function access |
| 5 | Course content | Course detail/content/file access thật, safe authenticated download | BLOCKED — Phase 4 + file policy |
| 6 | Student features | Assignment/grade/calendar/notification/profile theo API thật | PARTIAL — synthetic DEV core PASS; live API blocked |
| 7 | Teacher features | Read flows trước; write flows chỉ ở test environment được duyệt | BLOCKED — teacher account + explicit write permission |
| 8 | Security/reliability | Threat controls, test coverage, error states, performance, privacy review | PARTIAL — redaction + Supabase RLS foundation PASS; live auth/release review pending |
| 9 | Release candidate | APK, release config, docs/demo/checklist, known limitations | TODO |

## NEXT STEP

1. Duy trì boundary Flutter Student Support staging đã xác minh: chỉ dùng GET
   contract được tài liệu hóa, không đưa credential DLU vào app, và chỉ mở rộng
   sau khi có contract/capability được phê duyệt.
2. Dùng bộ tài liệu `docs/database/` và `docs/FEATURE_DATA_TRACEABILITY.md` cho chương Database Analysis/bảo vệ; không xin database thật trong phase này.
3. Chọn/tạo project Supabase non-production dành riêng cho app, xác minh DLU → Supabase stable UUID identity mapping; sau đó apply migration, chạy 28 pgTAP assertions và Security/Performance Advisors.
4. DLU LMS administrator phê duyệt mobile integration và bật Web Services + selected REST/mobile/external service, ưu tiên staging/test.
5. Khi gate live mở, chạy POC đúng thứ tự: auth → current user/site info → own courses → one course content; chỉ sau sanitized successful contracts mới tạo DTO/repository live.
6. Xác nhận ownership của `vn.edu.dlu.lmsmobile`, branding chính thức và release signing trước Phase 9.
