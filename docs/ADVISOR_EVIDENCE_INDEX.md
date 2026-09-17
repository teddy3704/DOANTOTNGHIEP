# Advisor evidence index — 2026-09-17

**STUDENT SUPPORT ONLY — Development Integration API.** Dữ liệu Neon là dữ liệu
mẫu của mô hình phát triển; các ảnh không chứng minh kết nối production LMS DLU.
Đây là bằng chứng thực tế từ milestone local, không phải ảnh staging mới.

| Evidence | Nội dung đã xác minh | Phân loại |
|---|---|---|
| [03 — Swagger student API](../evidence/integration/03_swagger_student_api.png) | Swagger UI local, student API và disclaimer | Local PASS |
| [04 — Swagger health 200](../evidence/integration/04_swagger_health_200.png) | Execute `/health` trên Swagger local trả 200 | Local PASS |
| [05 — Postman agent required](../evidence/integration/05_postman_import_agent_required.png) | Postman Web chưa gọi được localhost trước khi cài Desktop Agent | HISTORICAL — đã xử lý, không phải blocker hiện tại |
| [06 — Render source required](../evidence/integration/06_render_source_required.png) | Form Web Service yêu cầu nguồn deploy trước khi có quyền publish | HISTORICAL — quyền publish nhánh riêng đã được cấp; không chứng minh deploy PASS |
| [07 — Postman collection](../evidence/integration/07_postman_collection_85_pass.png) | 17 requests, 85/85 assertions, 0 failed/skipped/errors | Local PASS — kết quả cuối của lượt local |
| [08 — Postman security](../evidence/integration/08_postman_security_pass.png) | Negative security cases trong lượt Postman local | Local PASS |

Postman local run ID: `58266634-a11cc32e-cb1f-4f03-a954-436dfd2739a9`.
Environment chỉ có `base_url` và `demo_student_code`; không có database credential.

## Checkpoint hiện tại

- Database First, Neon, local API, Swagger/OpenAPI và Postman local: PASS.
- Final local rechecks 2026-09-17: format/typecheck/build/export contracts PASS, 50 tests PASS,
  20 HTTP → Neon checks PASS, dependency audit 0 vulnerabilities.
- pgAdmin đã reconnect server Neon hiện có trong phiên này; ERD đã được xác minh
  theo checkpoint người dùng. Bộ 6 ảnh này không chứa ảnh ERD mới.
- Nhánh local `integration-api-render-staging` đã tạo; form Render đã cấu hình,
  chưa nhập secret, chưa deploy. Publication/deployment: IN_PROGRESS.
- `RENDER_STAGING_GATE=NOT_RUN`; `POSTMAN_STAGING_GATE=NOT_RUN`.
- Flutter đã được phê duyệt, chỉ bắt đầu sau khi cả hai staging gates PASS.

Không bổ sung ảnh staging hoặc đánh dấu PASS trước khi thao tác và kiểm tra thật.
Không chụp field credential, ghi giá trị connection secret hoặc đưa secret vào
Postman/export. Nếu Render cần secret, người dùng nhập trực tiếp vào secret field
và checkpoint dùng `ACTION_REQUIRED_RENDER_DATABASE_SECRET`.

## Phạm vi tài liệu xuất bản

Contract và kết quả có trong [API_CONTRACT.md](API_CONTRACT.md),
[TRACEABILITY_MATRIX.md](TRACEABILITY_MATRIX.md),
[API_TEST_RESULT.md](API_TEST_RESULT.md),
[API_SECURITY_MODEL.md](API_SECURITY_MODEL.md) và
[INTEGRATION_STATUS.md](INTEGRATION_STATUS.md).
Tài liệu mapping ở `database/` vẫn local-only, không nằm trong commit deploy API;
không giả định chúng có sẵn khi clone riêng nhánh triển khai.
