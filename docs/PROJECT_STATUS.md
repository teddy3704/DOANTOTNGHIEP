# Project Status

**Cập nhật:** 2026-08-15 (Asia/Saigon)

**Milestone:** Moodle Schema Analysis & Synthetic Data + Student DEV Core

**Trạng thái milestone:** `PASS` — teacher schema analysis, `MOODLE_SUBSET_V1`, deterministic synthetic dataset, Student DEV flow, tests/build/emulator đều PASS

**Trạng thái production live:** `PARTIAL / BLOCKED_EXTERNAL` — DLU Web Services vẫn disabled; live API/auth integration chưa được phép triển khai

## Executive summary

Repository greenfield đã được scaffold thành Android-only Flutter project, application ID tạm thời `vn.edu.dlu.lmsmobile`. Phase 2 foundation và UI demo flow đã chạy qua format/analyze/test/debug build, Android 15 emulator smoke test và runtime log review.

Production entrypoint không phụ thuộc mock; do DLU authentication/Web Services chưa được xác nhận, production repository fail closed và hiển thị blocker phù hợp. Development entrypoint riêng inject dữ liệu synthetic có nhãn `DEV FIXTURE` để kiểm thử/demo UI.

Theo chỉ đạo mới nhất của GVHD, phase database không cần database/dump/data thật của DLU. Nhóm đã phân tích trực tiếp teacher-provided SchemaSpy Moodle LMS 3.9/MySQL 5.7.31, chốt `MOODLE_SUBSET_V1` gồm 20 bảng, tạo `PROJECT_SUBSET_SCHEMA`, seed/JSON deterministic với seed `202608`, validator integrity/privacy và tài liệu feature→table/join/ERD/CRUD. Nguồn này được gắn `TEACHER_SCHEMA_REFERENCE`, không bị gọi là production schema DLU.

DEV app đã bỏ hard-code fixture rời rạc và dùng một canonical JSON qua `SyntheticFixtureDataSource`. Student flow hiện render nhất quán Dashboard/Courses/sections/resources/Assignment/submission status/Grades/calendar summary/Profile. Production composition root không inject các adapter này và đã được re-verify fail closed trên emulator.

Phase 3B đã dùng chính browser session hiện có để xác minh read-only Dashboard, My Courses, một course đại diện, Profile, Calendar, own-grades navigation, notifications/messages navigation và course activity/resource metadata. Không lưu tên user/course, ID, grade, message, cookie/token hoặc `sesskey`.

Hai token/mobile site-check request không credential trả `errorcode=enablewsdescription`; REST entrypoint trả `403`. Vì vậy DLU hiện báo Web Services chưa được bật, `0` function đạt `VERIFIED_API`, mobile auth strategy vẫn `UNKNOWN`, và không có live DTO/repository nào được dựng từ HTML. Flutter production đã được harden để không hiển thị username/password; DEV fixture vẫn tách riêng.

## Repository audit

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Git repository | `.git` tồn tại; `main`; Phase 2 baseline commit `67953f8` | DONE |
| Uncommitted work | Không có file tracked/untracked tại thời điểm audit ban đầu | DONE |
| `README.md` | Không tồn tại trước audit; đã tạo entry point Phase 0 | DONE |
| `pubspec.yaml` | Flutter/Riverpod/go_router/Dio/secure storage | DONE |
| `lib/` | Feature-first foundation + demo milestone UI | DONE (Phase 2 scope) |
| `test/` | 32 unit/widget tests | DONE |
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

- Schema/synthetic/Student DEV milestone đã hoàn tất và quality-gated.
- Live Flutter authentication/current-user/courses integration vẫn cố ý chưa triển khai cho đến khi DLU bật/phê duyệt application-layer service/auth flow.
- Supabase chưa được wire trong milestone này; nếu bổ sung sau, nó phải là app-owned backend/Edge Function với RLS và không thay Moodle hoặc nhận service-role key ở client.

## BLOCKED

| Blocker code | Ảnh hưởng | Bằng chứng/thông tin cần có | Nguồn cung cấp phù hợp |
|---|---|---|---|
| `AUTHENTICATION_METHOD_UNCONFIRMED` | Public page có form local + Google OAuth2 nhưng chưa chứng minh backend/policy mobile | Xác nhận token login chuẩn, approved browser OAuth/SSO hoặc phương thức do DLU hỗ trợ | DLU LMS/identity administrator |
| `MOODLE_WEB_SERVICES_NOT_ENABLED` | Token/mobile site check trả `enablewsdescription`; không thể chạy API POC | DLU phê duyệt và bật Web Services + selected REST/mobile/external service, ưu tiên staging/test | DLU LMS administrator |
| `TEST_ACCOUNT_REQUIRED` | Sau enablement, cần kiểm chứng least-privilege student/teacher contexts | Student test identity trước; teacher account chỉ sau Student core PASS | DLU/GVHD |
| `MOODLE_API_TOKEN_REQUIRED` | Sau enablement, chưa có credential/token scope được phê duyệt | Approved short-lived test token/interactive auth; không gửi qua Git/docs/chat | DLU LMS administrator |
| `MOODLE_VERSION_REQUIRED_FOR_PLUGIN` | Không thể đánh giá/code custom plugin | Moodle, PHP và DB versions; plugin policy | DLU LMS administrator |
| `PACKAGE_IDENTITY_OWNERSHIP_UNCONFIRMED` | Package tạm đã dùng nhưng chưa có ownership/branding approval | DLU xác nhận application ID/branding/release ownership | DLU/GVHD/người dùng |

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
| 8 | Security/reliability | Threat controls, test coverage, error states, performance, privacy review | TODO |
| 9 | Release candidate | APK, release config, docs/demo/checklist, known limitations | TODO |

## NEXT STEP

1. Dùng bộ tài liệu `docs/database/` và `docs/FEATURE_DATA_TRACEABILITY.md` cho chương Database Analysis/bảo vệ; không xin database thật trong phase này.
2. Nếu thực hiện yêu cầu Supabase kế tiếp, chốt app-owned use case/project/config/RLS/Edge Function boundary riêng; không chuyển `MOODLE_SUBSET_V1` sang PostgreSQL rồi coi là Moodle schema.
3. DLU LMS administrator phê duyệt mobile integration và bật Web Services + selected REST/mobile/external service, ưu tiên staging/test.
4. Khi gate live mở, chạy POC đúng thứ tự: auth → current user/site info → own courses → one course content; chỉ sau sanitized successful contracts mới tạo DTO/repository live.
5. Xác nhận ownership của `vn.edu.dlu.lmsmobile`, branding chính thức và release signing trước Phase 9.
