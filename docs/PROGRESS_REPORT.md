# Progress Report

## 2026-09-19 — Council alignment and runtime verification

Continued the current worktree without restarting passed gates. Student Render
and Teacher read-only fixture flows, role switching, reminders and external LMS
navigation were exercised on DLU_LMS_Pixel. User granted Android permission;
scheduling/persistence worked, future notification delivery not claimed.
Final analysis and 150 tests PASS. Generic LMS labels and two contrast details
were corrected; final APK evidence: `FLUTTER_TEST_RESULT.md`.

One catalog check found lms 22 tables / 10 views / 22 PK / 35 FK / 135 columns,
different from the supplied 39-table group model. Word files read, not edited.
Node/Fastify remains authoritative; no Spring backend, import or redeployment.
Seven council SQL SELECTs executed read-only successfully. Prepared demo pack,
DDL/seed/OpenAPI backup and separate group seed with auth fields disabled.
Remaining: group schema export; Teacher API; DLU-approved auth/Web Services.
Prior entries below are historical checkpoints.

## 2026-09-18 — Student + Teacher LMS support and runtime continuation

Added explicit Teacher context, read-only assigned-course/work/calendar/profile
support, route isolation and central LMS links. Student Render flow and local
reminders are retained. Production remains unconfigured/fail-closed.

Format/analyze and 150 tests PASS; staging APK build/install PASS. Student runtime
reached Courses, Content/Resource, Assignment and Reminder editor. Android
notification permission now needs the user; remaining runtime and final local
commit are pending. No API/database redeployment or academic write. Evidence:
`FLUTTER_TEST_RESULT.md`. No source change or rebuild during runtime continuation.

## 2026-09-18 — App-owned local learning reminders

**Status: IN PROGRESS — source and automated checks pass locally; APK and
emulator/device notification verification are still pending.**

- Added `LearningReminder` and an owner-scoped repository for learner-selected
  deadlines. Its secure local record is deliberately narrow: opaque owner/course/
  assignment references, due/reminder times and enabled state only. It does not
  copy course text, grades, feedback, submissions, passwords, tokens or an LMS
  response into local reminder storage.
- The repository rejects cross-owner access, duplicate reminders, changed
  academic references and invalid/past scheduling times. It coordinates device
  scheduling with local persistence so a failed write restores the prior
  scheduler state where possible.
- Assignment Detail opens a create/edit sheet only while the supplied deadline is
  still in the future. Profile links to a reminder manager where the active
  learner can enable, disable or delete only their own reminders. These controls
  never send a Moodle, Neon, Render or other academic write request.
- Android local-notification scheduling uses a runtime notification permission
  request and generic copy that contains no assignment title, course, grade,
  submission or file data. It is not presented as an official Moodle
  notification. Actual delivery on an emulator/device is deliberately not yet
  claimed.
- Reminder repository, scheduler, editor and manager tests are included in the
  current suite. `flutter analyze` completed with no issues and `flutter test`
  completed with **137 passing tests**. The final `dart format`, debug APK and
  manual emulator flow remain part of the combined extension gate.

## 2026-09-18 — Student Support staging identity and read-only navigation extension

**Status: IN PROGRESS — implementation complete locally; final combined
quality/emulator gate pending.**

- Replaced the staging password-style entry surface with an explicit selector
  for approved sample-student scopes. The selection stores only a non-secret
  sample code through platform-backed storage; it is not a DLU credential,
  token or production authorization mechanism.
- A rejected staging identity response invalidates and clears that local scope,
  allowing the normal auth controller/router path to return to the selector.
  Production composition remains fail-closed and does not include this path.
- Added read-only **Bài tập** and **Tiến độ** destinations. Assignment list and
  detail use documented GET data only; no mobile submission, upload, grading,
  or synthetic write flow was introduced. Progress renders supplied course
  completion values without controls that alter Moodle state.
- Moved Calendar to a contextual Dashboard route, keeping five focused primary
  destinations: Trang chủ, Khóa học, Bài tập, Tiến độ and Hồ sơ.
- Added a constrained official-LMS handoff on Assignment Detail. It can open
  only the canonical official LMS origin through the platform; activity deep
  links are not guessed and all official academic actions remain on Moodle.
- Added focused tests for identity persistence/invalidation, no-password staging
  Login, assignment/progress loading-empty-error-navigation states, responsive
  shell navigation, external-origin rejection and app-owned local reminders.
  Analysis is clean and the full suite passes 137 tests; final format, build and
  emulator results remain pending.

## 2026-09-18 — Flutter Student Support staging consumer (PASS, read-only)

- Started the Flutter work only after both public staging gates passed, from an
  isolated clean worktree so unrelated local demo/database work remains untouched.
- Added an explicit `main_staging.dart` composition root for the verified Student
  Support staging API. It is read-only, uses typed adapters/repositories behind the
  existing feature contracts, and is separate from both `main.dart` production and
  `main_development.dart` fixture composition roots.
- The staging entrypoint deliberately does not implement DLU password login or
  production fallback. Its sample identity is a non-secret development header
  accepted only by the staging API; it is not a DLU account, password or token.
- `STAGING_FLUTTER_CONSUMER_GATE=PASS`: `dart format .`, `flutter analyze` and
  `flutter test` passed with 93 tests. The Android emulator verified Dashboard,
  Courses, Course Detail, Resource Detail, Assignment Detail, Grades, Calendar
  and Profile; evidence is retained under
  `docs/screenshots/student-support-staging/`.
- The adapter is deliberately non-production and read-only. It does not implement
  DLU password login, upload, submission, grading or another write workflow;
  `main.dart` remains fail-closed and does not select this consumer as a fallback.

## 2026-09-18 — Render staging and Postman verification

- Deployed the dedicated `integration-api-render-staging` branch commit `e241f8a`
  to the Render Node Free service `dlu-lms-student-support-staging`. No main merge,
  force-push, database migration, seed operation or production LMS request occurred.
- Verified the public staging endpoints: `/health`, `/docs` and `/openapi.json`
  each returned HTTP 200. The OpenAPI document is 3.0.3, same-origin (`/`) and
  contains 11 GET operations.
- Ran 19 status-only staging checks: ten read-only student endpoints returned 200;
  missing identity and the five expected authorization/scope/write-route negatives
  returned 401/404/404/400/404/404. No response body or secret was printed.
- Ran the existing Postman collection against `DLU LMS Render Staging`: 17 requests,
  85/85 assertions, zero failed/skipped/errors. The Render deploy log was reviewed
  for the build/start/health sequence and contained no database credential or
  connection string.
- The user entered the Render database secret directly. It was never read, copied,
  committed, logged, shown in a screenshot or passed to Postman.
- `RENDER_STAGING_GATE=PASS`; `POSTMAN_STAGING_GATE=PASS`. The subsequent Flutter
  Student Support read-only consumer has also passed in an isolated clean worktree,
  preserving existing local demo and Flutter changes.

## 2026-09-17 — Dedicated Integration API staging preparation

- Resumed the approved Render deployment chain without changing Flutter or the
  database. Created `integration-api-render-staging` from the actual baseline;
  preserved all unrelated uncommitted work and the original C workspace.
- Verified remote main at `c773b7e`; only the dedicated branch is authorized for
  publish. The private environment file remains ignored.
- Fixed staging Swagger to use same-origin requests; added staged-blob secret
  scanning with sanitized output. Format/typecheck/build and 50/50 tests PASS;
  regenerated safe OpenAPI/Postman artifacts.
- Configured the Render form for Node/Free/Singapore and the real build/start
  commands. No service deployment or public staging test is claimed yet.
- Public Render and Postman staging gates remain prerequisites for Flutter.
  See `INTEGRATION_STATUS.md` for current deployment/secret handoff evidence.

## 2026-08-12 — Phase 0 Repository & Environment Audit

### Công việc đã thực hiện

- Đọc yêu cầu dự án và audit toàn bộ repository.
- Kiểm tra Git state, file inventory, config/environment files và `AGENTS.md` hiện có.
- Kiểm tra Flutter, Dart, Git, Java, Android SDK CLI, ADB và Android environment variables.
- Thiết lập governance, status, architecture, Moodle integration discovery, API/database mapping skeleton, security baseline và test plan.
- Thêm `.gitignore` để chặn secret, signing artifacts, database dumps và generated output.
- Lập backlog Phase 0 → Phase 9 và blocker register.

### Kết quả

- Repository ban đầu chỉ có `.git`, nhánh `main`, chưa có commit.
- Không có `README`, `pubspec.yaml`, `lib/`, `test/`, `android/`, `docs/`, `.gitignore`, environment/config, UI, API code hoặc models để bảo tồn/audit.
- Git 2.54.0 hoạt động.
- Flutter, Dart, Java, `sdkmanager`, `avdmanager`, ADB và Android SDK variables không khả dụng.
- Moodle integration/database/permissions chưa thể xác minh vì thiếu DLU evidence/access.
- Phase 0 status: `PARTIAL`.

### Screenshot cần chụp

- VS Code Explorer hiển thị repository và bộ tài liệu Phase 0.
- Terminal: `git status --short --branch`.
- Sau khi cài toolchain: `flutter doctor -v` (đảm bảo không lộ path/username nhạy cảm nếu đưa vào báo cáo công khai).
- Sau khi có thiết bị: `adb devices -l` (redact serial number khi cần).

### Test/verification đã chạy

| Command/check | Result |
|---|---|
| `git status --short --branch` | PASS — `main`, no commits; clean initial repository |
| Repository file inventory | PASS — no project files found initially |
| Environment/config inventory | PASS — none found initially |
| `git --version` | PASS — 2.54.0.windows.1 |
| `flutter --version` | FAIL — command not recognized |
| `dart --version` | FAIL — command not recognized |
| `flutter doctor -v` | FAIL — Flutter unavailable |
| `adb version` | FAIL — command not recognized |
| `adb devices -l` | FAIL/BLOCKED — ADB unavailable |
| Command discovery for Java/SDK tools | FAIL — not found |
| Required documentation/file presence | PASS — 12 required baseline files present |
| Relative Markdown link check | PASS |
| Secret-pattern scan | PASS |
| Whitespace check | PASS |

### Vấn đề

1. Chưa có Flutter/Android CLI toolchain.
2. Chưa có Flutter repository scaffold hoặc application identity.
3. Chưa có DLU Moodle version/auth/API/service/capability/test account evidence.
4. Chưa có database schema/dump/read-only access.

### Giải pháp/định hướng

- Dùng Flutter manual install và Android SDK Command-line Tools theo `ENVIRONMENT_SETUP.md`; không Android Studio.
- Chỉ scaffold sau khi toolchain và app identity được xác nhận.
- Dùng DLU live API documentation và authorized test accounts để cập nhật `API_MATRIX.md`.
- Phân tích database read-only, xác định prefix/version từ evidence, không đoán.

### Việc tiếp theo

1. Hoàn tất CLI toolchain và chạy lại doctor/device checks.
2. Xác nhận application name/package ID/branding permission.
3. Xin DLU auth method, Moodle version, Web Services/service/function status và student/teacher test accounts.
4. Bắt đầu Phase 1 discovery/Phase 2 foundation khi blockers tương ứng được giải quyết.

## 2026-08-12 — Toolchain Remediation + Phase 2 Flutter Foundation

### Công việc đã thực hiện

- Cài Flutter stable/Dart, Temurin JDK 17, Android Command-line Tools, SDK platform/build-tools và ADB mà không dùng Android Studio.
- Cấu hình user PATH, `JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`; chấp nhận Android licenses.
- Scaffold Android-only Flutter project, package ID `vn.edu.dlu.lmsmobile`.
- Triển khai Material 3 responsive UI, Riverpod, go_router, Dio boundary, error taxonomy và secure token storage abstraction.
- Triển khai demo flow Splash → Login → Dashboard → Courses → Course Detail placeholder → Profile.
- Tách production shell khỏi synthetic DEV fixture bằng hai entrypoint.
- Thêm unit/widget tests và Android hardening cơ bản.
- Chuyển generated `build/` sang ổ D bằng junction vì OneDrive giữ lock.

### Kết quả

- Phase 2: `PASS`.
- Flutter doctor: Flutter/Android toolchain/network `PASS`; chỉ warning không có device.
- Production repository không gọi endpoint phỏng đoán và không fallback mock.
- Development fixture có nhãn rõ, không chứa PII DLU.
- Production và DEV fixture debug APK build thành công.

### Test đã chạy

| Command/check | Result |
|---|---|
| `dart format .` | PASS |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 13 tests |
| Mobile widget demo flow 390×844 | PASS; đã phát hiện và sửa overflow wordmark |
| `flutter build apk --debug -t lib/main.dart` | PASS |
| `flutter build apk --debug -t lib/main_development.dart` | PASS |
| `aapt dump badging` | PASS — `vn.edu.dlu.lmsmobile`, label `DLU LMS Mobile` |
| `adb devices -l` | BLOCKED — no device connected |

### Vấn đề và giải pháp

1. Flutter archive 1.9 GB tải chậm qua single connection: dùng portable `aria2`, vẫn kiểm SHA-256 chính thức.
2. `flutter_secure_storage` 11.0.0 yêu cầu compile SDK 37 nhưng CLI package hash chưa tương thích Gradle: pin 10.3.1, dòng stable target SDK 36.
3. OneDrive lock `build/`: stop Gradle daemon, chuyển generated output qua junction tới `D:\dlu_lms_build\DoAnTotNghiep`.
4. Widget test phát hiện overflow mobile: sửa wordmark bằng flexible/ellipsis.

### Artifacts local

- `D:\dlu_lms_artifacts\dlu-lms-mobile-production-shell-debug.apk`
  - SHA-256: `298D50429541111A29376805025116B0DA8A5EA6CB39530558E0BAB74CF8C816`
- `D:\dlu_lms_artifacts\dlu-lms-mobile-dev-fixture-debug.apk`
  - SHA-256: `126811D4EC7C03BADC76B3894570130A4D059F20AD5024F1AB71E56138A0F495`

DEV fixture artifact không được phân phối như production build.

### Việc tiếp theo

1. Nhận DLU auth/API/service evidence và test accounts qua kênh an toàn.
2. Triển khai Phase 3 authentication thật và site/user info verification.
3. Chạy smoke test trên Android device/emulator khi có thiết bị.

## 2026-08-12 — Storage-safe Android Emulator Demo Milestone

### Công việc đã thực hiện

- Áp dụng storage gate C ≥ 15 GB trước/sau các download, install và build lớn.
- Xác minh Flutter/JDK/Android SDK/Gradle/Pub/build paths; cấu hình thêm `ANDROID_EMULATOR_HOME` trên D.
- Cài Android 35 Google APIs x86_64 system image revision 9 bằng CLI, không Android Studio.
- Tạo AVD `DLU_LMS_Pixel` (Pixel 7, 1080×2400, 4 cores, 3072 MB RAM) trong `D:\DLU-LMS\Android\AVD`.
- Xác minh WHPX khả dụng, boot emulator Android 15/API 35 và deploy `lib/main_development.dart`.
- Chạy manual emulator flow: Launch/Splash → Login → Dashboard → Courses → Course Detail → Profile → Logout.
- Đọc accessibility tree từng màn hình, chụp screenshot và lọc logcat theo PID app.
- Thay native Flutter launch mark mặc định bằng generic academic mark theo palette của app; không sử dụng logo DLU chưa được duyệt.
- Bổ sung assertion widget test cho Flutter Splash và giữ delay quan sát chỉ trong DEV fixture.
- Build lại hai APK tách biệt: DEV fixture và production shell fail-closed.

### Storage layout và kết quả gate

| Thành phần | Path/kết quả |
|---|---|
| Flutter | `D:\DLU-LMS\Toolchains\flutter` |
| JDK 17 | `D:\DLU-LMS\Toolchains\jdk-17` |
| Android SDK/system image | `D:\DLU-LMS\Android\Sdk` |
| AVD | `D:\DLU-LMS\Android\AVD\DLU_LMS_Pixel.avd` |
| Emulator config | `D:\DLU-LMS\Android\EmulatorHome` |
| Gradle/Pub caches | `D:\DLU-LMS\Caches\Gradle`, `D:\DLU-LMS\Caches\Pub` |
| Build output | repository `build\` junction → `D:\DLU-LMS\Build\DoAnTotNghiep` |
| Final free space | C `20.82 GB`; D `75.34 GB` |
| Storage threshold | PASS — C chưa từng xuống dưới `15 GB` |

System image install làm D giảm khoảng `3.50 GB` và không làm giảm C. AVD dùng khoảng `3.09 GB` sau first boot.

### Test/verification đã chạy

| Command/check | Result |
|---|---|
| `emulator -accel-check` | PASS — WHPX installed and usable |
| `adb devices -l` | PASS — `emulator-5554` online |
| `flutter devices` | PASS — Android 15/API 35 x86_64 emulator |
| `flutter run -d emulator-5554 -t lib/main_development.dart --no-resident` | PASS |
| Emulator UI flow + logout | PASS — tất cả state được xác nhận qua UI Automator |
| PID-scoped logcat review | PASS — 0 crash/ANR/Flutter exception/RenderFlex overflow |
| `dart format .` | PASS — 39 files, 1 test file formatted |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 13 tests |
| `flutter doctor -v` sau build | PASS — no issues; emulator connected |
| DEV fixture debug APK | PASS |
| Production-shell debug APK | PASS |
| `aapt dump badging` cho cả hai APK | PASS — package `vn.edu.dlu.lmsmobile`, minSdk 24, targetSdk 36 |

### Screenshot artifacts

- `docs/screenshots/emulator/01-splash.png`
- `docs/screenshots/emulator/02-login.png`
- `docs/screenshots/emulator/03-dashboard.png`
- `docs/screenshots/emulator/04-courses.png`
- `docs/screenshots/emulator/05-course-detail.png`
- `docs/screenshots/emulator/06-profile.png`

Các ảnh dùng dữ liệu synthetic `DEV FIXTURE`, không chứa tài khoản hoặc PII DLU thật.

### APK artifacts local

- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-dev-fixture-emulator-verified-debug.apk`
  - Size: `170.20 MB`
  - SHA-256: `A513758A52D5689466BED9BA6A9F880F21EB84A8FD4C5097121BC5568E1C19C2`
- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-production-shell-emulator-verified-debug.apk`
  - Size: `170.20 MB`
  - SHA-256: `E8E7FDFA73E471CF11DE5A22A5145E3C04D4A35A1A1450794BA3C076448045AD`

Production artifact là debug-signed shell dùng `lib/main.dart`; nó fail closed khi thiếu DLU auth/API và không chứa DEV fixture. Release APK chưa được tạo vì owner chưa cung cấp release signing/config; dự án không tạo secret giả.

### Lỗi đã gặp và cách xử lý

1. Gradle không xóa được generated Flutter/assets directories qua OneDrive junction: dừng daemon, xoay toàn bộ generated build tree cũ sang backup trên D và build lại từ root rỗng; các lượt build sau PASS.
2. Native Android launch còn logo Flutter mặc định: thêm Android 12 splash theme, adaptive icon và vector academic mark nằm đúng safe zone.
3. Flutter Splash trong DEV khó quan sát do native cold-start che first frame: neo fixture restore vào Flutter frame và chỉ thêm độ trễ trong DEV layer; production repository không đổi.
4. Delete policy chặn xóa `D:\DLU-LMS\Build\DoAnTotNghiep.stale-20260812-215632` (`1.90 GB`) và interrupted SDK staging (`1.06 GB`) trước khi lệnh chạy. Hai path đã được xác minh là generated/staging, nhưng vẫn được giữ nguyên thay vì bypass policy.

### Việc tiếp theo

1. Nhận DLU authentication method, Web Services status/function inventory và authorized test account qua kênh an toàn.
2. Triển khai Phase 3 production authentication khi evidence có đủ; không suy đoán endpoint/token.
3. Xác nhận package/branding/release signing ownership và chạy physical-device smoke test khi có thiết bị.

## 2026-08-12 — OneDrive Long-path Remediation

### Nguyên nhân

OneDrive cố duyệt repository `build\` junction và báo path quá dài trong generated `flutter_secure_storage` intermediates. `.gitignore` không điều khiển OneDrive, và Microsoft không hỗ trợ junction/symlink trong synced root.

### Thay đổi

- Dừng OneDrive nhẹ nhàng và chuyển chính junction nhỏ ra `%LOCALAPPDATA%\DLU-LMS\WorkspaceLinks\DoAnTotNghiep-build`; không xóa hoặc di chuyển target build 2.04 GB trên D.
- Thêm `tool/build_storage.ps1` với ba action `Prepare`, `Cleanup`, `Status` và xác minh chặt target trước mọi move.
- Thêm `tool/flutter_dlu.ps1` để bảo đảm cleanup/restart OneDrive trong `finally` ngay cả khi Flutter fail.
- Kết nối hai VS Code launch profiles với pre/post tasks tương ứng.
- Cập nhật README và environment guide để dùng wrapper cho run/test/build.

### Verification

| Check | Result |
|---|---|
| Repository `build\` khi OneDrive chạy | Không tồn tại — PASS |
| Inactive junction | `%LOCALAPPDATA%\DLU-LMS\WorkspaceLinks\DoAnTotNghiep-build` → D target — PASS |
| OneDrive sau cleanup | Running — PASS |
| Wrapped `flutter doctor -v` | PASS — no issues, emulator connected |
| Wrapped `flutter analyze` | PASS — 0 issues |
| Wrapped `flutter test` | PASS — 13 tests |
| Wrapped production debug APK build | PASS — SHA-256 không đổi: `E8E7FDFA73E471CF11DE5A22A5145E3C04D4A35A1A1450794BA3C076448045AD` |
| Storage | C `20.86 GB`, D `75.34 GB`; gate ≥ 15 GB PASS |

## 2026-08-12 — Emulator Flow and APK Re-verification

### Phạm vi

- Tiếp tục từ environment hiện có, không audit lại và không thêm feature.
- Kiểm tra Android SDK, emulator, AVD, Gradle/Pub cache, build output và artifact paths trước khi chạy.
- Không tải/cài lại package vì Emulator 37.1.11, platform-tools 37.0.1, Android 35 Google APIs x86_64 system image revision 9 và AVD `DLU_LMS_Pixel` đã đầy đủ trên D.

### Kết quả emulator và UI

| Check | Result |
|---|---|
| `emulator -accel-check` | PASS — WHPX installed and usable |
| `adb devices -l` | PASS — `emulator-5554`, Android 15/API 35 x86_64 online |
| `flutter devices` | PASS — `sdk gphone64 x86 64` được nhận |
| `flutter run -d emulator-5554 -t lib/main_development.dart --no-resident` | PASS — build/install/launch thành công |
| Splash → Login → Dashboard → Courses → Course Detail → Profile | PASS — xác minh trực tiếp trên emulator |
| PID-scoped logcat | PASS — 0 crash, ANR, Flutter error, RenderFlex/overflow, unhandled/platform exception |
| Visual review | PASS — không phát hiện lỗi layout, runtime hoặc navigation cần sửa source |

Đã làm mới bộ ảnh `docs/screenshots/emulator/01-splash.png` đến `06-profile.png`. Native launch splash được chụp ở cold start; năm màn hình Flutter còn lại được chụp trong cùng luồng DEV fixture. Không ảnh nào chứa credential hoặc PII DLU thật.

### Quality gate và APK

| Command/check | Result |
|---|---|
| `dart format .` | PASS — 39 files, 0 changed |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 13 tests |
| DEV fixture debug APK | PASS — 178,470,619 bytes |
| Production-entrypoint debug APK | PASS — 178,470,619 bytes |
| `aapt dump badging` | PASS — `vn.edu.dlu.lmsmobile`, version 0.1.0, minSdk 24, targetSdk 36 |

- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-dev-fixture-emulator-reverified-debug.apk`
  - SHA-256: `A513758A52D5689466BED9BA6A9F880F21EB84A8FD4C5097121BC5568E1C19C2`
- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-production-shell-emulator-reverified-debug.apk`
  - SHA-256: `E8E7FDFA73E471CF11DE5A22A5145E3C04D4A35A1A1450794BA3C076448045AD`

Production artifact dùng `lib/main.dart`, không inject DEV fixture và fail closed khi chưa có DLU auth/API. Đây là production entrypoint build bằng debug signing; release APK tiếp tục chờ owner cung cấp release signing/config hợp lệ, không tạo secret giả.

### Storage gate

| Thời điểm | C | D | Result |
|---|---:|---:|---|
| Trước quality/build gate | 20.87 GB | 76.44 GB | PASS |
| Sau hai APK build và final verification | 20.85 GB | 74.98 GB | PASS |

Repository `build\` được wrapper kích hoạt tạm thời tới `D:\DLU-LMS\Build\DoAnTotNghiep`, sau mỗi command được tháo khỏi OneDrive synced root và OneDrive được khởi động lại. C không xuống dưới ngưỡng 15 GB.

### Blocker còn lại

- Không có blocker local/emulator cho demo milestone.
- At this earlier emulator milestone, live Moodle still required auth/Web Services evidence. Phase 3B later resolved the service-status question to `MOODLE_WEB_SERVICES_NOT_ENABLED`.

## 2026-08-13 — Phase 3A Live DLU Moodle Public Discovery

### Scope and safety

- Truy cập `https://lms.dlu.edu.vn/` công khai, read-only; không login, không submit form, không scan/fuzz/spider hoặc ghi dữ liệu lên LMS.
- Không in/lưu cookie value, login token, credential, MFA, user data hoặc response private.
- Flutter source không thay đổi; production tiếp tục fail-closed.

### Evidence findings

| Finding | Result | Confidence |
|---|---|---|
| DNS | IPv4 `14.238.96.169` observed | VERIFIED_NETWORK |
| HTTP → HTTPS | `302` to canonical HTTPS root | VERIFIED_NETWORK |
| HTTPS root | `200 OK`, Vietnamese HTML, LiteSpeed header | VERIFIED_NETWORK |
| TLS connection | Valid wildcard `*.dlu.edu.vn` certificate; observed TLS 1.2 negotiation | VERIFIED_NETWORK |
| Platform | Moodle via routes/runtime/assets/cookie-name/footer evidence | VERIFIED_NETWORK |
| Exact Moodle version | No authoritative evidence | UNKNOWN |
| Theme | Lambda asset/class evidence | VERIFIED_NETWORK |
| Public structure | Course search/category tree, news/online blocks, DLU navigation/contact | VERIFIED_UI |
| Local login | Username/password form at `/login/index.php` | VERIFIED_UI |
| Federated login | `Google Login` via Moodle OAuth2 route | VERIFIED_UI |
| Web Services/mobile service | No DLU-specific evidence yet | UNKNOWN |

The public form does not prove Moodle-native authentication or authorize mobile token acquisition. The Google option does not yet provide an approved Flutter redirect/token exchange contract.

### Documentation changed

- Created `docs/live-dlu/SITE_DISCOVERY.md`.
- Created `docs/live-dlu/AUTH_DISCOVERY.md`.
- Created a public-only `docs/live-dlu/WEB_FEATURE_MAP.md`.
- Created `docs/live-dlu/DLU_ADMIN_REQUIREMENTS.md`.
- Reworked `docs/API_MATRIX.md` so no DLU function is claimed before live/admin evidence.
- Updated Moodle integration, database evidence boundary, architecture claim, project status and this report.

### Tooling limitation

Browser DOM/metadata inspection succeeded, but screenshot capture repeatedly timed out. No partial/corrupt public screenshot was retained and no private data was captured.

### Quality gate

| Check | Result |
|---|---|
| `dart format .` | PASS — 39 files, 0 changed |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 13 tests |
| Secret/session-value scan | PASS — no cookie value, login token, bearer credential or private key; only existing synthetic test password matched |

Lượt wrapper đầu bị chặn trước khi Flutter chạy vì OneDrive đồng bộ ngược một cloud placeholder vào repository `build/` trong khi junction thật đang được cất ngoài OneDrive. Reparse tag, Git ignore/tracking state và D target đã được xác minh; placeholder được bảo toàn dưới tên ignored `build_onedrive_stale_phase3a_20260813`, không xóa build target/data. Sau remediation, analyze và test đều PASS và wrapper trả junction về trạng thái inactive.

### Current gate

`ACTION_REQUIRED: USER_INTERACTIVE_LOGIN` — authenticated read-only discovery requires the user to enter their own credential/MFA in the handed-off browser. Codex must never receive the password or OTP.

This Phase 3A action was completed before Phase 3B; it is retained only as chronological history and is no longer the active blocker.

### Next step

After the user reports `Đã đăng nhập`, continue in the same session with read-only Dashboard → My Courses → one course → Profile discovery, then assess DLU-specific Web Service/auth strategy before any production Flutter change.

## 2026-08-14 — Phase 3B Authenticated Discovery + Safety Hardening

### Scope and privacy

- Reused the existing user-authenticated browser session; no login replay and no credential/MFA request.
- Inspected only current-user Dashboard, course overview, one representative enrolled course, Profile, Calendar, own grades navigation, notification/message navigation and minimum activity/resource metadata.
- No user/course name, identifier, grade, private message, participant list, cookie, token, Authorization header or `sesskey` value was written to source/docs/Git.
- Browser session was handed back at `/my/` and remained authenticated at final check.

### Authenticated DLU evidence

| Finding | Result | Evidence |
|---|---|---|
| Authenticated session | Dashboard/private navigation verified | `VERIFIED_UI` (`UI-AUTH-001`) |
| Dashboard/My Courses | Course overview, recent items and calendar-related blocks verified | `VERIFIED_UI` |
| One representative course | Sections plus assignment/forum/label/resource/URL activity types verified; no quiz observed in this course | `VERIFIED_UI` |
| Profile | Profile container/avatar/grouped fields verified; values omitted | `VERIFIED_UI` |
| Calendar | Month/event/filter UI verified; values omitted | `VERIFIED_UI` |
| Own grades | Overview/navigation verified; values omitted | `VERIFIED_UI` |
| Notifications/messages | Navigation verified; notification content not opened; messages target showed generic error state | `VERIFIED_UI` |
| Successful Moodle function | None | `0 VERIFIED_API` |

### Web Services/auth investigation

| Request | Outcome | Conclusion |
|---|---|---|
| GET `/webservice/rest/server.php` without parameters/cookie | `403 text/html` | Endpoint access denied; denial layer `UNKNOWN` |
| GET `/login/token.php` without credentials | `200 application/json`, `errorcode=enablewsdescription`, no token field | Web Services gate failed before credential processing |
| GET `/login/token.php?appsitecheck=1` | Same error; no `appsitecheck=ok` | `MOODLE_WEB_SERVICES_NOT_ENABLED` |

Official Moodle stable token source was used only to interpret the standard error semantics; it does not establish DLU's Moodle version. No credential, service shortname, token or function was guessed, so no live API POC could safely proceed.

### Flutter/security changes

- Production Login now displays a professional fail-closed integration state and never renders username/password fields while auth strategy is unconfirmed. DEV fixture retains its separate credential form.
- Added `AppConfig` credential-free HTTPS-origin validation and canonicalization.
- Replaced raw failure `cause` retention with scalar-only `NetworkFailureDiagnostic`; arbitrary same-origin slugs and all cross-origin paths are redacted.
- Added a pre-authorizer and post-authorizer same-origin gate; a regression with an injected mismatched Dio base URL proves 0 authorizer calls, 0 network attempts and no sentinel leakage.
- Changed course list/detail/profile providers to `autoDispose` and added cache-lifecycle regression coverage.
- Fixed emulator cold-launch layout failure caused by a transient zero-height viewport and added a small-viewport regression.
- Added authenticated feature map, sanitized network evidence, data dictionary, evidence index and production feature traceability.

### Quality gate

| Check | Result |
|---|---|
| `dart format .` | PASS — 40 files, 0 changed on final run |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 21/21 |
| Production `flutter build apk --debug` | PASS |
| Production `flutter run -d emulator-5554 -t lib/main.dart --no-resident` | PASS |
| Production semantics | Blocker state present; 0 editable credential fields |
| Production PID log scan | PASS — 0 crash/widget exception/overflow/ANR pattern |
| DEV emulator synthetic flow | PASS — Login → Dashboard → Courses → Course Detail → Profile → Logout |
| DEV PID log scan | PASS — 0 matching runtime error |

The first production emulator run exposed `BoxConstraints has a negative minimum height` during the initial zero-size viewport. The constraint was guarded, a regression test was added, and all gates/emulator checks were repeated successfully. Visual review also corrected blocker-code wrapping before the final run.

### APK artifacts on D

- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-phase3b-dev-fixture-debug.apk`
  - 178,470,619 bytes
  - SHA-256 `5998CB902B8CFA6322011DE8EB2E95904FF790BBACE5BDEA4535DA7D9330B5B8`
- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-phase3b-production-debug.apk`
  - 178,470,619 bytes
  - SHA-256 `0BCAA88446475CA6C0CCA0CF63AE7921ABCBC1B945906393A08D6A2341790895`
- Production badging: `vn.edu.dlu.lmsmobile`, version `0.1.0`, minSdk 24, targetSdk 36.

Production screenshot used for local visual QA is stored only at `D:\DLU-LMS\Artifacts\phase3b-production-blocker.png`; it contains no credential or DLU personal data and is not staged in Git.

### Storage/OneDrive

| Check | Result |
|---|---|
| Final C free | 20.65 GB — PASS (>=15 GB) |
| Final D free after both APK artifacts | 75.00 GB — PASS (>=25 GB) |
| Build target | `D:\DLU-LMS\Build\DoAnTotNghiep` |
| Final build junction | Inactive outside OneDrive synced root |
| OneDrive | Running after every quality/build session |

OneDrive recreated cloud placeholders named `build` while the real junction was inactive. Each verified non-junction placeholder was preserved under ignored `build_onedrive_stale_*` names; none was deleted or confused with the D build target.

### External blocker

```text
ACTION_REQUIRED: DLU_ENABLE_MOODLE_WEB_SERVICES

REASON:
DLU's read-only Moodle mobile site check returns errorcode=enablewsdescription,
so no supported token/API POC can proceed.

EVIDENCE:
NET-TOKEN-001 and NET-TOKEN-002; REST entrypoint independently returns 403.

WHAT I ALREADY TRIED:
Authenticated read-only UI discovery plus minimal credential-free REST/token/site-check requests.

MINIMUM REQUIRED FROM YOU/DLU:
Approve mobile integration; enable Web Services and the selected REST/mobile or
external service, preferably on test/staging; provide approved auth strategy,
sanitized service shortname/function allowlist and one least-privilege student
test identity through an approved secret channel.

SECURITY NOTE:
No production admin password, database password, broad token, cookie reuse or
write permission is requested.

WHAT I WILL DO NEXT:
Run read-only POCs in order: auth -> current user/site info -> own courses ->
one course content; then implement only response-verified DTOs/repositories.
```

Database is not required for the next step. The application-layer service gate must be resolved first.

## 2026-08-15 — Moodle Schema Analysis & Synthetic Data

### Scope and evidence boundary

- Truy cập trực tiếp teacher-provided [Moodle SchemaSpy](https://moodleschema.zoola.io/): `Moodle LMS 3.9`, generated `2020-08-12`, database type `MySQL 5.7.31`.
- Phân tích feature-first, không copy 461 bảng. Chốt `MOODLE_SUBSET_V1` ở đúng 20 bảng: 13 CORE + 7 SUPPORTING.
- Gắn ba lớp bằng chứng riêng: `TEACHER_SCHEMA_REFERENCE`, `DLU_LIVE_EVIDENCE`, `SYNTHETIC_DATA`. Không tuyên bố schema tham khảo là production DLU.
- Các hop không có physical FK trên source (`course_modules.section/instance`, `grade_items.iteminstance`, plugin file item) được ghi `SCHEMA_RELATIONSHIP_UNRESOLVED` hoặc `LOCAL_SYNTHETIC_CONVENTION`, không nâng thành verified FK.

### Database/report artifacts

- Tạo Feature Table Matrix, Selected Tables, 20-table Catalog, Join Paths, Source Manifest, CRUD Matrix, ERD core/extensions và Synthetic Data Policy tại `docs/database/`.
- Tạo `PROJECT_SUBSET_SCHEMA` MySQL 5.7-compatible selected-column DDL; không cài MySQL/Docker và không tuyên bố SQL load runtime PASS khi máy không có MySQL CLI.
- Tạo offline Dart generator + validator; một nguồn canonical sinh cả JSON asset và SQL seed.
- `REAL_DLU_DATABASE: NOT_REQUIRED_FOR_CURRENT_PHASE` theo chỉ đạo GVHD; database thật/version/prefix DLU vẫn `UNKNOWN` nhưng không còn là blocker phase này.

### Synthetic dataset

| Item | Count/result |
|---|---:|
| Fixed seed | `202608` |
| Selected tables | 20 |
| Users | 23 — 3 `GVTEST*`, 20 `SVTEST*` |
| Categories / Courses | 4 / 6 |
| Sections / Course modules | 33 / 30 |
| Resources / Assignments | 12 / 18 |
| Submissions / Assignment grades | 103 / 49 |
| Grade rows / Events | 198 / 18 |
| Privacy | `example.test`; no password/token/cookie/real DLU data |

Hai lượt generator byte-identical:

- JSON SHA-256 `29DF789B51C16D311F4622C74BF2488482E2F11665BA29FDA312C5BBA3E7104C`.
- SQL seed SHA-256 `09C6E1680DF8AA4279CB5C375A119FD005CE399A040DA253733D513D66404DA1`.
- Validator PASS cho PK/FK/local-convention integrity, duplicate enrolment, mandatory fields, privacy và đủ future/soon/overdue/draft/submitted/not-submitted/graded/ungraded/low/medium/high states.

### Flutter integration

- Thay fixture hard-code bằng `SyntheticFixtureDataSource` đọc canonical generated JSON.
- Shared DEV data source cấp dữ liệu nhất quán cho Auth, Profile, Courses, Course Content, Assignments, Grades và Calendar repositories.
- Course Detail render sections/modules/resources; resource sheet chỉ hiển thị synthetic metadata.
- Assignment screen render deadline, trạng thái nộp và grade/feedback; write action vẫn blocked.
- Grades screen render graded/ungraded states; Dashboard có upcoming assignments/calendar và progress từ completion fixture.
- Emulator visual QA phát hiện và sửa tương phản chữ trên hero card Assignment/Grades và avatar Profile; widget/demo tests khóa màu `onPrimaryContainer` để tránh regression.
- `main.dart` production không inject fixture. Emulator production xác nhận blocker đúng, 0 editable credential field và không có `DEV FIXTURE`.

### Quality gate

| Check | Result |
|---|---|
| `dart run tool/generate_moodle_sample_data.dart` ×2 | PASS — byte-identical |
| `dart run tool/validate_moodle_sample_data.dart` | PASS |
| `dart format .` | PASS — 56 files, 0 changed |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 32/32 |
| DEV debug APK | PASS — 154,968,946 bytes; SHA-256 `B9492E81D45ED62D37ADF31CBE931A9460FFEF631D3BA5983EE36CDAD33ABC7E` |
| Production debug APK | PASS — 154,968,946 bytes; SHA-256 `3750875260D900E204B4EA9801D97BA2EBAC4CCAC83CB352E5F6102A6723AF1E` |
| Android 15/API 35 emulator | PASS |
| DEV PID log scan | 0 crash/ANR/Flutter exception/overflow |
| Production PID log scan | 0 runtime-error match |

APK artifacts nằm ngoài Git tại:

- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-schema-synthetic-dev-debug.apk`
- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-schema-production-debug.apk`

### Emulator flow and screenshots

Flow PASS trực tiếp:

```text
Splash → Login DEV → Dashboard → Assignment/Submission Status
→ Courses → Course Detail/Resources → Grades → Profile
```

Đã cập nhật `03-dashboard.png` đến `06-profile.png` và thêm `07-assignment.png`, `08-grades.png` trong `docs/screenshots/emulator/`. `06-profile.png`, `07-assignment.png` và `08-grades.png` được chụp lại sau bản sửa tương phản. Tất cả chỉ chứa synthetic data.

### Storage and environment

- C luôn cao hơn threshold: khoảng `57.7 GB` free; D khoảng `72.5 GB` free sau emulator, build output, APK và vùng quarantine có thể phục hồi.
- Android SDK/AVD, Gradle/Pub cache, build output và APK artifacts vẫn ở D.
- OneDrive tái tạo một `build` Microsoft reparse chứa 900,585,095 byte generated output trên C. Nội dung đã được chuyển có thể phục hồi sang `D:\DLU-LMS\Quarantine\onedrive-build-20260815\build`; reparse rỗng được đổi tên thành ignored `build_onedrive_stale_schema_20260815_02`. Không xóa source hay dữ liệu người dùng.
- Hai lần build DEV đầu lỗi do các thư mục incremental resources trên D mang cờ Windows `ReadOnly`. Đã dừng Gradle daemon, bỏ cờ trên đúng 380 generated entries và retry; DEV/production build sau đó PASS. Warning SDK XML version không chặn build.

### Current external blocker

Live Moodle integration vẫn chờ `MOODLE_WEB_SERVICES_NOT_ENABLED` và `AUTHENTICATION_METHOD_UNCONFIRMED`. Đây không làm giảm trạng thái PASS của schema/synthetic DEV milestone. Supabase chưa được nối ở milestone này; nếu làm phase kế tiếp phải là app-owned/RLS/Edge Function boundary, không thay Moodle hoặc cho Flutter kết nối database Moodle trực tiếp.

## 2026-08-16 — Production Product UI Polish

### Scope and evidence boundary

- Hoàn tất pre-edit inventory tại `docs/PRODUCT_UI_AUDIT.md` trước khi sửa presentation.
- Giữ nguyên production fail-closed, repository contracts, Moodle boundary và canonical synthetic fixture; milestone này không tuyên bố live Moodle/API authentication đã hoạt động.
- Synthetic metadata/IDs vẫn tồn tại trong data/test layer để đảm bảo integrity nhưng không còn xuất hiện như nhãn phát triển hoặc lời giải thích kỹ thuật trong UI sinh viên.
- Không thêm fake notification, fake aggregate grade, fake API response hoặc production-data fallback.

### Product cleanup and final navigation

- Chốt primary navigation responsive: `Trang chủ` / `Khóa học` / `Lịch` / `Hồ sơ`. Phone dùng Material 3 `NavigationBar`; màn hình rộng dùng `NavigationRail`.
- Login hiển thị copy tự nhiên và nhắc không lưu mật khẩu; development form trông như product UI bình thường. Production Login không có credential field và chỉ báo dịch vụ chưa sẵn sàng bằng ngôn ngữ người dùng.
- Dashboard được sắp lại thành lời chào → việc ưu tiên → học phần hiện tại → lịch sắp tới; bỏ technical status hero và notification affordance không có nguồn thật.
- Courses chuyển sang card gọn, searchable/filterable và dễ quét. Course Detail tổ chức overview/content/resources/assignments/grades, sửa nullable deadline và resource bottom sheet thành scroll-safe.
- Assignment chỉ giữ deadline/submission/feedback hữu ích. Grades chỉ hiển thị grade item đã phát hành, không tính trung bình hoặc biểu đồ khi Moodle weighting chưa xác minh.
- Calendar là màn hình thật dựa trên repository hiện có, group theo ngày, có course context và không hiện raw event type/ID.
- Profile chỉ giữ avatar, tên/email/role/faculty, lựa chọn giao diện local và logout; bỏ internal ID, endpoint/token/storage/repository detail.
- Thêm central `AppTokens`, contextual skeleton, shared section header, responsive content widths, semantic labels và system-bar contrast.

### Fixture display and integrity

- Presentation-facing synthetic names/course content được đổi thành tiếng Việt tự nhiên, vẫn hoàn toàn hư cấu và dùng `example.test`.
- Generator/validator từ chối thuật ngữ development/sample/test trong các field được render; internal `SYNTHETIC_DATA`, seed `202608` và fake identifiers vẫn giữ nguyên.
- Generated presentation dataset sau polish vẫn deterministic: JSON SHA-256 `4F6FF5992E45B6ACAEE1C28180F0D50166D62CA3B419BD29E0188416EC673C37`; SQL SHA-256 `5A3EFA1500F2B626A1BEAFB96D6FC172D941DF6D7FE63FAD8080DE7CBD022DC5`.
- DEV repositories chặn course content, assignment detail/list và grades ngoài enrolment; Dashboard progress chỉ tính module được hiển thị.
- Production composition root không import/inject fixture và không silently fallback khi live API unavailable.

### Tests and emulator QA

| Check | Result |
|---|---|
| `dart format .` | PASS — 66 files, 0 changed |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 50/50 |
| DEV debug APK | PASS — 193,806,149 bytes; SHA-256 `5301E09123DC5C072B1B0C29B14883B82C01ABEF494DA740123DB5F726DD224F` |
| Production debug APK | PASS — 193,806,149 bytes; SHA-256 `0AA35F8CE1CB9A98E5949D978135E6A861E0894678F414C24D890228E95046B4` |
| Android 15/API 35 direct walkthrough | PASS |
| Production APK fail-closed smoke | PASS — 0 credential field, 0 technical/dev copy match |

Direct flow đã chạy:

```text
Login → Trang chủ → Khóa học → Course Detail
→ Assignment → Grades → Lịch → Hồ sơ
```

Không quan sát crash, navigation failure hoặc layout overflow trong walkthrough. Bộ evidence mới nằm tại:

- `docs/screenshots/production-polish/01-login.png`
- `docs/screenshots/production-polish/02-dashboard.png`
- `docs/screenshots/production-polish/03-courses.png`
- `docs/screenshots/production-polish/04-course-detail.png`
- `docs/screenshots/production-polish/05-assignments.png`
- `docs/screenshots/production-polish/06-grades.png`
- `docs/screenshots/production-polish/07-calendar.png`
- `docs/screenshots/production-polish/08-profile.png`

Review ảnh phát hiện Android native default focus highlight tạo viền xanh quanh Flutter view sau keyboard input. Platform highlight này đã được tắt trên native view tree, trong khi Flutter semantics/focus behavior vẫn giữ nguyên; ảnh `02`–`08` được recapture trực tiếp từ emulator, không hậu kỳ.

APK artifacts nằm ngoài repository tại:

- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-production-polish-dev-debug.apk`
- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-production-polish-production-debug.apk`

### Security and storage

- User-facing error mapping không render raw failure message/code, endpoint, token, repository/schema hoặc network payload.
- Screenshots chỉ chứa synthetic identity/course data; không chứa credential/token/cookie hoặc dữ liệu DLU thật.
- Android SDK/AVD, Gradle/Pub cache, generated build output và APK artifacts tiếp tục ưu tiên ổ D; không cài lại Android Studio/toolchain trong milestone UI.
- Sau final rebuild: C còn `57.52 GB`, D còn `71.44 GB`; storage gate C ≥ 15 GB và D ≥ 25 GB PASS. Wrapper đã trả `build/` về trạng thái inactive.

### Current external blocker

Live Moodle vẫn chờ `MOODLE_WEB_SERVICES_NOT_ENABLED`, `AUTHENTICATION_METHOD_UNCONFIRMED`, approved test identity và least-privilege service/function access. Supabase chưa được triển khai trong commit product-polish; nếu thực hiện tiếp phải giữ app-owned boundary, RLS và project connection riêng, không thay Moodle làm nguồn course/assignment/grade.

## 2026-08-16 — Secure Supabase Backend Foundation

### Ownership and architecture

- Lập inventory app-owned trước migration tại `docs/supabase/APP_OWNED_DATA.md`; chỉ theme preference có lý do lưu Supabase ở phase này.
- Giữ Moodle là source of truth cho identity attributes, courses, content, assignments, submissions, grades, roles và capabilities. Không tạo bảng clone hoặc đưa Moodle token/password/session vào Supabase.
- Chốt một-login boundary: Flutter không tự tạo Supabase account/anonymous session; identity bridge phải cung cấp stable UUID `sub` cho cùng principal DLU sau khi được xác minh.
- Edge Function chỉ có negative/allowlist contract, chưa code generic proxy hoặc endpoint Moodle giả.

### Database and RLS

- Dùng Supabase CLI 2.114.0 qua npm cache trên D để init local config và tạo migration `20260815172943_create_mobile_preferences.sql`.
- Tạo đúng `public.mobile_preferences(owner_id, theme_mode, created_at, updated_at)`; `owner_id` là UUID PK, theme chỉ `system/light/dark`, timestamps client-immutable.
- Revoke default table/function privileges; chỉ `authenticated` có SELECT, INSERT hai cột cần thiết và UPDATE `theme_mode`. Không có anon, DELETE hoặc service-role app-table grant.
- Enable + force RLS; ba policy riêng đều buộc `auth.uid() = owner_id` và reject anonymous JWT.
- Thêm RPC `save_mobile_theme_preference` security-invoker: server derive `auth.uid()`, atomic insert-or-update và chỉ SET theme; Flutter không cần quyền UPDATE owner ID.
- Thêm 28-assertion pgTAP contract cho policy/grant/RPC/cross-owner INSERT và owner A/owner B/anonymous/anon; remote/local database execution chưa chạy vì không cài Docker và chưa link project.

### Typed Flutter layer

- Pin `supabase_flutter` 2.17.2; tạo HTTPS-only `SupabaseConfig`, allowlist đúng modern publishable/legacy anon key và fail closed khi thiếu project.
- Tạo injected `SupabaseIdentitySession`, direct client factory, typed model/DTO/repository/data source và Riverpod provider theo `UI → Provider → Repository → Data Source`.
- Query luôn filter owner UUID; write dùng fixed RPC chỉ nhận theme; mọi response được kiểm tra ownership, không global initialize/network call hoặc nối trực tiếp widget.
- Map auth, RLS, timeout, service unavailable, rate-limit, invalid response và unknown SDK errors sang failure đã sanitize; không giữ raw PostgREST message.

### Verification and build recovery

| Check | Result |
|---|---|
| `dart format .` | PASS — 80 files, 0 changed |
| Supabase offline validator | PASS — 1 table, 3 policies, 28 pgTAP assertions |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 73/73 |
| Production debug APK | PASS — 193,844,724 bytes; SHA-256 `40683400C5E2C370BB9F4A958A9583100F866FB5F6A23FA5F3CA57DB72FE73C7` |
| DEV debug APK | PASS — 193,844,724 bytes; SHA-256 `6ED3127E7665B820C97F5403A70AE08EC3E0FE35626F3957AFF155AB74A8E28E` |
| Production emulator smoke | PASS — 0 credential field, 0 technical string, 0 runtime error match |
| DEV emulator smoke | PASS — Login → Dashboard, four final nav labels, 0 technical string/runtime error match |

Build đầu tiên lỗi Kotlin incremental cache vì plugin source/Pub cache ở D còn repository ở C. Đã thêm `kotlin.incremental=false`, clean generated output và retry; cả hai APK PASS trong khi vẫn giữ cache/build trên D.

Artifacts nằm ngoài Git:

- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-supabase-foundation-production-debug.apk`
- `D:\DLU-LMS\Artifacts\dlu-lms-mobile-supabase-foundation-dev-debug.apk`

Storage sau final rebuild: C `57.41 GB`, D `70.01 GB` — gate C ≥ 15 GB và D ≥ 25 GB PASS.

### External blocker

`ACTION_REQUIRED: SUPABASE_PROJECT_CONNECTION_REQUIRED` — connector có nhiều project cũ inactive nhưng không project nào được xác nhận là DLU LMS Mobile. Không tự chọn/restore. Cần owner chọn hoặc tạo project non-production và chốt identity mapping trước khi apply migration, chạy pgTAP/advisors hay bật preferences sync.
