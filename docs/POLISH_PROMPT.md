# POLISH — làm cho buổi demo 20/11 chắc chắn và thuyết phục hơn

Owner yêu cầu lúc 23:30 ngày 10/11/2026 (bản đầy đủ do owner dán vào phiên native; tóm tắt để phiên sau tiếp tục).

Hiện trạng lúc giao: HEAD `830aa48`; tag cục bộ `bao-ve-2026-11-20` → `41f888b`; GitHub `dlu-lms-group-bao-ve` và tag cùng tên →
snapshot `4d00d98`; test BE 284, FE 329; máy demo 20/11 là chính máy này.

Mục tiêu: không thêm chức năng lớn; trước hội đồng không phải chờ, không lỗi, không nội dung kém chuyên nghiệp, trả lời được câu hỏi.

Quy tắc: áp dụng EXECUTION_RULES và FINAL (RESUME_STATE trước lệnh dài, gate đúng bản code, mỗi mục một commit cục bộ, HANDOFF/TASK_BOARD
ID POLISH-1…8, fail 3 lần → BLOCKED). **Không chạy Set-DemoPasswords**; kiểm tra bằng nút "Chế độ demo"; bắt buộc đăng nhập thật thì
DỪNG hỏi owner. Không DDL, không xóa dữ liệu, không SQL ghi; chỉ ghi schema `app` qua API của app với SV 205, GV 102. Start-Demo chạy
tách rời; file mới trên D; C < 22 GiB thì cảnh báo. GitHub chỉ push ở POLISH-8 theo cách 23:22 (snapshot con của `4d00d98`); không
push HEAD, tag cục bộ, `--tags`, `--all`, `--force`. Không ghi mật khẩu/key/token vào repo, log, ảnh, HANDOFF.

- **POLISH-1** Lớp cố vấn mở ngay: đo trước; `app.portal.cache-ttl` (mặc định 10 phút, Start-Demo 6 giờ, chỉ bộ nhớ); `app.portal.prewarm`
  (mặc định tắt, Start-Demo bật; luồng nền tuần tự ≤ 1 request/giây qua đúng service của endpoint; Portal lỗi thì bỏ qua, chỉ log số
  lượng; `/health` báo `prewarm: N/M`); test (TTL từ cấu hình, mặc định không làm nóng, đúng số lần gọi, Portal lỗi vẫn khởi động, log
  không có MSSV/dữ liệu); đo lại (mục tiêu < 2 s); cập nhật RELEASE_NOTES, DEMO_SCRIPT.
- **POLISH-2** Đổi Sáng/Tối/Theo máy ngay trong app (trang chủ SV và GV; có thể gom với Đăng xuất); 320 dp × 1.3; Semantics; widget
  test; ảnh tối rồi sáng trên emulator.
- **POLISH-3** Nội dung demo chuyên nghiệp: rà dữ liệu app của SV 205/GV 102 (thẻ, kế hoạch, mục tiêu, ghi chú GV, nhắc riêng,
  Pomodoro) tìm nội dung vô nghĩa ("sss", "test", "abc", "aaa", một ký tự); lập danh sách vào HANDOFF; sửa bằng chức năng Sửa của app
  (không xóa, không SQL); không có Sửa thì ghi để owner quyết; đảm bảo kế hoạch tuần, ôn thẻ, thành tích có dữ liệu (6–8 thẻ thật,
  kế hoạch có mục đã xong).
- **POLISH-4** Start-Demo kiểm tra chỉ đọc (pin qua Win32_Battery, chờ khởi động lại qua RebootRequired/PendingFileRenameOperations,
  internet/Portal 5 s) và bảng SẴN SÀNG (DB, Backend /health, Portal UP/DOWN + prewarm N/M, Thiết bị, APK SHA ngắn, Ổ C, Kết luận);
  parse PS5/PS7; cách đọc bảng trong LOCAL_RUNBOOK.
- **POLISH-5** Tập trọn kịch bản trên emulator, bấm giờ, thêm cột "giây"; tổng ≤ 10 phút (vượt thì chuyển bước sang "Nếu hội đồng
  hỏi thêm", giữ các bước khác biệt); bước lỗi thì sửa, gate, đi lại.
- **POLISH-6** Thêm vào cuối DEMO_SCRIPT: an toàn đăng nhập MSSV; vì sao chưa đăng nhập LMS thật; vì sao GitHub chỉ 1 commit; Portal có
  lưu xuống đĩa không; mất mạng thì sao. Thêm dòng "Đăng nhập" vào COMPARISON_FACTS.
- **POLISH-7** Video: quay lại gv-1/gv-2 nếu có cảnh chờ lâu, hoặc đoạn có màn thay đổi do POLISH-2/3; bản cũ giữ hậu tố `-r1`.
- **POLISH-8** Gate (Test-Backend -Package, Test-Flutter -BuildApk, Measure-Api); APK/JAR mới vào final (bản cũ `-r1`), SHA256SUMS,
  RELEASE_NOTES; tag cục bộ `bao-ve-2026-11-20-r2`; GitHub: `git commit-tree 'HEAD^{tree}' -p 4d00d98… -m 'DLU LMS Group: defense
  snapshot r2'`, rev-list count = 2, quét cây, push fast-forward nhánh và tag `bao-ve-2026-11-20-r2`, xác nhận ls-remote; tổng kết HANDOFF.
- Tùy chọn: `Start-Demo -PhysicalDevice` nếu owner cắm điện thoại; không thì NOT_RUN.
- Không làm (ghi "Hướng phát triển"): APK release; offline cho GV; tìm kiếm unaccent + chỉ mục; "điểm mới nhận" N14 và lịch sử N9;
  lưu Portal xuống đĩa.
- Việc cho owner: 1 Set-DemoPasswords; 2 Rotate-AppRolePassword; 3 đóng Claude, Start-Demo, đăng nhập thử 2312005 và teacher02,
  Stop-Demo; 4 giữ C ≥ 22 GiB; 5 tạm dừng Windows Update 2 tuần.
