# FINAL — Hoàn thiện cho buổi bảo vệ 20/11/2026

Phiên cloud soạn ngày 10/11/2026. Phiên native là writer duy nhất.

**Trạng thái hiện tại:** đã xong và đã qua gate N1–N18, O1, E2, P0–P8. Backend 273 test, Flutter 300 test, git cục bộ.

**Không thêm chức năng lớn mới.** Mục tiêu từ đây là bốn việc: ổn định, bằng chứng, tài liệu, video.

Mọi quy tắc cũ (V2, V3, phụ lục) giữ nguyên:
- Gate sau mỗi thay đổi code. Mỗi mục xong thì commit cục bộ một lần; không push, không remote.
- Cập nhật HANDOFF và TASK_BOARD (ID FINAL-F1 … F7) ngay khi xong từng mục. Nếu hết credit giữa chừng, phiên sau đọc phần cuối HANDOFF là làm tiếp được.
- Đọc tối thiểu để tiết kiệm credit: TASK_BOARD, mục "TỔNG KẾT PHIÊN 10/11/2026" cuối HANDOFF, rồi file này.

**Áp dụng thêm toàn bộ quy tắc trong `docs/EXECUTION_RULES.md`:** checkpoint `RESUME_STATE.md`, gate đúng bản code, storage, git, xử lý khi hết usage.
- Snapshot ở mục 1 của file đó đã **cũ**. Thực tế: HEAD là `788aac2`; N11–N18 đã DONE và đã chạy trên emulator.
- **Không làm lại** các chức năng đó. Mục 5 của file đó dùng làm danh sách kiểm tra lỗi, đã gộp vào F2 bên dưới.

Thứ tự: F0 → F1 → F2 → F3 → F4 → F5 → F6 → F7. Một mục fail 3 lần thì ghi BLOCKED và làm mục tiếp theo.

## F0. Checkpoint bền vững (làm ngay đầu phiên)

Tạo `docs/RESUME_STATE.md` theo mục 2 của `EXECUTION_RULES.md`, dưới 120 dòng, có `NEXT_ACTION` và `DO_NOT_REPEAT`.
- Cập nhật sau mỗi mục và **trước** mỗi lệnh dài (gate, build, emulator, quay video).
- Thêm vào `CLAUDE.md` một dòng chỉ dẫn: đọc `docs/RESUME_STATE.md` khi bắt đầu hoặc tiếp tục phiên.

## F1. Sơ đồ khớp với code hiện tại

Cập nhật `docs/diagrams/` theo code **thật**, mỗi file vẫn chỉ một ý:

| File | Việc cần làm |
| --- | --- |
| `02-components.mmd` | Thêm controller và service của N6–N18 |
| `08-usecase-student.mmd` | Thêm N6, N7, N10–N14, N17, N18. Giữ cách nhóm use case theo nguồn dữ liệu (LMS / dữ liệu riêng của ứng dụng / Portal) |
| `09-usecase-teacher.mmd` | Thêm N8, N13, N15, N16 |
| `10-activity-study-plan.mmd` | Viết lại theo `StudyPlanner` thật: thời lượng ước lượng, tách assign, quá tải, giữ mục done, sửa lỗi trùng thẻ ôn |
| `06-dataflow-bridge.mmd` | Sửa nếu luồng có thay đổi |

Không cần render: phiên cloud sẽ render. Ghi danh sách file đã đổi vào HANDOFF.

## F2. Giảm rủi ro ngày demo

1. **Quyền thông báo trên Android 13+**
   - Xin quyền `POST_NOTIFICATIONS` lúc chạy, khi người dùng bật nhắc hoặc bấm "Gửi thử". Không dựa vào việc cài bằng `-g`.
   - Nếu người dùng từ chối, hiện hướng dẫn mở cài đặt.
   - Có test, và có ảnh hộp thoại xin quyền trên emulator.
2. **Chế độ tối**
   - Tìm màu viết cứng ở các màn cũ (`Color(0x`, `Colors.grey`, `Colors.black`, mã hex) và đổi sang màu của theme.
   - Chụp ảnh chế độ tối cho 5 màn chính: trang chủ sinh viên, chi tiết khóa, học vụ Portal, trang chủ giảng viên, lớp cố vấn.
3. **Demo trên điện thoại thật qua USB**
   - Thêm tham số `-PhysicalDevice` cho `Start-Demo.ps1`: không bật emulator; chờ `adb devices` có máy thật; chạy `adb reverse tcp:8081 tcp:8081`; nếu máy chưa có APK cuối thì cài.
   - Backend vẫn chỉ nghe `127.0.0.1`.
   - Ghi cách dùng vào `LOCAL_RUNBOOK.md`.
4. **Lỗi đã biết và danh sách kiểm tra** (mục 5 của `EXECUTION_RULES.md`). Kiểm từng mục, có test; mục nào chưa đạt thì ghi PARTIAL, không đổi tiêu chí:
   - "Hoạt động gần nhất: -6 ngày trước" xuất hiện vì DB demo đã dời ngày nên có mốc thời gian ở tương lai. Hiển thị trung thực, **không** dùng abs(). Test cho quá khứ, hiện tại và tương lai.
   - Nhãn trục biểu đồ bị xuống dòng ở các màn còn lại. Hộp chọn giờ không còn chữ tiếng Anh.
   - N11: cache gắn đúng user, vai trò và môi trường; đổi tài khoản nhanh khi request cũ chưa về thì không trộn dữ liệu. Không dùng cache để che lỗi 401/403. Khởi động lại app vẫn đúng.
   - N12: Part B yêu cầu cả lịch **tuần** lẫn lịch tháng. Thiếu lịch tuần thì làm, hoặc ghi PARTIAL. Thử tháng rỗng, biên tháng, múi giờ.
   - N13: debounce và bỏ phản hồi cũ; xử lý `đ`/`Đ` và dấu tổ hợp (`dao` tìm ra `Đào`); bấm vào kết quả mở đúng màn.
   - N14 và N17: phân biệt "không có dữ liệu" với "số 0"; không cộng trùng sự kiện; biên tuần.
   - N18: chạy ở chiều rộng 320 và 390, cỡ chữ 1.3, cả sáng lẫn tối. Không nút nào là placeholder.
   - Docs: phần header hiện trạng của HANDOFF và trạng thái trong `COMPARISON_FACTS.md` đã cũ, cập nhật lại; giữ nguyên lịch sử có ngày.
5. **Kiểm tra trước trong `Start-Demo.ps1`**
   - Ổ C dưới 22 GiB thì cảnh báo; dưới 15 GiB thì dừng.
   - Portal DOWN thì cảnh báo nhưng vẫn chạy tiếp, vì phần LMS vẫn hoạt động.
   - In ra tóm tắt: đang dùng DB nào, Portal UP/DOWN, thiết bị nào.

## F3. Hồi quy toàn bộ và bản cuối

1. Chạy `Test-Backend.ps1 -Package`, `Test-Flutter.ps1 -BuildApk` và `Measure-Api.ps1`.
2. Trên emulator, với DB demo và Portal bật: đi hết kịch bản `DEMO_SCRIPT.md` (mục F4) một lượt. Bước nào lỗi thì sửa, chạy lại gate, rồi đi lại đoạn đó.
3. Bản cuối, đặt trong `D:\DLU-LMS\Artifacts\final\`:
   - `dlu-lms-group-final-debug.apk` và JAR backend, mỗi file kèm SHA-256.
4. Viết `docs/RELEASE_NOTES.md`: danh sách chức năng theo mã, số test, SHA-256, cách chạy demo, giới hạn đã biết.

## F4. Tài liệu cho nhóm

### `docs/DEMO_SCRIPT.md` — kịch bản 10 phút

- Thứ tự: sinh viên 205 trước, rồi giảng viên 102. Dùng dữ liệu demo đúng ngày 20/11.
- Mỗi bước ghi đủ: bấm vào đâu, chức năng mã nào, **một câu thuyết minh**.
- Ưu tiên các bước thể hiện khác biệt:
  - thẻ GPA từ Portal, rồi mô phỏng GPA dùng dự báo LMS;
  - tiến độ CTĐT và học phần đủ điều kiện;
  - tình trạng học tập Xanh/Vàng/Đỏ;
  - kế hoạch tuần, ôn thẻ SM-2;
  - dự báo qua môn, lớp cố vấn có ẩn danh, phân tích quiz, nhắc riêng.
- Có nhánh dự phòng: Portal DOWN thì bỏ qua đoạn nào, nói gì; emulator treo thì làm gì.
- Cuối kịch bản: **8 câu hội đồng dễ hỏi** kèm câu trả lời ngắn, dựa trên code thật:
  - khác Moodle ở đâu;
  - dữ liệu lấy từ đâu, có thật không;
  - bảo mật đăng nhập và MSSV;
  - SM-2 hoạt động thế nào;
  - GPA dự kiến tính ra sao;
  - vì sao không dùng API miễn giảm học phí;
  - đã kiểm thử thế nào;
  - triển khai thật cần gì.

### `docs/USER_GUIDE.md` — hướng dẫn sử dụng

- Theo từng màn hình, chia hai phần sinh viên và giảng viên.
- Mỗi mục: mục đích, cách dùng 2–4 bước, tên file ảnh minh họa trong `D:\DLU-LMS\Artifacts\v2|v3\screens`.

## F5. Video demo quay màn hình thật

- Quay theo `DEMO_SCRIPT.md`, từng đoạn ngắn hơn 3 phút:
  `adb shell screenrecord --bit-rate 6000000 --time-limit 170 /sdcard/<doan>.mp4`
- Các đoạn: `sv-1-tong-quan-gpa`, `sv-2-ctdt-mo-phong`, `sv-3-ke-hoach-on-the`, `gv-1-du-bao-quiz`, `gv-2-co-van-nhac-rieng`.
- Thao tác bằng `adb shell input`, lấy tọa độ từ ảnh chụp và chờ đủ lâu giữa các bước để người xem kịp đọc (2–3 giây).
- `adb pull` về `D:\DLU-LMS\Artifacts\final\video\`. Kiểm tra từng file có kích thước hợp lý và mở được.
- Ghi vào HANDOFF: tên file, thời lượng, nội dung từng đoạn.
- **Không ghép, không biên tập.** Phiên cloud sẽ ghép và thêm chú thích.

## F6. Đổi mật khẩu role ứng dụng (owner chạy, không chặn các mục khác)

Viết `tools\Rotate-AppRolePassword.ps1`:
1. Hỏi mật khẩu postgres bằng ô nhập ẩn.
2. Sinh mật khẩu ngẫu nhiên 32 ký tự cho `lms_group_app`, rồi `ALTER ROLE` (role thuộc cấp cluster, chỉ cần đổi một lần).
3. Cập nhật `.local\backend.json`, không in mật khẩu ra màn hình.
4. Kiểm tra lại: backend đăng nhập được bằng mật khẩu mới.

Viết xong thì ghi vào phần "Việc cho owner" trong HANDOFF.

## F7. Kết thúc

1. Commit cục bộ, đặt tag `bao-ve-2026-11-20`. Không push.
2. Chạy `Stop-Demo.ps1`.
3. Viết mục tổng kết trong HANDOFF, gồm:
   - số test cuối;
   - SHA-256 của APK và JAR;
   - đường dẫn ảnh và video;
   - danh sách "Việc cho owner": chạy Start-Demo sau khi đóng Claude, chạy Rotate-AppRolePassword, dọn ổ C còn trống ít nhất 22 GiB.
