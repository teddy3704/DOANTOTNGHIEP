# Ngày báo cáo 13/11 — chạy trên dữ liệu thật (`lms_mobile_group_real`)

Không có dữ liệu cá nhân trong tài liệu này. Dữ liệu, bảng điểm tự nhập, ảnh và video nằm ở `D:\DLU-LMS\RealData\`
(ngoài repo). Mật khẩu do người dùng tự gõ; không ghi ở đâu.

## 1. Sáng 13/11 — khởi động (Windows PowerShell mở từ Start, bàn phím ENG)

1. Khởi động lại máy (Windows đang chờ cập nhật), tạm dừng Windows Update 1 tuần. Cắm sạc.
2. Mở PowerShell, chạy:
   ```
   cd D:\DLU-LMS-Group
   .\tools\Start-Demo.ps1
   ```
   Mặc định `-Target real`. Script mở cửa sổ **DLU Demo - PostgreSQL** và **DLU Demo - Backend**, bật emulator, cài
   APK real nếu máy đang có bản khác, mở app. Backend tự làm nóng cache cho các tài khoản đăng nhập (khoảng
   1–2 phút); chạy lại `Start-Demo.ps1` sau đó, bảng SẴN SÀNG phải ghi `làm nóng 55/0 done` (số đầu = lời gọi OK).
3. **Không đóng** hai cửa sổ PostgreSQL và Backend trong suốt buổi. Đóng cửa sổ PostgreSQL làm CSDL dừng ngay
   (Windows gửi Ctrl+C, đã xảy ra 12/11 21:59). Thu nhỏ chúng xuống thanh tác vụ.

APK real đang dùng: `D:\DLU-LMS\Artifacts\real\dlu-lms-group-real-debug.apk`, SHA-256
`80e646fc410f189e34e6184526f61dcf9ffe91a85b76392c1a0eea22b6fe4ad0` (commit 39c7a4e; cũng ghi trong `SHA256.txt`).

Kết quả đúng ở cuối Start-Demo: `DB lms_mobile_group_real`, `Backend /health UP, database CONNECTED`,
`Portal TẮT, làm nóng N/0 done` (hoặc `running` trong 1–2 phút đầu), `APK … (= bản real)`, `Kết luận SẴN SÀNG`.

## 2. Kiểm tra 5 phút trước giờ

| Kiểm | Cách | Đúng khi |
| --- | --- | --- |
| Cache đã nóng | chạy lại `.\tools\Start-Demo.ps1` | dòng Portal ghi `làm nóng N/0 done` |
| Đăng nhập SV | trên emulator gõ MSSV + mật khẩu, **trong vòng 1 giờ trước khi trình bày** (phiên hết hạn sau 1 giờ) | Trang chủ "Xin chào, <MSSV>", thẻ "Học vụ · GPA" |
| Không có Chế độ demo | màn đăng nhập | chỉ có nút Đăng nhập (dữ liệu thật luôn cần mật khẩu) |
| Học vụ | bấm thẻ Học vụ · GPA | dòng "Bảng điểm: sinh viên nhập từ Portal đào tạo · đến HK2 2025-2026" |
| Đăng nhập GV | đăng xuất, gõ tài khoản giảng viên | Trang chủ ghi "Được tổng hợp từ các khóa học · Học kỳ hiện tại"; danh sách khóa có "Bắt đầu MM/YYYY", sinh viên hiện "SV nn" |
| Ẩn danh | mở một khóa › Sinh viên cần theo dõi | không có MSSV nào, nút xuất CSV có khóa |

## 3. Cứu hộ

| Lỗi | Xử lý |
| --- | --- |
| App báo không kết nối / Backend không trả lời | `.\tools\Start-Demo.ps1` lần nữa (dùng lại phần đang chạy, mở lại phần đã tắt). |
| CSDL dừng (backend log "Connection refused") | như trên; script mở lại cửa sổ PostgreSQL. |
| Màn đầu tiên chậm (2–6 s) | cache chưa nóng: đợi 1–2 phút sau khi backend UP, hoặc mở lại màn đó lần nữa. |
| Màn báo "Không thể tải dữ liệu" sau thời gian dài | phiên đã hết hạn (1 giờ): đăng xuất, đăng nhập lại. |
| Emulator treo | đóng cửa sổ Emulator, `.\tools\Start-Demo.ps1`. |
| Máy hỏng / dữ liệu thật lỗi | `.\tools\Stop-Demo.ps1` rồi `.\tools\Start-Demo.ps1 -Target demo` (dữ liệu minh họa, APK final cũ chạy được; nói rõ với hội đồng đây là bản dự phòng). |
| Hết mọi cách | trình bày bằng ảnh trên slide (ảnh trong `D:\DLU-LMS\RealData\screens\slides\`). Không có video dự phòng. |

Tắt sau buổi: `.\tools\Stop-Demo.ps1`.

## 4. Những gì dữ liệu thật không có (và app hiện gì)

- Tiến độ CTĐT, quyết định học vụ: "Chưa có dữ liệu Portal cho MSSV này" (Portal API mô phỏng bị tắt trên real).
- GPA dự kiến từ LMS: các khóa học kỳ này chưa có điểm trên LMS nên không có; Mô phỏng GPA vẫn cho chọn điểm từng môn.
- Chi tiết từng buổi điểm danh, lượt xem tài liệu: không có; chuyên cần = điểm mục điểm danh, "hoạt động" = nộp bài
  hoặc làm bài kiểm tra.
- Chi tiết: docs/REAL_DATA_IMPORT.md.
