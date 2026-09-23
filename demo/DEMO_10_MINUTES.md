# Demo 10 phút — mặc định

| Thời gian | Mở và thao tác | Thông điệp | Dự phòng |
|---|---|---|---|
| 0:00–0:45 | DLU LMS | Hệ thống nguồn; Mobile không thay LMS. | Ảnh/URL ghi sẵn. |
| 0:45–2:15 | Sơ đồ + `01_verify_database_baseline.sql` | 3 schema; 35 `lms` + 4 `app`; 20 view; synthetic staging. | SQL/README offline. |
| 2:15–3:15 | `02_council_database_demo.sql` | Enrolment khác role; `unified_tasks`, teacher monitoring là read models. | SQL và ảnh kết quả đã lưu. |
| 3:15–4:00 | `/health`, OpenAPI Student/Teacher | Fastify/Render GET-only; scope server-side. | Bản spec và matrix offline. |
| 4:00–6:20 | Student Home → Courses → Detail → Assignment → Progress → Grades → Profile → LMS link | Hỗ trợ tra cứu, bài nộp chính thức ở LMS. | 15 ảnh runtime, chọn đúng ảnh Student. |
| 6:20–8:35 | Teacher Home → Courses → Monitoring → Công việc → Calendar → Profile → LMS link | Teacher API thật, không ghi điểm. | Ảnh Teacher runtime. |
| 8:35–9:15 | Đổi Teacher → Student | Identity, navigation, dữ liệu đổi; không rò scope. | Test report + ảnh tương ứng. |
| 9:15–10:00 | Cheat sheet/limitations | DLU auth/Web Services `TO_VERIFY_DLU`; notification `NOT_VERIFIED`. | Đọc lời kết 30 giây. |

Warm `/health` 5–10 phút trước buổi; timeout đầu thì chờ và retry một lần. Không đưa credential hoặc Postman secret lên màn chiếu.
