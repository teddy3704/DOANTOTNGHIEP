# Project Status

**Cập nhật:** 2026-08-12 (Asia/Saigon)

**Milestone:** Phase 2 — Flutter Foundation + Android Emulator Demo Milestone

**Trạng thái tổng thể:** `PARTIAL` — local foundation PASS, live Moodle integration BLOCKED

## Executive summary

Repository greenfield đã được scaffold thành Android-only Flutter project, application ID tạm thời `vn.edu.dlu.lmsmobile`. Phase 2 foundation và UI demo flow đã chạy qua format/analyze/test/debug build, Android 15 emulator smoke test và runtime log review.

Production entrypoint không phụ thuộc mock; do DLU authentication/Web Services chưa được xác nhận, production repository fail closed và hiển thị blocker phù hợp. Development entrypoint riêng inject dữ liệu synthetic có nhãn `DEV FIXTURE` để kiểm thử/demo UI.

Không có bằng chứng cho thấy DLU Moodle REST Web Services, mobile service, token login, SSO flow, Moodle version, function list, capability hoặc database schema đã được cung cấp/xác nhận. Tất cả tích hợp thật tiếp tục ở trạng thái `BLOCKED`.

## Repository audit

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Git repository | `.git` tồn tại; `main`; chưa có commit | DONE |
| Uncommitted work | Không có file tracked/untracked tại thời điểm audit ban đầu | DONE |
| `README.md` | Không tồn tại trước audit; đã tạo entry point Phase 0 | DONE |
| `pubspec.yaml` | Flutter/Riverpod/go_router/Dio/secure storage | DONE |
| `lib/` | Feature-first foundation + demo milestone UI | DONE (Phase 2 scope) |
| `test/` | 13 unit/widget tests | DONE |
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

### Latest emulator re-verification — 2026-08-12 22:47 ICT

- Không tải/cài lại toolchain: Emulator 37.1.11, Android 35 Google APIs x86_64 image revision 9 và AVD `DLU_LMS_Pixel` hiện có đều hợp lệ trên D.
- Xác minh lại toàn bộ path nặng nằm trên D: Android SDK/emulator/AVD, Gradle cache, Pub cache, generated build output và APK artifacts.
- `flutter run -d emulator-5554 -t lib/main_development.dart --no-resident` PASS; kiểm thử trực tiếp Splash → Login → Dashboard → Courses → Course Detail → Profile PASS.
- PID-scoped logcat có `0` crash, ANR, Flutter exception, RenderFlex/overflow, unhandled exception hoặc platform exception; không phát hiện lỗi source cần sửa.
- Làm mới đủ 6 ảnh trong `docs/screenshots/emulator/`; ảnh chỉ dùng synthetic `DEV FIXTURE`.
- `dart format .` PASS (39 files, 0 changed), `flutter analyze` PASS (0 issues), `flutter test` PASS (13 tests).
- Build lại DEV fixture và production-entrypoint debug APK trên D; cả hai giữ package `vn.edu.dlu.lmsmobile`, minSdk 24, targetSdk 36.
- Khi bàn giao: C còn `20.85 GB`, D còn `74.98 GB`; storage gate C ≥ 15 GB PASS.

## IN PROGRESS

- Không có task local foundation đang chạy. Milestone tiếp theo là Phase 3 Moodle Authentication sau khi DLU cung cấp evidence/access.

## BLOCKED

| Blocker code | Ảnh hưởng | Bằng chứng/thông tin cần có | Nguồn cung cấp phù hợp |
|---|---|---|---|
| `AUTHENTICATION_METHOD_UNCONFIRMED` | Không thể thiết kế login production cuối cùng | Xác nhận token login chuẩn, SSO/OAuth hoặc phương thức do DLU hỗ trợ | DLU LMS administrator |
| `MOODLE_WEB_SERVICES_STATUS_REQUIRED` | Không thể gọi live API | Web Services, REST và mobile/external service status | DLU LMS administrator |
| `TEST_ACCOUNT_REQUIRED` | Không thể kiểm chứng quyền/student-teacher flow | Student và teacher test account trên staging/test hoặc scope an toàn | DLU/GVHD |
| `MOODLE_API_TOKEN_REQUIRED` | Không thể xác minh function responses | Token/test-token theo policy được duyệt; không gửi qua Git | DLU LMS administrator |
| `MOODLE_VERSION_REQUIRED_FOR_PLUGIN` | Không thể đánh giá/code custom plugin | Moodle, PHP và DB versions; plugin policy | DLU LMS administrator |
| `DLU_MOODLE_DATABASE_NOT_PROVIDED` | Không thể xác nhận prefix/schema/ERD vật lý | Schema/dump đã ẩn danh hoặc read-only access được duyệt | DLU database/LMS administrator |
| `PACKAGE_IDENTITY_OWNERSHIP_UNCONFIRMED` | Package tạm đã dùng nhưng chưa có ownership/branding approval | DLU xác nhận application ID/branding/release ownership | DLU/GVHD/người dùng |

Không yêu cầu production admin password và không cần production database WRITE access.

## Technical debt / risks hiện tại

1. Authentication topology của DLU chưa rõ; token endpoint không được coi là khả dụng cho đến khi được xác nhận.
2. Moodle version/function exposure/capabilities chưa rõ; API matrix mới là discovery backlog.
3. Chưa có branding/release signing ownership approval; UI dùng generic school icon, không dùng logo DLU chính thức.
4. Workspace nằm trong OneDrive và OneDrive không hỗ trợ junction trong synced root. Junction `build/` hiện được giữ ngoài OneDrive tại `%LOCALAPPDATA%\DLU-LMS\WorkspaceLinks`, chỉ kích hoạt trong lúc wrapper tạm dừng OneDrive rồi được tháo trước khi sync chạy lại. Build thật vẫn ở `D:\DLU-LMS\Build\DoAnTotNghiep`.
5. `flutter_secure_storage` được pin 10.3.1 vì 11.0.0 yêu cầu compile SDK 37 trong khi current stable project/toolchain dùng SDK 36; cần review lại khi API 37 tooling ổn định.
6. Emulator Android 15/API 35 đã PASS; chưa có smoke test trên thiết bị Android vật lý.
7. Hai generated/staging directories đã xác minh là không cần (`1.90 GB` build backup và `1.06 GB` interrupted SDK staging) vẫn còn trên D vì local delete policy chặn lệnh trước khi thực thi; không ảnh hưởng gate C ≥ 15 GB.

## TODO / backlog Phase 0 → Phase 9

| Phase | Mục tiêu | Exit criteria | Trạng thái |
|---|---|---|---|
| 0 | Audit repository/environment; governance/docs | Toolchain status và blockers rõ; docs baseline verified | PASS |
| 1 | Moodle/system analysis | Use cases, role/capability evidence, live function inventory, auth decision | BLOCKED — cần DLU evidence |
| 2 | Flutter foundation | App scaffold, Material 3, router, config, errors/network/storage, shell tests | PASS |
| 3 | Moodle authentication | Login → token/session → site/user info → dashboard trên account test | BLOCKED — auth/API/test account |
| 4 | Courses | Courses thật theo user/capability | BLOCKED — Phase 3 + function access |
| 5 | Course content | Course detail/content/file access thật, safe authenticated download | BLOCKED — Phase 4 + file policy |
| 6 | Student features | Assignment/grade/calendar/notification/profile theo API thật | BLOCKED — function/capability verification |
| 7 | Teacher features | Read flows trước; write flows chỉ ở test environment được duyệt | BLOCKED — teacher account + explicit write permission |
| 8 | Security/reliability | Threat controls, test coverage, error states, performance, privacy review | TODO |
| 9 | Release candidate | APK, release config, docs/demo/checklist, known limitations | TODO |

## NEXT STEP

1. Xin DLU/GVHD: authentication method, Moodle version, Web Services/REST/mobile service status, sanitized function list và student/teacher test accounts.
2. Khi có evidence, triển khai Phase 3 `AuthRepository` thật: approved login → token/session → site/user info → secure storage → dashboard.
3. Nếu có thiết bị Android vật lý, chạy thêm smoke test để bổ sung coverage ngoài emulator.
4. Xác nhận ownership của `vn.edu.dlu.lmsmobile`, branding chính thức và release signing trước Phase 9.
