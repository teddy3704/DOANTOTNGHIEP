# Security model — Student Support Development API

**Không phải production authentication hoặc production DLU API.** Chỉ dữ liệu
mẫu trong database phát triển đã được chủ dự án cho phép. Không sửa Flutter trong
phase này, không đưa database credential đến client.

## Identity và ranh giới tin cậy

- `APP_ENV` chỉ nhận `development` hoặc `staging`; production bị từ chối lúc nạp
  cấu hình. `DEMO_AUTH_ENABLED=true` là điều kiện bật demo identity.
- Mọi `/api/v1/me/...` sử dụng header `X-Demo-Student-Code`, không lấy student tùy
  ý từ query/body. Mã phải qua validation và khớp user mẫu, role student, hoạt động.
- Header có thể bị người gọi sửa. Đây là **impersonation tiện dụng cho kiểm thử**,
  không password, session, JWT hay chứng minh quyền sở hữu tài khoản. Không dùng
  với dữ liệu thật hoặc gọi đây là bảo mật production hoàn chỉnh.
- Header thiếu, sai hoặc không phải student hợp lệ bị từ chối. Tắt demo identity
  không tạo fallback sang user đầu tiên. `/health` không cần identity.
- Future DLU authentication, service/token/OAuth/SSO/capabilities: **TO_VERIFY_DLU**.
  Chỉ DLU/LMS administrator cung cấp cơ chế được hỗ trợ; không lấy browser session
  hoặc yêu cầu production admin password để thay thế.

## Isolation và quyền đọc

| Rủi ro | Kiểm soát / giới hạn |
|---|---|
| Course ID thuộc sinh viên khác | Kiểm tra ghi danh hoạt động theo principal trước khi đọc nội dung; course không được phép không trả nội dung |
| Lấy điểm/trạng thái người khác | Filter student code ở data source, không chỉ che UI; guard membership và visibility của course/activity |
| Teacher giả làm student | Lookup profile phải kiểm tra student role và trạng thái, không chấp nhận mọi row trong `users` |
| SQL injection | SQL cố định và parameters; không nối mã sinh viên/course ID vào SQL |
| API vô tình ghi dữ liệu | Không có route nghiệp vụ ghi; mỗi truy vấn database đi trong transaction read-only; không auto-migration |
| Phơi bày tài liệu | Trả metadata phạm vi cho phép; không đọc/execute binary hoặc lộ local path; chưa có download proxy |
| Gửi synthetic ID sang LMS thật | Deep-link để null/TO_VERIFY_DLU; không tự suy luận URL activity |

Role database được cấp hiện tại không mặc nhiên là một role least-privilege chỉ
SELECT. Read-only transaction là lớp bảo vệ của ứng dụng, **không thay thế** quyền
database tối thiểu. Không tự tạo/đổi role, grant hoặc rotate credential. Trước khi
mở rộng staging ngoài demo có kiểm soát, cần review dedicated read-only role,
network exposure và authentication thật; không đưa dữ liệu thật vào demo header.

## Secret và transport

Tệp local `integration-api/.env` được Git bỏ qua. Nó chỉ được process backend đọc;
không chép vào tài liệu, screenshot, terminal output, source, OpenAPI hoặc Postman
environment. `.env.example` là template không có giá trị bí mật. Không đọc lại
credential từ pgAdmin, không in config/process environment, không log password.

Kết nối PostgreSQL dùng TLS có kiểm chứng certificate; không tắt
`rejectUnauthorized`. Pool tối đa 4 connection. Client HTTP local chỉ bind loopback
ở development; staging dùng HTTPS do hosting cung cấp. Không đưa Neon host/role,
SQL hoặc chi tiết certificate/auth failure vào HTTP response công khai.

Theo [node-postgres SSL](https://node-postgres.com/features/ssl), tùy chọn SSL trong
connection string có thể ảnh hưởng object `ssl`; cấu hình của dự án phải xử lý
điều này có chủ đích để vẫn giữ certificate verification, không dựa vào việc URL
có chữ SSL như một chứng nhận an toàn.

## Logging và errors

Logs chỉ dùng trường allowlist cần cho vận hành, ví dụ request ID, route template,
method/status và elapsed time. Không log raw URL/query, headers, body, database
error object/stack hoặc config. Unknown error được đổi thành code/message an toàn.
Không serialize exception tùy ý rồi redaction sau cùng.

Error response dùng `{ "error": { "code": "...", "message": "..." } }`.
Validation/identity/ownership/dependency failure không lộ SQL, URI hay credential.
HTTP status và error code cụ thể phải đối chiếu `API_CONTRACT.md` và OpenAPI export.

Schema được định nghĩa trong source kiểm soát, không nhận schema do người gọi gửi.
Fastify khuyến nghị JSON Schema cho validation/serialization và không thực hiện
database access trong initial schema validation; identity lookup được đặt ở hook
phù hợp. [Nguồn Fastify](https://fastify.dev/docs/latest/Reference/Validation-and-Serialization/).

## Không triển khai

Không login DLU bằng credential mẫu; không upload/nộp bài; không chấm điểm hoặc
ghi feedback; không teacher/admin endpoints; không ghi course/enrolment/role/quiz;
không proxy SQL tùy ý; không app reminder write trong phase này. Nộp/chấm tiếp tục
thuộc LMS DLU, không biến database phân tích thành một LMS production thay thế.

## Kiểm chứng

Test cần bao phủ identity thiếu/sai/disabled, non-student, course ngoài quyền,
scoped grade/status, query injection, write method bị từ chối, error/log không lộ
secret và real-Neon read-only path. Kết quả thực thi ở `API_TEST_RESULT.md`; không
đánh đồng pass của test doubles với real-Neon hoặc DLU production integration.
