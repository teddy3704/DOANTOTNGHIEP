# Demo 5 phút — kịch bản tối thiểu

| Thời gian | Mở và thao tác | Lời nói ngắn | Khi mạng chậm |
|---|---|---|---|
| 0:00–0:30 | LMS chính thức | “Mobile hỗ trợ, LMS DLU vẫn ghi nhận nghiệp vụ chính thức.” | Dùng ảnh LMS đã chuẩn bị; không nói đang online. |
| 0:30–1:15 | Sơ đồ kiến trúc và baseline SQL | “Database First: 3 schema, 39 bảng, 20 view; đây là staging dữ liệu mẫu.” | Mở kiến trúc/SQL offline. |
| 1:15–1:45 | Render `/health`, một Student và một Teacher GET | “Fastify API chỉ đọc, giới hạn theo vai trò/học phần.” | OpenAPI + ảnh kết quả đã lưu. |
| 1:45–3:15 | Student Home → Course → Assignment → Progress; mở “Nộp bài trên LMS” | “Việc học được tóm tắt trên Mobile, nộp bài vẫn ở LMS.” | Ảnh Student runtime, không giả thao tác live. |
| 3:15–4:25 | Teacher Home → Công việc → Student Monitoring; “Chấm bài trên LMS” | “Teacher API thật, theo dõi chứ không chấm trong app.” | Ảnh Teacher runtime. |
| 4:25–5:00 | Kiến trúc production/limitations | “Auth/Web Services DLU cần xác minh; notification fire chưa có bằng chứng.” | Đọc cheat sheet. |
