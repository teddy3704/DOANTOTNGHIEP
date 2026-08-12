# AGENTS.md — DLU LMS Mobile Engineering Rules

File này áp dụng cho toàn bộ repository và là nguồn quy tắc lâu dài của dự án.

## 1. Mục tiêu và phạm vi

- Xây dựng ứng dụng Flutter/Dart hướng production cho sinh viên và giảng viên DLU, target đầu tiên là Android.
- LMS mục tiêu: `https://lms.dlu.edu.vn/`.
- Dữ liệu production cuối cùng phải đến từ Moodle/LMS hoặc nguồn dữ liệu Moodle được DLU cho phép.
- Không biến mock, fixture hoặc hard-code thành production data source.

## 2. Tooling bắt buộc

- Editor chính: Visual Studio Code.
- Không cài đặt, mở hoặc phụ thuộc Android Studio.
- Dùng Flutter CLI, Dart CLI, Android SDK Command-line Tools, `sdkmanager`, `adb` và JDK tương thích.
- Không tự thực hiện thay đổi hệ thống lớn. Ghi hướng dẫn và xin phép khi thay đổi vượt phạm vi repository.

## 3. Kiến trúc và tích hợp

- Luồng production ưu tiên: `Flutter -> HTTPS -> Moodle REST Web Services -> Moodle application layer -> Moodle database`.
- Flutter không được kết nối trực tiếp MySQL/MariaDB/PostgreSQL production của Moodle.
- Ưu tiên Moodle standard Web Services. Chỉ đề xuất custom Moodle plugin sau khi chứng minh API chuẩn không đáp ứng.
- Không code plugin theo Moodle/PHP/database version phỏng đoán.
- Base URL phải cấu hình được; không hard-code token, service shortname hoặc thông tin xác thực.
- Tách production repository khỏi fixture/mock repository. Production build không được silently fallback sang mock.
- Kiến trúc Flutter định hướng feature-first, clean architecture vừa đủ, dễ kiểm thử và dễ giải thích khi bảo vệ.

## 4. Bảo mật và quyền

- Không commit hoặc log password, API token, database password, private key, signing key hay dữ liệu cá nhân thật.
- Secret dùng environment/runtime config phù hợp; token thiết bị dùng secure storage.
- Không lưu lâu dài password Moodle.
- Không bypass SSO, CAPTCHA, MFA/2FA hoặc scrape dữ liệu private sau login để thay API.
- Authorization cuối cùng do Moodle/backend xác minh; client chỉ điều chỉnh UI theo capability đã được server cung cấp/xác nhận.
- Thiết kế least privilege và HTTPS-only cho production.
- Không WRITE production database/API, deploy production, rotate credential hoặc sửa server DLU nếu chưa có cho phép rõ ràng.
- Database dump/credential chỉ được phân tích read-only ban đầu và không đưa vào Git.

## 5. Chất lượng code

- Null safety, typed models, naming rõ ràng, state bất biến khi phù hợp.
- Không nuốt exception; lỗi phải được phân loại, chuyển thành state và hiển thị thông báo phù hợp.
- Không tạo abstraction/dependency khi chưa có use case thực tế.
- Không duplicate API logic, magic value hoặc file màn hình quá lớn.
- Mỗi dependency mới phải có lý do và được ghi trong thay đổi liên quan.
- Mọi màn hình lấy dữ liệu phải có loading, empty, error và retry state khi hợp lý.

## 6. Kiểm thử và quality gate

Khi Flutter project đã tồn tại, chạy theo thứ tự:

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

- Chỉ chạy release build nếu cấu hình release hợp lệ; không tạo signing secret giả.
- Phase không được `PASS` nếu analyze/test/build lỗi hoặc live API chưa được kiểm chứng.
- Trạng thái được phép: `PASS`, `FAIL`, `BLOCKED`, `PARTIAL`.
- Unit test: parsing, repository, service logic, error mapping.
- Widget test: critical loading/empty/error/success flows.
- Integration test: chỉ trên môi trường và tài khoản được cấp phép.

## 7. Git và file safety

- Luôn chạy `git status` trước và sau thay đổi.
- Không overwrite uncommitted work, không force reset, không xóa file không liên quan.
- Không commit `.env`, token, password, database dump, private key hoặc production data.
- Giữ patch theo phase/mục tiêu logic; chỉ commit/push khi người dùng yêu cầu hoặc cho phép.

## 8. Tài liệu bắt buộc phải đồng bộ

Khi code hoặc quyết định kiến trúc thay đổi, cập nhật các tài liệu liên quan:

- `docs/PROJECT_STATUS.md`: DONE / IN PROGRESS / BLOCKED / TODO / NEXT STEP.
- `docs/ARCHITECTURE.md`: kiến trúc và diagram phản ánh code thật.
- `docs/MOODLE_INTEGRATION.md` và `docs/API_MATRIX.md`: kết quả discovery/verification thực tế.
- `docs/DATABASE_MAPPING.md`: chỉ ghi mapping đã xác minh; giả thuyết phải gắn nhãn rõ.
- `docs/SECURITY.md`: threat/control changes.
- `docs/TEST_PLAN.md`: test scope và quality gate.
- `docs/PROGRESS_REPORT.md`: ngày, công việc, kết quả, test, vấn đề và việc tiếp theo.

## 9. Mock và dữ liệu development

- Mock/fixture chỉ nằm ở dev/test layer, có nhãn `MOCK`, không chứa PII thật.
- Không gọi mock integration là Moodle integration hoàn chỉnh.
- Không để production configuration tự động dùng fixture khi API lỗi.

## 10. Quy tắc khi thiếu thông tin

Không đoán endpoint, schema, table prefix, version, role, capability, token, service name hoặc dữ liệu người dùng. Dùng blocker code rõ ràng:

- `MOODLE_API_TOKEN_REQUIRED`
- `TEST_ACCOUNT_REQUIRED`
- `MOODLE_WEB_SERVICES_NOT_ENABLED`
- `DLU_MOODLE_DATABASE_NOT_PROVIDED`
- `MOODLE_VERSION_REQUIRED_FOR_PLUGIN`
- `AUTHENTICATION_METHOD_UNCONFIRMED`

Mỗi blocker phải nêu chính xác bằng chứng cần nhận và ai có thể cung cấp. Không yêu cầu production admin password.

## 11. Trình tự phase

0. Repository & Environment Audit
1. Moodle/System Analysis
2. Flutter Foundation
3. Moodle Authentication
4. Courses
5. Course Content
6. Student Features
7. Teacher Features
8. Security & Reliability
9. Release Candidate

Không nhảy qua quality gate của phase hiện tại. Chức năng WRITE của teacher chỉ được phát triển/test sau khi endpoint, capability và môi trường test được xác nhận.

## 12. Format bàn giao

Mỗi task/phase phải báo cáo: `STATUS`, `FILES CHANGED`, `WHAT WAS IMPLEMENTED`, `TESTS`, `COMMANDS RUN`, `RESULT`, `BLOCKERS`, `NEXT STEP`.
