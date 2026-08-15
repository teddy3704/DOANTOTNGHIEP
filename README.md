# DLU LMS Mobile

Đồ án tốt nghiệp: **Xây dựng ứng dụng di động và hỗ trợ học tập trên nền tảng LMS** cho Trường Đại học Đà Lạt.

Repository đã hoàn thành **Phase 2 — Flutter Foundation** và đang chốt milestone **Moodle subset schema + canonical synthetic Student demo**. Tích hợp thật với `https://lms.dlu.edu.vn/` vẫn bị chặn cho đến khi DLU xác nhận authentication, Web Services và cung cấp test account/token phù hợp.

## Trạng thái nhanh

- Flutter 3.44.9, Dart 3.12.2, JDK 17 và Android SDK CLI đã được kiểm chứng.
- Android application ID: `vn.edu.dlu.lmsmobile`.
- Material 3 shell, Riverpod, go_router, Dio boundary và secure token storage abstraction đã tồn tại.
- DEV flow: Splash → Login → Dashboard → Courses → Course Detail/Resources → Assignment/Submission Status → Grades → Profile.
- Database analysis dùng `MOODLE_SUBSET_V1` gồm 20 bảng từ teacher-provided Moodle LMS 3.9 SchemaSpy, cùng dữ liệu AI-generated synthetic; đây không phải schema/data production DLU.
- Moodle version, cơ chế xác thực, Web Services và test account/token chưa được DLU cung cấp/xác nhận. Database thật không cần cho phase hiện tại theo chỉ đạo GVHD.
- Không có dữ liệu giả nào được coi là dữ liệu production.

Xem [Project Status](docs/PROJECT_STATUS.md), [Architecture](docs/ARCHITECTURE.md), [Selected Moodle Tables](docs/database/SELECTED_TABLES.md), [Feature/Data Traceability](docs/FEATURE_DATA_TRACEABILITY.md) và [Environment Setup](docs/ENVIRONMENT_SETUP.md).

## Nguyên tắc bắt buộc

- Flutter + Dart, target đầu tiên là Android, editor chính là Visual Studio Code.
- Không cài đặt hoặc sử dụng Android Studio; Android được build bằng SDK Command-line Tools.
- Flutter không kết nối trực tiếp production database của Moodle.
- Không commit secret, token, password, private key hoặc dữ liệu cá nhân thật.
- Không tuyên bố API hoạt động trước khi kiểm chứng trên môi trường được DLU cho phép.

Các quy tắc làm việc đầy đủ nằm trong [AGENTS.md](AGENTS.md).

## Chạy ứng dụng

Production shell không tự fallback sang mock và sẽ hiển thị blocker integration:

```powershell
.\tool\flutter_dlu.ps1 run -t lib/main.dart --dart-define=MOODLE_BASE_URL=https://lms.dlu.edu.vn
```

Sinh lại và kiểm tra canonical synthetic dataset (offline, seed `202608`):

```powershell
dart run tool/generate_moodle_sample_data.dart
dart run tool/validate_moodle_sample_data.dart
```

Demo UI dùng generated synthetic asset có nhãn `DEV FIXTURE`:

```powershell
.\tool\flutter_dlu.ps1 run -t lib/main_development.dart
```

Nếu chưa có Android device:

```powershell
.\tool\flutter_dlu.ps1 build apk --debug -t lib/main.dart
.\tool\flutter_dlu.ps1 build apk --debug -t lib/main_development.dart
```

Quality gate:

```powershell
dart format .
.\tool\flutter_dlu.ps1 analyze
.\tool\flutter_dlu.ps1 test
```

Wrapper giữ generated build trên `D:\DLU-LMS\Build\DoAnTotNghiep`, tạm dừng OneDrive trong lúc Flutter chạy và tháo junction `build\` trước khi bật sync lại. Hai VS Code launch profiles đã tự động dùng cùng workflow; không tạo junction thủ công trong thư mục OneDrive.
