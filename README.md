# DLU LMS Mobile

Đồ án tốt nghiệp: **Xây dựng ứng dụng di động và hỗ trợ học tập trên nền tảng LMS** cho Trường Đại học Đà Lạt.

Repository đã hoàn thành Flutter foundation, Moodle subset/schema reference, canonical synthetic dataset và milestone **production product UI polish** cho Student V1. Tích hợp thật với `https://lms.dlu.edu.vn/` vẫn bị chặn cho đến khi DLU xác nhận authentication, Web Services và cấp quyền test phù hợp.

## Trạng thái nhanh

- Flutter 3.44.9, Dart 3.12.2, JDK 17 và Android SDK CLI đã được kiểm chứng.
- Android application ID: `vn.edu.dlu.lmsmobile`.
- Material 3, Riverpod, go_router, Dio boundary, secure-storage abstraction và feature-first repositories đã tồn tại.
- Student flow: Splash → Login → Trang chủ → Khóa học → Chi tiết/Tài liệu/Bài tập/Điểm → Lịch → Hồ sơ.
- Primary navigation gồm bốn mục `Trang chủ` / `Khóa học` / `Lịch` / `Hồ sơ`; màn hình dữ liệu có loading/empty/error/retry phù hợp.
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

Production entrypoint không tự fallback sang dữ liệu mẫu. Khi DLU auth/API chưa được phê duyệt, app đóng an toàn và hiển thị thông báo thân thiện:

```powershell
.\tool\flutter_dlu.ps1 run -t lib/main.dart --dart-define=MOODLE_BASE_URL=https://lms.dlu.edu.vn
```

Sinh lại và kiểm tra canonical synthetic dataset (offline, seed `202608`):

```powershell
dart run tool/generate_moodle_sample_data.dart
dart run tool/validate_moodle_sample_data.dart
```

Demo UI dùng generated synthetic asset qua composition root riêng; giao diện vẫn giống sản phẩm và không hiển thị nhãn development:

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
