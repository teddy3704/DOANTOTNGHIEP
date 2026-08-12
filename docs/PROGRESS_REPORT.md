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
- Live Moodle vẫn cần `AUTHENTICATION_METHOD_UNCONFIRMED`, `MOODLE_WEB_SERVICES_STATUS_REQUIRED`, `TEST_ACCOUNT_REQUIRED` và `MOODLE_API_TOKEN_REQUIRED` trước Phase 3.
