# Ma trận chỉnh hai báo cáo nhóm theo bản chạy ngày 23/09/2026

Hai DOCX gốc ở `D:\DoAnTotNghiep-group` là tài liệu tham chiếu **chỉ đọc**. Vị trí dùng chỉ số paragraph/table của nội dung Word để tìm nhanh; trang có thể đổi theo Word/LibreOffice. Bản sửa ở `05_REPORT/revised` giữ cấu trúc và tên thành viên, chỉ cập nhật các khẳng định kỹ thuật hiện hành.

| Vị trí / phần | Nội dung cũ | Hệ thống đã xác minh | Cần sửa | Lý do và chứng cứ |
|---|---|---|---|---|
| Báo cáo lần 1, §2 sơ đồ (table 2) | `Spring Boot REST API` | Node.js/TypeScript/Fastify trên Render | Đổi nhãn backend, thêm “staging development data” | `integration-api/package.json`, Render/API test |
| Báo cáo lần 1, §3 công nghệ (table 3 row 2) | Spring Boot + Java + JdbcTemplate, Controller → Service → Repository | Fastify routes → domain/data source → PostgreSQL | Đổi công nghệ/luồng hiện hành | Backend 54 test PASS, source/API spec |
| Báo cáo lần 1, §3 tích hợp (table 3 row 4), §16 checklist paragraph 81 | Android thật + `adb reverse localhost:8080` | Staging Flutter gọi HTTPS Render; emulator đã xác minh | Bỏ 8080/ADB reverse khỏi mô tả demo hiện tại | `docs/FLUTTER_TEST_RESULT.md`, ảnh runtime |
| Báo cáo lần 1, §3 kiểm thử (table 3 row 5) | “Bộ test mock” không có số cuối | Flutter 167/167, analyze PASS; backend 54 | Ghi số gate đã xác minh, nêu staging | Test reports |
| Báo cáo lần 1, §5 phân công (table 5 row 4), §6 paragraphs 27–28 | Tác vụ Spring Boot và kiến trúc Controller → Service → Repository | Vương phụ trách Node/Fastify API/E2E; Tiến schema/Student; Luật data design/Teacher | Sửa tên công nghệ, giữ phân công và review/test | Git/source + trách nhiệm báo cáo |
| Báo cáo lần 1, §14 kế hoạch (table 16 row 1) | Authentication/JWT dễ ngụ ý tài khoản riêng | DLU Auth/Web Services `TO_VERIFY_DLU` | Đổi thành DLU Authentication / Identity Adapter; JWT chỉ nếu cơ chế được duyệt cần | `docs/DLU_LMS_AUTH_DISCOVERY.md` |
| Báo cáo lần 1, §13/§16 minh chứng & checklist | Teacher Assignment/Quiz/Analytics có thể hiểu mọi screen đã đủ; notification “chạy được” | Teacher Home/Courses/Work/Monitoring/Calendar/Profile và read-only API PASS; notification fire NOT_VERIFIED | Mô tả đúng các screen đã chạy và giới hạn notification | `docs/FLUTTER_TEST_RESULT.md`, 15 ảnh |
| Phân tích CSDL, sơ đồ nguồn (table 3) | Spring Boot REST API | Node/Fastify REST API | Đổi trong sơ đồ | `integration-api/` |
| Phân tích CSDL, §kết nối tương lai (paragraph 243, table 100) | Có thể đọc là chỉ đổi seed/mock thành nguồn thật | DLU identity/Web Services/capability chưa xác minh | Nêu target có phê duyệt/adapter; không bảo đảm chỉ thay connection string | `docs/MOODLE_INTEGRATION.md` |
| Cả hai báo cáo, thuật ngữ “Mock Moodle PostgreSQL” | Có thể bị hiểu nhầm CSDL Moodle DLU | 3 schema, 39 bảng, 20 view development/staging synthetic | Ghi rõ “mô hình Moodle-oriented”, không phải DB production DLU | Baseline SQL/catalog, `docs/DATABASE_MODEL_RECONCILIATION.md` |
| Các tài liệu lịch sử 22 bảng/10 view/Teacher fixture, nếu dùng làm hiện trạng | Checkpoint cũ | GROUP_39_20 đang dùng, Teacher API thật | Gắn nhãn lịch sử/rollback, không để ở summary cuối | `docs/REPORT_ALIGNMENT_NOTES.md` phần hiện hành |
| Các lời dẫn API Student-only / APK cũ, nếu đưa vào slide | Chưa cập nhật Teacher/readiness | Student + Teacher GET thật; staging APK hash đã xác minh | Dùng test report/APK cuối; không nhận signed production | `docs/FLUTTER_TEST_RESULT.md` |

**Câu thay thế chuẩn:** “Bản hiện tại sử dụng mô hình PostgreSQL development/staging theo cấu trúc Moodle với dữ liệu mẫu. Flutter gọi API Node.js/TypeScript/Fastify trên Render để đọc thông tin hỗ trợ Student/Teacher. Kiến trúc có lớp Integration/API để sau này kết nối nguồn DLU được Nhà trường cho phép; chưa xác minh xác thực hay Moodle Web Services production. Nộp bài, làm quiz, chấm điểm và quản trị vẫn ở LMS chính thức.”

Không nhận `teacher_*` view nào là một screen/API riêng nếu OpenAPI/runtime không có. 20 view là catalog của mô hình; OpenAPI hiện công bố 16 GET operation kể cả `/health` như matrix đính kèm.
