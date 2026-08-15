# Progress Report

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
