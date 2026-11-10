# GÓI V2 — PHẦN B: thêm chức năng và bằng chứng đánh giá (đọc sau V2_FEATURES_PROMPT.md)

Soạn ngày 07/11/2026 bởi phiên cloud. Phần B **bổ sung** cho `docs/V2_FEATURES_PROMPT.md`, không thay thế. Mọi quy tắc ở mục 1 của file đó vẫn áp dụng: gate, bảo mật, không số liệu bịa, không ghi `lms`, mẫu HANDOFF.

Mục tiêu: hội đồng phản biện chấm vào ba điều.
1. Có nhiều chức năng hữu ích và khác biệt rõ với Moodle.
2. Chức năng có chiều sâu kỹ thuật thật: thuật toán, bảo mật, riêng tư.
3. Có bằng chứng: chạy thật, đo được, có người dùng thử.

Phần B thêm 10 chức năng (N9–N18), 1 việc vận hành (O1) và 1 việc đo hiệu năng (E2).

## 0. Thứ tự toàn gói — thay cho thứ tự cũ

Ưu tiên từ trên xuống. Hết thời gian thì những gì đã xong vẫn hoàn chỉnh.

| Hạng | Thứ tự | Loại |
| --- | --- | --- |
| A — bắt buộc | N1 → N9 → N2 → N4 → N3 | khác biệt, không cần DDL |
| A | Migration (gồm cả bảng mới của Phần B) → N5 → N6 → N7 → N10 | khác biệt, cần DDL |
| B — mạnh | N8 → N15 → N16 → O1 → E2 | giảng viên, vận hành, bằng chứng |
| C — hoàn thiện | N11 → N12 → N13 → N14 → N17 → N18 | tiện ích, đánh bóng |

Sau mỗi hạng: chạy `-BuildApk`, kiểm tra trên emulator, chụp ảnh, ghi HANDOFF.

**Migration:**
- Nếu `Apply-V2Migration.ps1` **chưa chạy**: thêm bảng `app.study_sessions` (mục N10) vào cùng file migration và grants, để owner chỉ chạy một lần.
- Nếu **đã chạy**: tạo `database/migrations/2026-11-08b_v2_study_sessions.sql` cùng tham số `-MigrationFile` cho script, và gộp vào lần nhờ owner kế tiếp.

**Ghi nhãn trung thực** trong `docs/FEATURES_V2.md`. Mỗi chức năng ghi một trong hai nhãn:
- **"Khác biệt"**: Moodle web lẫn Moodle App đều không có.
- **"Tiện ích"**: Moodle App có dạng tương tự; ghi rõ ứng dụng làm khác ở điểm nào.

Không được ghi "khác biệt" cho offline, lịch hoặc tìm kiếm.

## 1. Hạng A bổ sung

### V2-N9. "Tình trạng học tập của tôi" (sinh viên) — Khác biệt

**Vấn đề:** giảng viên thấy điểm theo dõi và lý do cảnh báo của sinh viên (+40 vì 77 ngày không truy cập…), còn **chính sinh viên thì không thấy**.

**Logic:**
- Dùng đúng các tín hiệu giảng viên đang thấy, nhưng chỉ cho `userId` của chính người dùng: `derived.student_risk_indicator`, `derived.student_engagement`, `derived.student_learning_analytics`, và cùng các ngưỡng mà `ClassInsightsService` đang dùng.
- Tách công thức chấm điểm ra một hàm dùng chung, để điểm sinh viên thấy luôn bằng điểm giảng viên thấy. Viết test khẳng định điều này.
- Mỗi khóa có một mức Xanh / Vàng / Đỏ và danh sách lý do kèm số.
- Có mục "Làm gì để lên Xanh": tối đa 3 hành động cụ thể, mỗi hành động nối tới màn liên quan (việc quá hạn → Việc cần làm; lâu không truy cập → Mở trên LMS; chương yếu → N2).

**API:** `GET /api/v1/dev/students/{userId}/learning-health` (mọi khóa) và `…/courses/{courseId}/learning-health`.

**UI:** thẻ màu ở đầu dashboard và ở tab Tổng quan của khóa.

**Test:**
- Điểm sinh viên thấy bằng điểm giảng viên thấy cho cùng một sinh viên và khóa.
- Không lộ dữ liệu người khác.
- Security.

### V2-N10. Phiên học tập trung (Pomodoro) và mục tiêu phút học (sinh viên) — Khác biệt

**Vấn đề:** `GoalService` hiện từ chối `study_minutes` với lỗi "hệ thống không ghi nhận thời lượng học", dù bảng mục tiêu đã có loại này. N10 lấp đúng chỗ trống đó.

**Bảng** (trong migration):

```sql
app.study_sessions: id bigserial PK, user_id bigint NOT NULL, course_id bigint,
plan_item_id bigint REFERENCES app.study_plan_items(id) ON DELETE SET NULL,
started_at timestamptz NOT NULL, ended_at timestamptz NOT NULL, focus_minutes int NOT NULL CHECK (focus_minutes BETWEEN 1 AND 180),
created_at timestamptz NOT NULL DEFAULT now(), CHECK (ended_at > started_at)
```

Grants: SELECT và INSERT, cùng sequence.

**Backend:**
- `POST …/students/{userId}/study-sessions`.
- Server kiểm tra hợp lệ: `focus_minutes` ≤ (ended − started) + 1, không cho thời điểm ở tương lai, có kiểm tra ghi danh.
- `GET …/students/{userId}/study-sessions/summary?from=&to=`: phút học theo ngày và theo khóa.
- Mở `study_minutes` trong `GoalService`: tiến độ = tổng phút trong khoảng thời gian của mục tiêu.

**UI:**
- Màn hẹn giờ 25/5 (có thể đổi 50/10). Chọn khóa hoặc mục kế hoạch N6 trước khi bắt đầu.
- Đếm giờ phải đúng khi app chạy nền: tính theo mốc thời gian bắt đầu, không cộng dồn từng tick.
- Kết thúc phiên thì lưu lại, và đánh dấu mục kế hoạch "done" nếu sinh viên chọn.
- Màn Phân tích thêm biểu đồ "Phút học 7 ngày".

**Test:** kiểm tra hợp lệ, tổng hợp theo ngày, mục tiêu `study_minutes` tính đúng, widget hẹn giờ dùng fake clock.

## 2. Hạng B

### V2-N15. Bản đồ nhiệt tương tác của lớp (giảng viên) — Khác biệt (trên mobile)

**Dữ liệu:**
- `lms.logstore_standard_log` (userid, courseid, timecreated).
- `lms.course_modules_completion` (timemodified).
- Chỉ lấy sinh viên trong roster của khóa.

**Hiển thị:**
- Ma trận sinh viên × 8 tuần gần nhất (so với mốc thời gian dữ liệu, xem `DOI_NGAY_DEMO`).
- Ô tô theo số sự kiện, chia 4 mức.
- Sắp sinh viên "im lặng lâu nhất" lên đầu.
- Bấm vào hàng thì mở chi tiết sinh viên.

**API:** `GET /api/v1/dev/teachers/{teacherId}/courses/{courseId}/engagement-heatmap?weeks=8`.

**Test:** ranh giới tuần, sinh viên không có log, kiểm tra roster.

### V2-N16. Phân tích bài kiểm tra (giảng viên) — Tiện ích (Moodle web có thống kê quiz; ứng dụng tóm tắt thành cảnh báo hành động được trên mobile)

**Dữ liệu:** `derived.teacher_quiz_monitoring` và `lms.quiz_attempts` (sumgrades, timestart, timefinish, state).

**Mỗi quiz:**
- Histogram điểm (5 khoảng).
- Thời gian làm bài trung vị.
- Tỷ lệ chưa làm.
- Cờ tự động:
  - "Quá khó": trung bình < 50% và ≥ 3 lượt hoàn thành.
  - "Nhiều sinh viên bỏ": chưa làm ≥ 40%.
  - "Làm quá nhanh": trung vị < 20% thời gian giới hạn, chỉ xét khi có `timelimit`.
- Mỗi cờ có nút hành động: "Nhắc những sinh viên chưa làm" (dùng N8) hoặc "Mở trên LMS".

**API:** `GET …/teachers/{teacherId}/courses/{courseId}/quiz-insights`.

**Test:** quiz không có lượt làm, cờ đúng ngưỡng, roster.

### O1. Bộ khởi động demo không phụ thuộc phiên Claude — bắt buộc trước ngày bảo vệ

Vấn đề đã ghi nhận: postgres, backend và emulator chết khi phiên Claude kết thúc.

**`tools\Start-Demo.ps1`:**
- Mỗi tiến trình mở trong **cửa sổ PowerShell riêng** bằng `Start-Process pwsh -ArgumentList '-NoExit', …`, nên không phải tiến trình con của phiên Claude.
- Thứ tự:
  1. `Use-LocalPostgres.ps1 -Action Start`
  2. Chờ cổng 55432 sẵn sàng.
  3. `Start-LocalBackend.ps1`
  4. Chờ `/api/v1/health` trả UP.
  5. Bật emulator `DLU_LMS_Pixel`.
  6. `adb wait-for-device`, chờ `sys.boot_completed` bằng 1.
  7. `adb reverse tcp:8081 tcp:8081`.
  8. Mở app.
- In trạng thái từng bước. Bước nào lỗi thì dừng và in hướng xử lý.
- Kiểm tra ổ C ≥ 15 GiB trước khi bật emulator.

**`tools\Stop-Demo.ps1`:** tắt theo thứ tự ngược lại, an toàn.

**Thêm vào `docs/LOCAL_RUNBOOK.md`:** mục "Ngày bảo vệ" gồm checklist 10 dòng và cách xử lý 5 sự cố thường gặp (cổng bận, emulator treo, mất `adb reverse`, backend 401 do token hết hạn, ổ C đầy).

**Test:** owner chạy thử một lần sau khi phiên Claude đã đóng. Ghi kết quả vào HANDOFF.

### E2. Đo hiệu năng API — số liệu cho Chương 5

`tools\Measure-Api.ps1` (hoặc một script Java/Dart nhỏ, không cài công cụ mới):
- Đăng nhập demo một lần.
- Gọi **12 endpoint chính**, mỗi endpoint 200 lần (10 lần khởi động không tính): dashboard, tasks, courses, grades, grade-forecast, study-recommendations, learning-health, study-plan, flashcards/due, teacher courses, grade-forecast của giảng viên, engagement-heatmap.
- Ghi p50, p95, max (ms) và số lỗi vào `D:\DLU-LMS\Artifacts\v2\perf-<stamp>.csv`.
- Ghi kèm cấu hình máy (CPU, RAM) và ghi chú "đo cục bộ, 1 người dùng".

Không tối ưu sớm. Nếu endpoint nào có p95 > 500 ms thì ghi lại và đề xuất index, chỉ đề xuất, không tự tạo index trong `lms`.

## 3. Hạng C — tiện ích và đánh bóng

### V2-N11. Xem khi mất mạng (sinh viên) — Tiện ích (Moodle App có offline; ứng dụng cache các màn tổng hợp riêng của mình)

- Cache các phản hồi GET đã tải thành công: dashboard, tasks, courses, grades, grade-forecast, study-plan, flashcards. Lưu bằng `shared_preferences` hoặc file trong thư mục app, kèm thời điểm lưu.
- Mất mạng thì hiện dữ liệu cache với banner "Đang ngoại tuyến · dữ liệu lúc 21:30". Thao tác ghi bị khóa, kèm thông báo rõ ràng.
- **Bảo mật:** xóa toàn bộ cache khi đổi vai trò hoặc đăng xuất. Không cache token. Khóa cache gồm userId để không lẫn dữ liệu giữa hai vai trò.
- **Test:** đọc cache khi `http` ném `SocketException`; đổi vai trò thì cache rỗng.

### V2-N12. Lịch tổng hợp và xuất sang Google Calendar (sinh viên) — Tiện ích

- Lịch tháng và tuần gộp ba nguồn: hạn nộp (`unified_tasks`), mục kế hoạch (N6), buổi điểm danh (`lms.attendance_sessions` của các khóa đã ghi danh).
- Màu theo loại. Bấm vào ngày thì ra danh sách việc trong ngày.
- Xuất `.ics` (RFC 5545, UTF-8, có UID ổn định và VALARM theo số giờ nhắc ở N7) rồi chia sẻ bằng `share_plus` để mở trong Google Calendar.
- **Test:** hàm sinh `.ics` (escape ký tự, múi giờ Asia/Ho_Chi_Minh, UID ổn định).

### V2-N13. Tìm kiếm nhanh (cả hai vai trò) — Tiện ích

- Một ô tìm kiếm ở dashboard sinh viên và trang chủ giảng viên.
- **Sinh viên** tìm trong: khóa học, hoạt động hoặc tài liệu (`student_course_learning_items`), việc cần làm, thẻ ghi nhớ của mình.
- **Giảng viên** tìm trong: khóa học, sinh viên trong roster (tên, MSSV), bài tập, quiz.
- So khớp không phân biệt dấu tiếng Việt: chuẩn hóa NFD rồi bỏ dấu, có test với "nguyen" ↔ "Nguyễn". Tối đa 20 kết quả, nhóm theo loại.
- **API:** `GET …/students/{userId}/search?q=` và `…/teachers/{teacherId}/search?q=`. Yêu cầu q dài 2–100 ký tự, dùng tham số hóa SQL. Test SQL injection bằng chuỗi `' OR 1=1 --`.

### V2-N14. "Tuần của bạn" — báo cáo tuần cá nhân (sinh viên) — Khác biệt

- Thẻ tóm tắt tuần (thứ Hai đến Chủ nhật, theo mốc dữ liệu):
  - số việc đã xong so với kế hoạch (N6);
  - điểm mới nhận;
  - phút học (N10);
  - số thẻ đã ôn (N5);
  - chuỗi ngày học;
  - so với tuần trước (↑/↓).
- Nút "Chia sẻ": chụp widget thành PNG bằng `RepaintBoundary` rồi gửi qua `share_plus`.
- Chỉ dùng dữ liệu thật. Thiếu nguồn nào thì ẩn dòng đó, không hiện 0 giả.

### V2-N17. Thành tích (sinh viên) — Tiện ích, động lực

- 6 huy hiệu tính từ sự kiện thật, không cần bảng mới:
  - nộp đúng hạn 3 bài liên tiếp;
  - ôn thẻ 7 ngày liên tục;
  - hoàn thành kế hoạch tuần ≥ 80%;
  - tích lũy 300 phút học;
  - đạt một mục tiêu;
  - hết "Đỏ" ở một khóa (theo N9).
- Hiện những huy hiệu đã đạt, ngày đạt, và tiến độ tới huy hiệu kế tiếp.
- Chỉ hiển thị cho chính sinh viên đó, không có bảng xếp hạng.
- Test từng điều kiện.

### V2-N18. Đánh bóng giao diện

- **Chế độ tối:** theo hệ thống, kèm công tắc trong Cài đặt. Kiểm tra mọi màn mới và cũ.
- **Cỡ chữ lớn:** tôn trọng `textScaler` đến 1.3 mà không tràn layout. Viết widget test ở mức 1.3 cho 5 màn chính.
- **Onboarding 3 bước:** lần đầu chọn vai trò thì giới thiệu "Mô phỏng điểm · Kế hoạch tuần · Ôn thẻ thông minh". Lưu cờ đã xem (cờ này không nhạy cảm).
- **Nhãn truy cập** (Semantics) cho các nút chỉ có icon.

## 4. Kết thúc gói — thay cho mục 7 của file A

1. TASK_BOARD: liệt kê đủ N1–N18, O1 và E2 với trạng thái DONE, BLOCKED hoặc NOT_RUN.
2. `docs/FEATURES_V2.md`: bảng tổng hợp (chức năng | vai trò | nhãn Khác biệt/Tiện ích | nguồn dữ liệu | thuật toán hoặc công thức | test).
3. Ảnh mỗi chức năng đặt trong `D:\DLU-LMS\Artifacts\v2\screens\` theo tên `nXX-YY-mo-ta.png`.
4. Video `adb shell screenrecord` cho từng hạng, đặt trong `D:\DLU-LMS\Artifacts\v2\video\`.
5. Chạy `Start-Demo.ps1` từ cửa sổ PowerShell của owner, sau đó tắt bằng `Stop-Demo.ps1`.
6. Báo owner: chức năng nào xong và đã chạy thật, chức năng nào chưa, kèm đường dẫn bằng chứng.
