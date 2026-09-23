# Demo 15 phút — có phần giải thích kỹ thuật

| Thời gian | Mở và thao tác | Điều cần nói | Dự phòng |
|---|---|---|---|
| 0:00–1:00 | LMS DLU và phạm vi | LMS là hệ thống chính thức; Mobile là lớp hỗ trợ. | Ảnh LMS. |
| 1:00–2:30 | Sơ đồ current/target | Staging dùng PostgreSQL mẫu → Fastify/Render → Flutter; đích production cần DLU phê duyệt. | Bản kiến trúc offline. |
| 2:30–4:00 | Baseline SQL và nhóm 35 bảng | 39 bảng/20 view/3 schema; User/role/context, course/enrolment. | SQL + file phân nhóm. |
| 4:00–5:30 | `unified_tasks`, progress, teacher monitoring | Read models; null khác 0, risk theo quy tắc, không AI. | Demo SQL và view guide. |
| 5:30–6:30 | `/health`, Student và Teacher GET, OpenAPI | API GET-only, role/context scope, negative 401/404 đã test. | Spec + test report. |
| 6:30–9:30 | Student Home → Courses → Detail → Assignment → Grades → Progress → Profile → LMS | Hỗ trợ người học, không nộp bài trong Mobile. | Ảnh Student. |
| 9:30–12:30 | Teacher Home → Courses → Monitoring → Công việc → Lịch → Hồ sơ → LMS | Theo dõi lớp; chấm trên LMS. | Ảnh Teacher. |
| 12:30–13:15 | Đổi role | Kiểm tra không giữ dữ liệu/shell Teacher sau khi chọn Student. | Runtime report. |
| 13:15–14:15 | Test/APK evidence | Backend 54, Flutter 167, analyze PASS, APK debug staging và 15 ảnh thật. | Bản manifest/test report. |
| 14:15–15:00 | Giới hạn và kết | DLU Auth/Web Services `TO_VERIFY_DLU`; notification fire `NOT_VERIFIED`. | Closing statement. |

Không trình diễn write vào LMS, không chạy migration và không nhận staging là dữ liệu production. Render Free cần warm trước 5–10 phút; nếu timeout lần đầu, chờ rồi thử lại một lần.
