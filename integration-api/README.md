# DLU Student Support — Development Integration API

**This is NOT the production DLU LMS API.**

API chỉ đọc dữ liệu sinh viên mẫu trong mô hình Neon PostgreSQL hiện có. Mục tiêu:
kiểm chứng database-first, contract HTTP, Swagger và Postman. Không sửa Flutter,
không tạo database mới, không chạy migration hoặc seed tự động.

## Phạm vi và kiến trúc

Node.js 24, TypeScript strict, Fastify 5, `pg` và Fastify Swagger/UI. Node built-in
test runner và Prettier phục vụ quality gate; không framework backend thứ hai.

HTTP route → `StudentLearningDataSource` → `PostgresDevelopmentDataSource` → views
trong schema `lms`. Domain DTO không phụ thuộc driver. Production sẽ cần adapter
Moodle Web Services cùng authentication/capabilities được DLU xác nhận, không chỉ
thay connection string. Không có live-to-demo fallback.

Không có upload/submission/grading/teacher/admin/course-write endpoints. Resource
chỉ là metadata; `deepLink` null và `deepLinkStatus` là `TO_VERIFY_DLU`.

## Environment và cài đặt

Active workspace: `D:\DoAnTotNghiep`. Node cần `>=24 <25`. Tệp `.env` local đã được
Git ignore; không ghi đè tệp có sẵn hoặc đưa nội dung lên terminal/chat. Nếu máy
mới, lấy tên setting từ `.env.example`, nhập secret riêng vào `.env`; không copy
secret vào Postman, Swagger, README, screenshot hay source.

`APP_ENV` chỉ nhận `development`/`staging`. `PORT` mặc định 3000.
`DEMO_AUTH_ENABLED=true` bật identity mẫu. Development bind `127.0.0.1`, staging
bind `0.0.0.0`; production config bị từ chối. Không xem staging này là an toàn cho
dữ liệu thật vì header demo không phải authentication.

```powershell
Set-Location 'D:\DoAnTotNghiep\integration-api'
# Kiểm tra dung lượng trước/sau install; nếu C dưới 15 GB, dừng cài đặt.
Get-PSDrive -Name C,D
npm ci --cache 'D:\DLU-LMS\Cache\npm'
Get-PSDrive -Name C,D
```

Không cần Android Studio, Docker hoặc database server local. Không di chuyển
toolchain đang hoạt động. Không cài package/cache lớn lên C nếu có thể dùng D.

`.npmrc` hiện dùng cache trên D cho Windows. Trên Linux/Render, override bằng
`NPM_CONFIG_CACHE=/tmp/npm` trong environment build; không tái sử dụng đường dẫn
Windows. Nguồn deploy đã được người dùng cho phép xuất bản trên nhánh riêng;
Render staging vẫn đang triển khai, chưa có public URL được xác minh.

## Local run, build, test

Chạy từ thư mục `integration-api`:

```powershell
npm run db:verify
npm run dev
```

Terminal thứ hai, cùng thư mục:

```powershell
npm run format:check
npm run typecheck
npm test
npm run build
npm run test:neon
npm run export:contracts
```

`db:verify` và `test:neon` đọc tệp local bằng Node env-file; không echo config.
`npm test` dùng isolated test dependencies, không chứng minh database live.
`test:neon` mới kiểm tra đường đọc Neon thật với dữ liệu mẫu; không import seed.
Flutter đã được phê duyệt cho phase kế tiếp nhưng chưa thực hiện: cần cả Render
staging và Postman staging PASS trước, không dùng local API PASS thay cho hai gate.

Chạy bản build local có nạp cấu hình local:

```powershell
node --env-file=.env dist/src/server.js
```

`npm start` chạy cùng build và nhận environment do hosting/process đã cung cấp;
không tự động đọc tệp `.env`. Không đặt secret trực tiếp vào command line.

## URL và demo identity

- Health: <http://localhost:3000/health>
- Swagger UI: <http://localhost:3000/docs>
- OpenAPI: <http://localhost:3000/openapi.json>
- Student profile: <http://localhost:3000/api/v1/me>

Header cho student endpoints: `X-Demo-Student-Code: SV001`, chỉ khi mã này tồn tại
và đang hoạt động trong database phát triển. Course content dùng `courseId` nhận
từ courses response, không tự đoán ID. Đây là **identity lựa chọn dữ liệu mẫu**,
không login hay bảo mật tài khoản thật. Profile/courses/grades/status bị giới hạn
theo student/ghi danh; không có query parameter chọn user tùy ý.

## Postman

Import collection và environment trong `postman/` sau `npm run export:contracts`:

- `DLU_LMS_Student_Support.postman_collection.json`
- `DLU_LMS_Development.postman_environment.json`

Environment chỉ chứa base URL và mã student mẫu/giá trị không bí mật phục vụ test.
Không thêm Neon connection string. Với Postman Web, localhost có thể yêu cầu
Desktop Agent; không coi export thành công là Web execution PASS. Render chỉ dùng
URL staging đã xác minh; không đưa LMS DLU vào danh sách development servers.

## Render staging — checkpoint 2026-09-17

Chỉ dùng một Node Web Service, nguồn từ nhánh `integration-api-render-staging`
của repository hiện có. Không merge/push main, không force-push; không tạo database
mới hoặc chạy migration/seed trong build/start.

| Setting | Giá trị |
|---|---|
| Root Directory | `integration-api` |
| Node | `NODE_VERSION=24.15.0`, phù hợp `engines` trong `package.json` |
| Build Command | `npm ci --include=dev && npm run build` |
| Start Command | `npm start` |
| Instance | Free nếu có; không tự nâng cấp trả phí |
| Region | Singapore đã chọn trên form; không khẳng định Neon cùng region khi chưa xác minh |
| Health Check Path | `/health` |
| `APP_ENV` | `staging` |
| `DEMO_AUTH_ENABLED` | `true` |
| `NPM_CONFIG_CACHE` | `/tmp/npm` |

Database connection setting chỉ được người dùng nhập vào secret environment field
của Render. Không sao chép giá trị vào tài liệu, source, command line, Postman hoặc
ảnh. Khi cần thao tác này, dừng tại đúng field với
`ACTION_REQUIRED_RENDER_DATABASE_SECRET`; không đọc credential từ pgAdmin.

Nhánh local `integration-api-render-staging` đã tạo. Form Render đã cấu hình các
giá trị trên, chưa nhập database secret và chưa deploy. Publish/deploy **IN_PROGRESS**;
`RENDER_STAGING_GATE=NOT_RUN`, `POSTMAN_STAGING_GATE=NOT_RUN`.
Chỉ đổi thành PASS sau khi kiểm tra public `/health`, `/docs`, `/openapi.json`,
student requests, Postman collection, negative 401/security và log an toàn.

Local recheck cuối ngày 2026-09-17: format/typecheck/build/export contracts PASS,
50 tests PASS (44 tests ban đầu và 6 tests bổ sung cho staging OpenAPI/index scan),
20 real HTTP → Neon checks PASS, dependency audit 0 vulnerabilities. Lượt Postman
local đã có 85/85 assertions PASS; không phải kết quả Postman staging.

## Security và kết quả

TLS PostgreSQL kiểm chứng certificate, pool tối đa 4, transaction read-only,
parameterized SQL. Không log raw request URL/header/body/config/database error.
Response lỗi dùng code/message an toàn. Không lấy credential từ pgAdmin.
Dedicated database read-only role và authentication thật cần review trước phạm
vi production; application read-only transaction không thay thế database grants.

Xem `../docs/API_CONTRACT.md`, `API_SECURITY_MODEL.md`, `TRACEABILITY_MATRIX.md`.
Gate thực thi và blockers ghi trong `../docs/API_TEST_RESULT.md` và
`../docs/INTEGRATION_STATUS.md`. Không có cam kết live Moodle: version, enabled
Web Services, identity, capabilities và deep-link DLU đều cần xác minh.

Tài liệu gốc: [Fastify schema](https://fastify.dev/docs/latest/Reference/Validation-and-Serialization/),
[node-postgres SSL](https://node-postgres.com/features/ssl).
