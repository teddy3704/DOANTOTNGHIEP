# Kiến trúc Development Integration API

Phạm vi hiện tại: **STUDENT SUPPORT ONLY**. Tài liệu này mô tả lớp API phát triển
độc lập trong `integration-api/` và consumer Flutter staging chỉ đọc đã được
xác minh trong clean worktree. **This is NOT the production DLU LMS API.**

## Current development

Schema Moodle do GVHD cung cấp là cơ sở phân tích. Mô hình PostgreSQL trong Neon
chứa dữ liệu mẫu, không phải bản sao dữ liệu sinh viên DLU. Luồng hiện tại là:
schema tham chiếu → mô hình Neon → Development Integration API → Swagger/Postman
→ explicit Flutter staging consumer. Render staging và Postman staging đều đã
`PASS`; Flutter consumer cũng đã PASS quality/emulator gate riêng. Không có gate
nào trong số này biến nó thành production hoặc live Moodle integration.

| Thành phần | Trách nhiệm / giới hạn |
|---|---|
| `database/` (workspace local-only) | Mô hình phân tích, mapping, seed mẫu và view đã có; không đưa vào nhánh deploy API. Runtime chỉ kết nối mô hình Neon hiện có, không chạy migration hoặc sửa seed khi khởi động |
| `integration-api/src/domain/student-learning.ts` | Typed DTO và `StudentLearningDataSource`; không phụ thuộc Fastify hoặc PostgreSQL |
| `PostgresDevelopmentDataSource` | Đọc view `lms` và kiểm tra student/course/visibility; không ghi bảng Moodle-owned |
| Fastify 5 + TypeScript strict | Route, validation, response schema, identity mẫu, safe error mapping |
| `pg` | Pool nhỏ, TLS kiểm chứng chứng thư, truy vấn tham số hóa trong transaction read-only |
| `/docs`, `/openapi.json` | Hợp đồng API development; không chứng minh Moodle Web Services DLU đang bật |
| Postman | Consumer kiểm thử HTTP; không nhận credential kết nối database |
| Render | Dedicated branch `integration-api-render-staging` deploy commit `e241f8a` lên Node Free staging; `/health`, `/docs`, `/openapi.json` đều HTTP 200; chi tiết/evidence ở `INTEGRATION_STATUS.md` |

Identity development lấy từ header `X-Demo-Student-Code`, kiểm tra tài khoản mẫu
student đang hoạt động. Header này **không phải xác thực**: người dùng biết mã khác
có thể chọn sinh viên mẫu khác. Chỉ dùng development/staging được phép; không chứa
PII thật. Các query vẫn phải giới hạn dữ liệu theo principal đã chọn và ghi danh.

## Flutter staging consumer — verified PASS (read-only)

`lib/main_staging.dart` là composition root được chọn tường minh, không phải
fallback của production. Nó inject `StudentSupportApiClient` và staging
repositories vào contract/domain provider đã có, nên presentation giữ cùng flow
Student Dashboard/Courses/Content/Assignments/Grades/Calendar/Profile. Client chỉ
cho phép HTTPS, origin đã cấu hình, 11 GET route contract và header development
identity; không gửi password, token Moodle, `Authorization` header, database
credential hoặc mutation request.

Staging preview không thay thế đăng nhập DLU: `main.dart` tiếp tục fail closed và
`main_development.dart` tiếp tục là fixture boundary riêng. `dart format .`,
`flutter analyze` và `flutter test` (93 tests) đã PASS. Emulator đã xác minh
Dashboard, Courses, Course Detail, Resource Detail, Assignment Detail, Grades,
Calendar và Profile. Không có password login DLU, upload, submission, grading hay
write workflow nào được thêm hoặc giả lập ở boundary này.

API tái sử dụng `vw_assignment_status`, không tạo view trùng chỉ để đổi tên thành
`vw_student_assignment_status`. Hai teacher views hiện có trong mô hình phân tích
không trở thành teacher endpoints. Submission/grade trong Neon là trạng thái mẫu
để đọc; API này không nhận bài nộp, file upload, điểm hay feedback mới.

## Target production — chưa triển khai/xác minh

DLU LMS → Moodle Web Services được DLU hỗ trợ → integration boundary → Student
Support Mobile. Identity, ghi danh, capability, điểm/tệp hiển thị do Moodle/backend
xác minh. `MoodleDataSource` là adapter tương lai của contract, không dùng browser
cookie, không scrape trang private, không kết nối Flutter trực tiếp database.

Không tự động thử live rồi dùng dữ liệu mẫu khi lỗi. Adapter development chỉ được
chọn trong cấu hình development/staging; process từ chối `APP_ENV=production`.
Việc triển khai production đòi hỏi adapter, authentication và authorization thật,
không chỉ đổi tên biến môi trường hoặc URL.

Moodle-owned: hồ sơ, khóa học, nội dung, tài liệu, bài tập, trạng thái, điểm và tiến
độ/lịch. App-owned: nhắc nhở và tùy chọn cá nhân, hiện không thêm bảng/endpoint trong
phase này. Không nhân bản nghiệp vụ Moodle sang Supabase; foundation cũ không sửa.

## Resource và deep-link

Response tài liệu chỉ có metadata đã biết. Không có binary download/proxy endpoint.
`deepLink: null`, `deepLinkStatus: TO_VERIFY_DLU` thể hiện URL activity chưa được
DLU xác nhận; không ghép URL từ ID Neon. Nộp bài phải diễn ra trên LMS qua liên kết
được xác minh sau này, không triển khai submission endpoint ở Mobile/API này.

## Chất lượng và trạng thái

Các gate build/test/real-Neon/browser phải có bằng chứng thực thi riêng ở
`API_TEST_RESULT.md` và `INTEGRATION_STATUS.md`. Render/Postman staging và
Flutter read-only consumer đều đã PASS với evidence riêng; kiến trúc, export hoặc
test dùng test doubles không tự chứng minh production DLU PASS.

Nguồn kỹ thuật: [Fastify validation và serialization](https://fastify.dev/docs/latest/Reference/Validation-and-Serialization/)
cho schema request/response; [node-postgres SSL](https://node-postgres.com/features/ssl)
cho cấu hình TLS. Contract API cụ thể: `API_CONTRACT.md`; threat/control:
`API_SECURITY_MODEL.md`; truy vết SV-01..10: `TRACEABILITY_MATRIX.md`.
