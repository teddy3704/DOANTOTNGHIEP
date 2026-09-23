# Demo khi mạng hoặc Render không khả dụng

1. Nói rõ: “Hiện không có kết nối live; phần dưới là bằng chứng runtime đã ghi nhận từ staging.” Không giả API đang hoạt động.
2. Mở APK đã cài và các màn còn tải được nếu có cache/ứng dụng cho phép. Nếu app hiện lỗi mạng, chỉ trạng thái retry; không lén đổi sang fixture.
3. Mở `02_SCREENSHOTS` (15 ảnh Student/Teacher/LMS link) theo thứ tự kịch bản, nêu thời điểm chụp đã kiểm chứng.
4. Mở `08_ARCHITECTURE/FINAL_ARCHITECTURE.md` và `03_DATABASE/01_verify_database_baseline.sql` / `02_council_database_demo.sql` dưới dạng tài liệu, không chạy trên DB khác hoặc local mới.
5. Mở `04_API/openapi.group-39-20.json` hoặc API endpoint matrix làm contract; không nhận HTTP live PASS trong phiên offline.
6. Khi Internet trở lại, thử `/health` một lần, sau đó tiếp tục demo. Không hammer Render Free.

Không chiếu `.env`, Neon/Render credential, cookie hoặc tab SQL connection secret. Không yêu cầu hội đồng nhập tài khoản DLU thật.
