# Bộ bảo vệ ĐLU LMS Support — 23/09/2026

Đây là bản chốt nội dung để trình diễn **ứng dụng hỗ trợ học tập**, không phải một LMS mới. Nguồn hiện chạy là PostgreSQL development/staging theo mô hình Moodle của nhóm; không phải dữ liệu hay CSDL production của Đại học Đà Lạt. Bản Mobile đọc Student/Teacher qua API Render và chuyển nghiệp vụ chính thức về [DLU LMS](https://lms.dlu.edu.vn/).

| Gate | Kết quả đã xác minh |
|---|---|
| Database First | 3 schema, 39 bảng vật lý (35 `lms`, 4 `app`), 20 view `derived`, 39 PK, 38 FK, 548 cột |
| Backend | Node.js, TypeScript, Fastify, PostgreSQL; Render staging; 54 test PASS |
| Student/Teacher | API GET thật trên staging, runtime trên emulator PASS; đổi role/context PASS |
| Flutter | `analyze` PASS, 167/167 test PASS, payload Render thật PASS |
| Android | APK debug staging đã cài và chụp 15 ảnh thật |
| Tích hợp DLU production | Auth và Web Services `TO_VERIFY_DLU` |
| Thông báo Android phát thực tế | `NOT_VERIFIED`: dữ liệu staging không có hạn nộp tương lai phù hợp |

Tài liệu dùng theo thứ tự: `ARCHITECTURE_CHEAT_SHEET.md` → `DATABASE_FIRST_DEFENSE.md` → `DATABASE_35_TABLES_BY_DOMAIN.md` / `DERIVED_VIEWS_EXPLAINED.md` → `COUNCIL_QA_MASTER.md` → `TIEN_DEFENSE_SCRIPT.md` → `LIMITATIONS_AND_FUTURE_WORK.md`.

Không đưa credential, URL kết nối database hoặc dữ liệu học vụ thật vào bộ này. Các con số lịch sử trong tài liệu cũ phải đọc cùng `docs/REPORT_ALIGNMENT_NOTES.md` và ma trận sửa báo cáo cuối.
