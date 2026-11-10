# Release notes — bản bảo vệ 20/11/2026

Nhánh `codex/group-stack-takeover`, git cục bộ (không remote). Mã nguồn của bản cuối: commit `08e41e6` (sau đó chỉ đổi tài liệu).
Dữ liệu: bản sao CSDL Moodle `lms_mobile_group_demo` (đã dời ngày theo 20/11/2026) và API Portal Online DLU Proxy (**dữ liệu mô
phỏng**). Ứng dụng không ghi vào Moodle; chỉ ghi dữ liệu riêng của ứng dụng (schema `app`).

## Bản build

| File (`D:\DLU-LMS\Artifacts\final\`) | Kích thước | SHA-256 |
| --- | ---: | --- |
| `dlu-lms-group-final-debug.apk` | 211.479.377 B | `E285526E2BDC1E5AB2CC0E6382C1DEBE5090B547666E8B7D0793A7CD4F048917` |
| `lms_mobile_backend-final.jar` | 27.621.430 B | `3169A50465347CABE25686B650B2A569B856BC99B0F3C352FDAB10AAF8C9F046` |

Danh sách SHA trong `SHA256SUMS.txt` cùng thư mục. APK là bản **debug** (đăng nhập thử nghiệm local chỉ hoạt động ở bản này).

## Kiểm thử (trên đúng mã nguồn bản cuối)

- Backend: `tools\Test-Backend.ps1 -Package` exit 0 — **284 test, 0 lỗi, 1 bỏ qua có chủ đích** (`SchemaVerificationTest`
  `@Disabled`, cần CSDL thật).
- Flutter: `tools\Test-Flutter.ps1 -BuildApk` exit 0 — **329 test**, `flutter analyze` sạch; gồm cỡ chữ 1.3, màn 320/360/390 dp,
  chế độ sáng/tối, test quét mã nguồn cấm màu xám/đen/nền sáng viết cứng.
- Hiệu năng (`tools\Measure-Api.ps1`, 12 endpoint × 200 lần, DB demo, 10/11/2026): p95 1,3–21,0 ms, 0 lỗi
  (`perf-20261110-214039.csv`).
- Chạy thật trên emulator (DB demo, Portal UP): đi hết `DEMO_SCRIPT.md`; ảnh `final\screens\` (demo-01..17, f2-*, login-*), 5 video
  `final\video\`.

## Chức năng theo mã

- **Nền tảng:** đăng nhập MSSV/tên tài khoản + mật khẩu (LOGIN), JWT + kiểm tra danh tính theo đường dẫn, role DB tối thiểu quyền.
- **V2 sinh viên:** N1 mô phỏng điểm · N2 gợi ý ôn lại · N3 vị trí trong lớp ẩn danh · N5 ôn tập SM-2 · N6 kế hoạch tuần · N7 nhắc
  học trên điện thoại · N9 tình trạng học tập · N10 học tập trung · N11 xem khi mất mạng · N12 lịch tháng/tuần + .ics · N13 tìm kiếm ·
  N14 tuần của bạn · N17 thành tích · N18 chế độ tối, chữ lớn, giới thiệu.
- **V2 giảng viên:** N4 dự báo qua môn · N8 nhắc riêng + xuất CSV · N13 tìm kiếm · N15 bản đồ nhiệt · N16 phân tích bài kiểm tra.
- **V3 Portal:** P1 bảng điểm/GPA · P2 tiến độ CTĐT · P3 mô phỏng GPA (cầu nối N1) · P4 rèn luyện · P5 quyết định học vụ ·
  P6 lớp cố vấn (+ tín hiệu N9) · P7 nguồn dữ liệu · P8 cache/hoàn thiện.
- **Vận hành:** O1 `Start-Demo.ps1` / `Stop-Demo.ps1` (kể cả `-PhysicalDevice`), E2 đo hiệu năng, `Rotate-AppRolePassword.ps1`,
  `Set-DemoPasswords.ps1`.

Chi tiết: `FEATURES_V2.md`, `FEATURES_V3.md`, `COMPARISON_FACTS.md`; hướng dẫn: `USER_GUIDE.md`; kịch bản: `DEMO_SCRIPT.md`.

## Chạy demo

1. Một lần (owner): `.\tools\Set-DemoPasswords.ps1` (mật khẩu đăng nhập demo cho 2312005, 2212001, teacher02) và
   `.\tools\Rotate-AppRolePassword.ps1` (mật khẩu role CSDL).
2. `.\tools\Start-Demo.ps1` (emulator) hoặc `.\tools\Start-Demo.ps1 -PhysicalDevice` (điện thoại USB) → đọc **Tóm tắt demo**.
3. Trên app: đăng nhập `2312005` (sinh viên) rồi `teacher02` (giảng viên), theo `DEMO_SCRIPT.md`.
4. `.\tools\Stop-Demo.ps1`.

Chi tiết và sự cố thường gặp: `LOCAL_RUNBOOK.md` mục "Ngày bảo vệ".

## Giới hạn đã biết

- Dữ liệu Portal là mô phỏng; ngưỡng xếp loại theo Thông tư 08/2021 cần đối chiếu quy chế của Trường.
- Đăng nhập dùng tài khoản demo cục bộ (BCrypt). `MoodleTokenProvider` đã viết nhưng **tắt**, chỉ kiểm thử bằng mock; bật thật cần
  văn bản cho phép của Trường. MSSV thật của thành viên nhóm không có trong dữ liệu mẫu.
- DB demo dời ngày theo 20/11: trước ngày đó một số mốc hiện "sau hôm nay N ngày" (hiển thị trung thực mốc tương lai).
- Lần đầu mở chi tiết SV lớp cố vấn có thể chờ 20–30 s (server tải lịch sử nhiều học kỳ từ Portal; app chờ tối đa 60 s).
- N7: giờ nhắc hằng ngày lưu trên máy; N14 không có dòng "điểm mới nhận"; N17 "không còn khóa Đỏ" thay "hết Đỏ" (không có lịch sử N9).
- Chưa kiểm thử trên điện thoại thật (nhánh `-PhysicalDevice` NOT_RUN); APK debug, chưa ký bản phát hành.
- Owner cần tự chạy `Start-Demo.ps1` sau khi đóng Claude (bài thử độc lập O1) và giữ ổ C ≥ 22 GiB.
