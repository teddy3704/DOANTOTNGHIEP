# Release notes — bản bảo vệ 20/11/2026

Nhánh `codex/group-stack-takeover`, git cục bộ. Mã nguồn của bản cuối (r2, sau POLISH): commit `229ed71` (sau đó chỉ đổi tài liệu);
GitHub nhánh `dlu-lms-group-bao-ve` là ảnh chụp cùng cây (tag `bao-ve-2026-11-20-r2`).
Dữ liệu: bản sao CSDL Moodle `lms_mobile_group_demo` (đã dời ngày theo 20/11/2026) và API Portal Online DLU Proxy (**dữ liệu mô
phỏng**). Ứng dụng không ghi vào Moodle; chỉ ghi dữ liệu riêng của ứng dụng (schema `app`).

## Bản build

| File (`D:\DLU-LMS\Artifacts\final\`) | Kích thước | SHA-256 |
| --- | ---: | --- |
| `dlu-lms-group-final-debug.apk` | 211.478.171 B | `910CEF7591C547C585770592447E34357231E41E46265A7F0FCF397728477131` |
| `lms_mobile_backend-final.jar` | 27.626.465 B | `F1038DC02FB103D470BF0BC88FEF56B29BB77C1C8525FF0120D42E6F68D2C3F7` |

Danh sách SHA trong `SHA256SUMS.txt` cùng thư mục. Bản trước (từ `08e41e6`) giữ lại với hậu tố `-r1` (APK `E285526E…`, JAR `3169A504…`,
`SHA256SUMS-r1.txt`). APK là bản **debug** (đăng nhập thử nghiệm local chỉ hoạt động ở bản này).

## Kiểm thử (trên đúng mã nguồn bản cuối)

- Backend: `tools\Test-Backend.ps1 -Package` exit 0 — **290 test, 0 lỗi, 1 bỏ qua có chủ đích** (`SchemaVerificationTest`
  `@Disabled`, cần CSDL thật).
- Flutter: `tools\Test-Flutter.ps1 -BuildApk` exit 0 — **333 test**, `flutter analyze` sạch; gồm cỡ chữ 1.3, màn 320/360/390 dp,
  chế độ sáng/tối, test quét mã nguồn cấm màu xám/đen/nền sáng viết cứng.
- Hiệu năng (`tools\Measure-Api.ps1`, 12 endpoint × 200 lần, DB demo): 10/11 p95 1,3–21,0 ms (`perf-20261110-214039.csv`); 11/11
  khi emulator cùng chạy p95 2,1–75,5 ms (`perf-20261111-025846.csv`); 0 lỗi. Lớp cố vấn: chi tiết SV ≈ 0,25 s sau làm nóng.
- Chạy thật trên emulator (DB demo, Portal UP): đi hết `DEMO_SCRIPT.md` hai lần (F3; POLISH-5 bấm giờ ≈ 7 phút 35 giây); ảnh
  `final\screens\` (demo-*, rehearse-*, f2-*, login-*, polish*), 5 video `final\video\` (sv-3, gv-2 quay lại; bản cũ `-r1`).

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
- Cache Portal chỉ trong bộ nhớ backend: 10 phút mặc định (giữ nguyên khi triển khai thật); `Start-Demo.ps1` đặt 6 giờ và làm nóng
  sẵn lớp cố vấn của GV demo (POLISH-1) nên chi tiết SV mở ngay (≈ 0,25 s). Không làm nóng thì lần mở đầu có thể chờ lâu khi Portal
  chậm (đo 10/11: > 20 s; app chờ tối đa 60 s).
- N7: giờ nhắc hằng ngày lưu trên máy; N14 không có dòng "điểm mới nhận"; N17 "không còn khóa Đỏ" thay "hết Đỏ" (không có lịch sử N9).
- Chưa kiểm thử trên điện thoại thật (nhánh `-PhysicalDevice` NOT_RUN); APK debug, chưa ký bản phát hành.
- Owner cần tự chạy `Start-Demo.ps1` sau khi đóng Claude (bài thử độc lập O1) và giữ ổ C ≥ 22 GiB.

## Hướng phát triển (chưa làm, có lý do)

- **APK bản phát hành (release):** cờ `kDebugMode` đang khóa các endpoint thử nghiệm — đó là một tính chất bảo mật; bản release còn
  phải mở HTTP tới loopback, rủi ro khi sát ngày bảo vệ. Làm sau khi có máy chủ HTTPS và đăng nhập LMS thật.
- **Xem khi mất mạng cho giảng viên** (N11 hiện chỉ có cho sinh viên).
- **Tìm kiếm bằng `unaccent` + chỉ mục** trong PostgreSQL thay cho chuẩn hóa ở tầng ứng dụng (cần DDL, quyền owner).
- **Dòng "điểm mới nhận" (N14) và lịch sử mức N9:** dữ liệu mẫu thiếu mốc thời gian chấm điểm và không lưu lịch sử mức theo dõi.
- **Lưu dữ liệu Portal xuống đĩa:** không làm — trái với nguyên tắc bảo vệ quyền riêng tư đã trình bày (chỉ cache trong bộ nhớ).
