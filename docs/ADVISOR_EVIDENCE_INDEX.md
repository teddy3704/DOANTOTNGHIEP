# Advisor evidence index — 2026-09-18

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
| [09 — Render staging Live](../evidence/integration/09_render_staging_live.png) | Service Node Free Live, source `integration-api-render-staging`, commit `e241f8a` | Render staging PASS |
| [10 — Postman Render staging](../evidence/integration/10_postman_render_staging_85_pass.png) | Environment staging, 17 requests, 85/85 assertions, 0 errors | Postman staging PASS |

Postman local run ID: `58266634-a11cc32e-cb1f-4f03-a954-436dfd2739a9`.
Environment chỉ có `base_url` và `demo_student_code`; không có database credential.

## Checkpoint hiện tại

- Database First, Neon, local API, Swagger/OpenAPI và Postman local: PASS.
- Final local rechecks 2026-09-17: format/typecheck/build/export contracts PASS, 50 tests PASS,
  20 HTTP → Neon checks PASS, dependency audit 0 vulnerabilities.
- pgAdmin đã reconnect server Neon hiện có trong phiên này; ERD đã được xác minh
  theo checkpoint người dùng. Bộ 6 ảnh này không chứa ảnh ERD mới.
- Render staging đã deploy từ commit `e241f8a`; public `/health`, `/docs` và
  `/openapi.json` đều HTTP 200. OpenAPI 3.0.3 có 11 GET operations, same-origin `/`.
- Independent status-only smoke: 19/19 PASS, gồm mười student GET 200 và sáu
  expected negative 401/404/404/400/404/404. Không in response body hoặc secret.
- Postman staging: 17 requests, 85/85 assertions, 0 failed/skipped/errors.
  `RENDER_STAGING_GATE=PASS`; `POSTMAN_STAGING_GATE=PASS`.
- Flutter đã được phê duyệt và unblocked, nhưng phải bắt đầu trong worktree sạch để
  không ảnh hưởng phần demo/Flutter local chưa commit.

Ảnh 09 và 10 là bằng chứng sau khi thao tác và kiểm tra thật. Không chụp field
credential, ghi giá trị connection secret hoặc đưa secret vào Postman/export.

## Phạm vi tài liệu xuất bản

Contract và kết quả có trong [API_CONTRACT.md](API_CONTRACT.md),
[TRACEABILITY_MATRIX.md](TRACEABILITY_MATRIX.md),
[API_TEST_RESULT.md](API_TEST_RESULT.md),
[API_SECURITY_MODEL.md](API_SECURITY_MODEL.md) và
[INTEGRATION_STATUS.md](INTEGRATION_STATUS.md).
Tài liệu mapping ở `database/` vẫn local-only, không nằm trong commit deploy API;
không giả định chúng có sẵn khi clone riêng nhánh triển khai.
