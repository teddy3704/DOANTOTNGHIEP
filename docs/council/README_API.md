# API Student và Teacher ở staging

Luồng đã chạy: `Flutter → HTTPS → Render staging → Node.js/TypeScript/Fastify → PostgreSQL`. `openapi.group-39-20.json` và Postman collection là contract của development/staging, không phải API DLU. `GET /health`, `/docs` và `/openapi.json` hỗ trợ kiểm tra/trình diễn.

Student API và Teacher API đều **chỉ đọc** dữ liệu mẫu, lọc theo hồ sơ và phạm vi học phần tại backend. Header identity mẫu không phải xác thực đại học; 401/400/404 negative tests đã PASS. Không có endpoint Mobile upload, nộp bài, làm quiz, chấm điểm hoặc sửa học phần. Nghiệp vụ chính thức vẫn ở LMS DLU; production integration cần DLU phê duyệt identity/Web Services.

Không import Postman environment chứa secret. Bản OpenAPI và collection trong bộ cuối phải được scan trước khi copy; không đưa DB URL, cookie hoặc token vào file export.
