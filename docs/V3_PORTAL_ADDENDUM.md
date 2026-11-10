# V3 — PHỤ LỤC (09/11/2026, 20:10): dữ liệu Portal là dữ liệu MÔ PHỎNG, key dùng chung trên trang docs

Phụ lục này ghi đè các điểm tương ứng trong `docs/V3_PORTAL_PROMPT.md`. Phần không nhắc tới ở đây giữ nguyên.

**Xác nhận qua Zalo ngày 09/11/2026 từ phía phụ trách API (Đức Nguyễn):**
- API Portal Online DLU Proxy trả **dữ liệu mô phỏng**, có cấu trúc giống Portal đào tạo thật. Đây không phải dữ liệu thật của sinh viên.
- Dữ liệu tĩnh, không có dữ liệu động.
- **Không có key riêng.** Key cần dùng chính là key dev hiển thị trên trang docs.

## Thay đổi

1. **Key**
   - Phiên native được phép tự lấy key dev từ trang docs (ví dụ request của một endpoint bất kỳ) và ghi vào `.local\backend.json`. File này đã nằm trong `.gitignore`; kiểm tra lại trước khi ghi.
   - **Không cần dừng chờ owner chạy `Set-PortalConfig.ps1`.** Script vẫn viết để dùng về sau.
   - Vẫn giữ quy tắc: key không được vào repo, APK, log, HANDOFF hay ảnh chụp.
2. **Chạy thật ngay sau P0.** Dùng API thật với dữ liệu mô phỏng: gọi thử từng endpoint, chỉ ghi vào HANDOFF số bản ghi, danh sách trường và thời gian phản hồi. Mock vẫn dùng cho test tự động.
3. **Ánh xạ demo (sinh viên)**
   - Chọn một sinh viên mô phỏng có bảng điểm qua nhiều học kỳ. Gợi ý từ ví dụ trên docs: MSSV `2347A008`, CTĐT `CQ23CT-PM`, lớp `ITK47A`. Kiểm tra trước khi chọn; nếu dữ liệu mỏng thì chọn sinh viên khác trong lớp.
   - Ánh xạ này gán cho sinh viên demo 205 trong cấu hình server.
   - Vẫn **không cho người dùng tự nhập MSSV**. Lý do: khi nối Portal thật, việc cho nhập MSSV là lỗ hổng xem trộm bảng điểm.
4. **Cho cầu nối có ý nghĩa khi demo (sinh viên)**
   - Ánh xạ 2–3 khóa Moodle demo của sinh viên 205 (Software Testing, Mobile Application Development, Hỗ trợ học tập số) sang các **MaHP có tên tương ứng trong CTĐT của sinh viên mô phỏng mà sinh viên đó chưa có điểm**.
   - Nhờ vậy P2 hiện "Đang học trên LMS", và P3 dùng được dự báo N1 để tính GPA dự kiến.
   - Ghi bảng ánh xạ vào `FEATURES_V3.md` và hiển thị trên màn P7 với nhãn "ánh xạ demo".
5. **Lớp cố vấn (P6)**
   - Gán cho giảng viên 102 một lớp có dữ liệu điểm và rèn luyện, ví dụ `ITK47A` hoặc `ITK47C`; dò để tìm năm học và học kỳ có dữ liệu.
   - Để minh họa cầu nối cho giảng viên: ánh xạ vài sinh viên Moodle trong khóa của giảng viên 102 sang StudentID của lớp đó (cấu hình server, nhãn "ánh xạ demo").
6. **Dữ liệu tĩnh**
   - Không suy "học kỳ hiện tại" từ đồng hồ máy. Dò năm học và học kỳ **mới nhất có dữ liệu** (từ bảng điểm của sinh viên và danh sách học kỳ của lớp).
   - UI ghi rõ "Dữ liệu Portal đến HKxx năm yyyy-yyyy".
7. **Quyền riêng tư:** giữ nguyên toàn bộ thiết kế ở mục 2 của V3 (tối thiểu hóa trường, không tích hợp miễn giảm học phí, không lưu vào CSDL, cache có TTL, server lọc dữ liệu theo người gọi, chế độ ẩn danh), coi như **thiết kế sẵn cho Portal thật** (privacy by design). Riêng hai điểm được nới:
   - Chế độ ẩn danh trên màn giảng viên được để **TẮT mặc định trong profile demo**, vì dữ liệu là mô phỏng. Vẫn giữ công tắc trên màn hình và test.
   - Khi kiểm thử được in số liệu tổng hợp. Vẫn không dump body vào HANDOFF.
8. **Cách diễn đạt trong docs, báo cáo và màn P7:** "Dữ liệu đào tạo lấy từ API Portal Online DLU Proxy do thầy Nguyễn Trọng Hiếu cung cấp. Đây là dữ liệu mô phỏng có cấu trúc giống Portal đào tạo của Trường; ứng dụng đã thiết kế sẵn các biện pháp bảo vệ để nối với dữ liệu thật."
