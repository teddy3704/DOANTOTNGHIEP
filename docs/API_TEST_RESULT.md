# Development Integration API — kết quả kiểm thử

Checkpoint: 2026-09-17. Workspace `D:\DoAnTotNghiep`. Đây không phải API production DLU.

Local recheck cuối ngày 2026-09-17 xác nhận format/typecheck/build/export contracts,
50 automated tests, 20 HTTP → Neon checks và dependency audit 0 vulnerabilities.
44 tests ban đầu vẫn PASS, thêm 1 staging Swagger test và 5 index-scan tests. Swagger và
Postman Web dưới đây là bằng chứng local đã xác minh ở milestone trước; không
gán lại chúng thành staging results hoặc tuyên bố đã chạy lại browser hôm nay.

## Gate local: PASS

| Kiểm tra | Kết quả thực thi |
|---|---|
| Dependency install | PASS, Node 24.15.0; cache/dependencies trên D |
| Format + format check | PASS, Prettier |
| TypeScript strict + build | PASS |
| Unit/HTTP/security tests | 50/50 PASS, 0 fail, 0 skipped |
| Dependency audit | 0 vulnerabilities sau khi cập nhật Swagger UI 6.1.1 |
| Neon connectivity / readonly transaction | PASS; `transaction_read_only=on` |
| Actual database inventory | 22 tables, 10 views, 35 physical FK; 8 student/support views |
| Real HTTP → Neon smoke | PASS; 20 checks, không dùng fixture fallback |
| `/health` on running local server | 200; browser Swagger Execute cũng trả 200 |
| Missing identity on running local server | 401 |
| `/openapi.json` | PASS, OpenAPI 3.0.3, 11 GET operations |
| `/docs/` browser | PASS; đúng tên API, disclaimer và localhost server |
| Secret scan | PASS before staging: 0 secret value matches in working tree/index, ignored local config; recheck actual staged/committed blobs before push |
| Postman Web via Desktop Agent | PASS: 17 requests, 85/85 assertions, 0 failed/skipped/errors |
| Preserved Flutter source | Previous comparison PASS: 160 files hash-equal to original C workspace; no Flutter edit in deployment phase |
| pgAdmin connection | Reconnected to existing Neon server; ERD previously verified per user checkpoint |
| Render staging | NOT_RUN: deployment IN_PROGRESS, no verified public URL yet |
| Postman staging | NOT_RUN: requires verified Render URL |

## Dữ liệu đọc thật từ Neon

SV001 có 2 khóa học (1, 2), 4 activity của course 1, 4 resource rows, 4 assignments,
4 assignment-status rows, 2 grade rows, 2 progress rows và 2 upcoming deadlines tại
thời điểm chạy. Deadline thay đổi theo thời gian; không hard-code các count này
trong API. Profile và overview trả 200. Grade SV001 khớp truy vấn database theo
đúng principal; SV002 được đối chiếu phạm vi riêng.

GV001/unknown student bị 401; course 3 không thuộc SV001 và course không tồn tại
đều 404; query cố đổi student code bị 400. Status/grades/deadlines được lọc thêm
qua catalogue assignment hiển thị, không lộ module/section ẩn.

## Security coverage theo yêu cầu SEC-01..10

| Mã yêu cầu | Bằng chứng | Kết quả |
|---|---|---|
| SEC-01 thiếu identity | HTTP tests và Neon 401 | PASS |
| SEC-02 invalid synthetic identity | malformed/unknown/teacher checks | PASS |
| SEC-03 inaccessible course | repository + HTTP + Neon 404 | PASS |
| SEC-04 unknown course | HTTP + Neon cùng response 404 | PASS |
| SEC-05 no DB secret in response | safe error marker tests + real URL comparison in memory | PASS |
| SEC-06 no password/token fields | allowlisted schema/SQL projections tests | PASS |
| SEC-07 no submission route | POST upload/submission rejected | PASS |
| SEC-08 no teacher grading route | POST teacher/grade rejected | PASS |
| SEC-09 scoped student grades | two student fixtures + actual scoped Neon query | PASS |
| SEC-10 sanitized unexpected errors | safe 500 and captured logger assertions | PASS |

Tên test SEC trong source được nhóm theo hành vi; bảng này map đầy đủ 10 yêu cầu.
7 database-wrapper tests kiểm tra transaction/rollback/release, destroy connection
khi rollback thất bại, URI boundary, TLS không thể bị URI options vô hiệu hóa.

Log thật của request thành công và lỗi có route template, request ID, status,
duration; không có URL database, header, SQL, record hoặc raw exception. Ví dụ
đã quan sát `/health` 200 và `/api/v1/me/courses` 401.

## Postman / Render

Postman collection và environment đã import **2/2** vào workspace hiện có; dùng
`DLU LMS Development`. Cloud Agent ban đầu bị chặn do localhost; đã xử lý bằng
Desktop Agent 0.5.1 chính thức, chữ ký Postman hợp lệ, cài với phép của người dùng.
Environment chỉ có `base_url` và `demo_student_code`, không chứa database secret.

**POSTMAN_GATE=PASS**: chạy toàn bộ 17 requests, 1 iteration, 85/85 assertions;
0 failed, 0 skipped, 0 errors; duration 15.694 s, average response 794 ms.
Run ID `58266634-a11cc32e-cb1f-4f03-a954-436dfd2739a9`.
11 GET positive đều 200. Negative cases: missing identity 401; inaccessible và
unknown course 404; identity override query 400; submission/grading route 404.
Không dùng/lưu cookie trong lượt chạy. Hai POST negative không có handler ghi.
Assertions kiểm tra status, JSON, data/error envelope, safe response keys và
list count khi response là danh sách; không tuyên bố đây là full JSON Schema
validation. Typed schema/ownership có kiểm thử backend riêng.

Screenshot thật đã lưu trên D:
`../evidence/integration/07_postman_collection_85_pass.png`.
Ảnh `05_postman_import_agent_required.png` là bằng chứng blocker trước khi cài
Agent, không phải trạng thái cuối. Có 6 ảnh trong `evidence/integration/`, gồm
`08_postman_security_pass.png`. Cơ chế duyệt lệnh tạm hết capacity rồi phục hồi;
copy ảnh được duyệt qua đúng cơ chế, không bypass. Backend đã khởi động lại sau
khi phiên terminal cũ kết thúc; health cuối trả `ok` / database `reachable`.

Render precheck trước đây bị chặn tại nguồn deploy; ảnh
`06_render_source_required.png` chỉ là bằng chứng lịch sử. Người dùng hiện đã cho
phép commit/push riêng nhánh `integration-api-render-staging`; nhánh local đã tạo,
publication/deploy đang **IN_PROGRESS**. Không merge main hoặc force-push. Chưa có public staging URL
được xác minh: `RENDER_STAGING_GATE=NOT_RUN`, `POSTMAN_STAGING_GATE=NOT_RUN`.

Form Render đã cấu hình root `integration-api`, Node `24.15.0`, build
`npm ci --include=dev && npm run build`, start `npm start`, health `/health`, Free,
Singapore, `APP_ENV=staging`, `DEMO_AUTH_ENABLED=true`, `NPM_CONFIG_CACHE=/tmp/npm`
và `NODE_VERSION=24.15.0`. Chưa nhập database secret hoặc deploy.
Database secret chỉ do người dùng nhập vào secret environment field; nếu cần
nhập, dừng với `ACTION_REQUIRED_RENDER_DATABASE_SECRET`. Không đưa secret vào
collection/export, source, terminal output hay evidence.

Staging còn phải kiểm tra public health/docs/OpenAPI, student requests, negative
401/security, toàn bộ Postman collection và log Render không lộ secret. Không lấy
local tests, source hoặc export để tuyên bố những bước đó đã PASS.

## Commands

Chạy trong `D:\DoAnTotNghiep\integration-api`:

```powershell
npm run db:verify
npm run format
npm run format:check
npm run typecheck
npm run build
npm test
npm run test:neon
npm run export:contracts
npm audit --audit-level=low
node --experimental-strip-types scripts/security-scan.ts
npm run dev
```

Flutter phase đã được phê duyệt nhưng chưa bắt đầu: chỉ chuyển tiếp khi cả Render
staging và Postman staging PASS. Không dùng PASS của API local để tuyên bố Flutter
integration hoặc production Moodle PASS.
