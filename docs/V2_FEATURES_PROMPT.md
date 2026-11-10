# GÓI CHỨC NĂNG MỚI V2 — DLU LMS Group (prompt cho phiên Claude Code native)

Soạn ngày 07/11/2026 bởi phiên cloud (chỉ đọc, chỉ review). Phiên native là writer duy nhất.

## 0. Bối cảnh — đọc trước khi làm

Giảng viên nhận xét: ứng dụng **thiếu chức năng** và **chưa thấy khác biệt rõ với Moodle**. Lần chạy thật T09 (07/11) đã xác nhận mọi luồng có sẵn đều chạy, nhưng đó là những gì nhóm đã có từ trước. Gói V2 thêm chức năng **mới thật sự**, mỗi chức năng phải trả lời được câu "Moodle không làm điều này cho sinh viên/giảng viên".

**ĐÃ CÓ — KHÔNG làm lại, chỉ được tái sử dụng:**
- Phía sinh viên: dashboard (Ưu tiên hôm nay, Tiếp tục học), việc cần làm, khóa học, điểm, chuyên cần, nhật ký kèm mức hiểu bài, thẻ ghi nhớ CRUD kèm nút "Bắt đầu ôn tập" đơn giản, mục tiêu, phân tích (streak, biểu đồ tuần), thông báo.
- Phía giảng viên: trợ lý giảng dạy, khóa học, danh sách sinh viên có lọc, theo dõi bài tập và quiz, điểm theo dõi kèm lý do (+40/+30…), việc cần làm tuần này, hiệu quả hỗ trợ, ghi chú, nhắc nhóm.

**Dữ liệu thật đang có** (DB `lms_mobile_group_dev`, role `lms_group_app`):
- `lms.grade_items`: 28 mục, `itemtype='mod'`, grademax 100, gradepass 50, aggregationcoef 0.
- `lms.grade_categories`: aggregation 0 (Mean of grades), 2 tầng.
- `lms.grade_grades`, `lms.course_sections`, `lms.course_modules`, `lms.course_modules_completion`.
- `derived.student_course_learning_items`: có section, completionstate, moodle_path.
- `derived.student_grade_overview`: có grade_percentage và course_average_percentage.
- `derived.unified_tasks`, `derived.student_course_progress`.
- `app.learning_reflections.understanding_level`.
- `app.learning_goals`: goal_type cho phép `target_grade`.
- `app.notification_preferences`: bảng đã tồn tại nhưng code chưa dùng.
- Mọi hạn nộp trong dữ liệu mẫu nằm quanh tháng 9/2026, nên hiện tại đều đã quá hạn; các view dùng CURRENT_TIMESTAMP.

## 1. Quy tắc (giữ nguyên các quy tắc cũ, thêm các điểm sau)

1. Không ghi vào schema `lms`, không import đè, không push/deploy, không đổi credential.
2. Mọi thay đổi cấu trúc CSDL (DDL) gom vào **một** migration ở Đợt 2. Owner chạy migration bằng script có kiểm tra an toàn. Runtime vẫn là `lms_group_app`, không có quyền DDL.
3. Không có số liệu cứng hoặc dữ liệu bịa. Thiếu dữ liệu thì hiện trạng thái rỗng có giải thích. Mỗi con số trên màn hình phải truy được về một truy vấn.
4. Mọi endpoint mới:
   - Nằm dưới `/api/v1/dev/students/{userId}/…` hoặc `/api/v1/dev/teachers/{teacherId}/…` để `PathIdentityAuthorizationManager` bảo vệ.
   - Có kiểm tra ghi danh (với sinh viên) hoặc roster (với giảng viên); không thuộc thì trả 404.
   - Có test WebMvc cho 401, 403 và 404.
5. Logic tính toán viết thành hàm thuần (pure) trong service riêng và có unit test dạng bảng.
6. Gate sau **mỗi** chức năng: `tools\Test-Backend.ps1 -Package` exit 0 và `tools\Test-Flutter.ps1` exit 0. Cuối mỗi đợt chạy thêm `-BuildApk` và kiểm tra trên emulator (chụp ảnh).
7. Một gate fail 3 lần thì ghi BLOCKED kèm lý do vào TASK_BOARD rồi sang chức năng tiếp theo, không dừng cả gói.
8. Cache và đầu ra nằm trên D: dùng `tools\Use-LocalToolchain.ps1` (PUB_CACHE và GRADLE_USER_HOME trên D). Nếu ổ C còn dưới 15 GiB thì tắt emulator trước khi build.
9. Giao diện: tiếng Việt, Material 3, theo theme xanh hiện có, tái dùng widget sẵn có (`metric_card`, `moodle_button`, `learning_widgets`, `async_tab`).
10. Sau mỗi chức năng, ghi vào HANDOFF.md theo đúng mẫu ở mục 6 và cập nhật TASK_BOARD (ID V2-N1 … V2-N8).
11. Viết `docs/FEATURES_V2.md`: mỗi chức năng có mục đích, công thức, nguồn dữ liệu và điểm khác Moodle. Tài liệu này để đưa vào báo cáo.

## 2. ĐỢT 1 — không cần đổi CSDL (làm trước, giá trị cao nhất)

### V2-N1. Mô phỏng điểm và "điểm cần đạt" (sinh viên)

**Khác Moodle:** Moodle chỉ cho xem điểm đã có. Ứng dụng tính được cần bao nhiêu ở các bài còn lại để qua môn hoặc đạt mục tiêu, và cho thử "nếu bài X được Y điểm thì tổng là bao nhiêu".

**Engine** (`GradeForecastService`, hàm thuần):
- Dựng cây từ `grade_categories` (theo parent/depth) và `grade_items` có `hidden=0`.
- aggregation 0 (Mean of grades): trung bình đều các con đã chuẩn hóa về %. Nếu `aggregationcoef > 0` thì dùng trung bình có trọng số. Các kiểu aggregation khác dùng trung bình và trả `approximation=true`.
- Mỗi item có trọng số hiệu dụng `w_i` = tích của (1/số con) theo từng tầng, hoặc trọng số chuẩn hóa. Tổng các `w_i` bằng 1.
- `current` = trung bình chỉ trên các item đã có điểm, tôn trọng `aggregateonlygraded`.
- `need` = (target − Σ w_i·s_i của item đã chấm) / Σ w_j của item chưa chấm.
- Trạng thái:
  - `ACHIEVED` nếu need ≤ 0.
  - `FEASIBLE` nếu need ≤ 100.
  - `NOT_FEASIBLE` nếu need > 100.
  - `NO_REMAINING` nếu không còn item nào chưa chấm.
- Ngưỡng qua môn = gradepass/grademax. Không có gradepass thì dùng 50% và ghi rõ là mặc định.

**API:** `GET /api/v1/dev/students/{userId}/courses/{courseId}/grade-forecast`. Trả về:
- `current`, `passPercent`.
- `items[]`: gradeItemId, name, activityType, category, scorePercent (null nếu chưa chấm), weight, dueTime, moodlePath.
- `approximation`.

**UI:** ở tab Điểm của chi tiết khóa, thêm thẻ "Mô phỏng điểm" mở màn hình mới gồm:
- Điểm hiện tại.
- Chọn mục tiêu: Qua môn, 70%, 80%, 90% hoặc tự nhập.
- Câu kết luận, ví dụ "Bạn cần trung bình 64% ở 2 bài còn lại".
- Mỗi bài chưa chấm có một slider; điểm dự kiến cập nhật ngay khi kéo, tính phía client bằng `w_i`.
- Nút "Lưu làm mục tiêu": gọi API goals sẵn có với `goal_type='target_grade'` và `course_id`.

**Test:**
- Engine: tất cả đã chấm, chưa chấm bài nào, mục tiêu không khả thi, item bị ẩn, có trọng số, cây hai tầng.
- Security: 401, 403 và 404 khi chưa ghi danh.
- Widget: kéo slider làm thay đổi điểm dự kiến.

### V2-N2. Gợi ý ôn lại theo chương (sinh viên)

**Khác Moodle:** Moodle không nối "điểm thấp ở quiz chương 3" với "2 tài liệu chương 3 bạn chưa mở".

**Logic:**
- Ghép `student_course_learning_items` (section, completion, moodle_path) với `student_grade_overview` theo (activity_type, source_id).
- Một chương là **yếu** nếu thỏa một trong ba điều kiện:
  - trung bình điểm các hoạt động đã chấm trong chương dưới ngưỡng qua môn;
  - thấp hơn trung bình lớp từ 10 điểm % trở lên;
  - có hoạt động chấm điểm quá hạn mà chưa hoàn thành.
- Mỗi chương yếu gợi ý tối đa 3 mục: ưu tiên tài liệu hoặc hoạt động chưa hoàn thành trong cùng chương, sau đó đến bài có điểm thấp nhất.
- Lý do ghi bằng số, ví dụ "MVP3 – Quiz 3.1: 0% (lớp 36,5%)".

**API:**
- `GET …/students/{userId}/courses/{courseId}/study-recommendations`
- `GET …/students/{userId}/study-recommendations?limit=3` (gộp mọi khóa, xếp theo mức độ yếu)

**UI:**
- Thẻ "Nên ôn lại" trên dashboard, đặt dưới "Ưu tiên hôm nay".
- Một mục trong chi tiết khóa.
- Mỗi gợi ý có nút "Mở trên LMS" và "Tạo thẻ ghi nhớ" (mở dialog thêm thẻ của khóa đó).

**Test:** chương không có điểm, chương yếu vì lớp cao hơn, giới hạn 3 gợi ý, security.

### V2-N3. Vị trí của tôi trong lớp — ẩn danh (sinh viên)

**Khác Moodle:** Moodle không cho sinh viên biết mình đứng đâu so với lớp. Ứng dụng cho biết điều này mà không lộ dữ liệu của ai.

**Logic** (tính hoàn toàn ở server):
- Với tiến độ (`student_course_progress`) và điểm trung bình đã chấm, trả về:
  - phần trăm bạn cùng lớp có kết quả thấp hơn mình;
  - trung vị của lớp;
  - histogram 5 khoảng 20%, kèm khoảng của mình.
- **Chỉ trả kết quả khi lớp có ≥ 5 sinh viên có dữ liệu.** Ít hơn thì trả `suppressed=true`, UI hiện "Lớp quá nhỏ để so sánh ẩn danh".
- Response tuyệt đối không chứa userId, tên hay giá trị của từng người.

**API:** `GET …/students/{userId}/courses/{courseId}/peer-comparison`

**UI:** thẻ ở tab Tổng quan của chi tiết khóa và trong màn Phân tích: câu kết luận cùng biểu đồ cột (fl_chart), cột của mình tô đậm.

**Test:**
- Lớp 4 người bị suppressed.
- Lớp 15 người tính đúng phần trăm.
- JSON response không có khóa `userid` hay `name`.
- Security.

### V2-N4. Dự báo qua môn của cả lớp (giảng viên)

**Khác Moodle:** điểm theo dõi hiện có đo hành vi. Chức năng này dùng điểm thật để chỉ ra ai đã không còn khả năng qua môn, và ai cần đạt bao nhiêu.

**Logic:** chạy engine N1 cho từng sinh viên trong roster của khóa. Mỗi sinh viên có: current, bestCase (100% mọi bài còn lại), need để qua môn, và trạng thái:
- Đã chắc qua.
- An toàn (need ≤ 60).
- Cần cố gắng (60 < need ≤ 85).
- Nguy cơ cao (85 < need ≤ 100).
- Không còn khả thi.

Ngưỡng ghi trong `FEATURES_V2.md`.

**API:** `GET /api/v1/dev/teachers/{teacherId}/courses/{courseId}/grade-forecast` (có kiểm tra roster).

**UI:** mục "Dự báo qua môn" trong tab Phân tích của giảng viên: các ô đếm theo trạng thái và danh sách sinh viên. Bấm vào một sinh viên thì mở chi tiết sẵn có, có nút "Nhắc riêng" (nối với N8).

**Test:** engine dùng chung với N1; security 403 khi gọi khóa của giảng viên khác.

**Cuối Đợt 1:**
- Chạy `-BuildApk`, cài lên emulator, chạy N1–N4 với sinh viên 205 và giảng viên 102.
- Chụp ảnh vào `D:\DLU-LMS\Artifacts\v2\screens\` theo tên `n1-01-….png`.
- Ghi HANDOFF.

## 3. ĐỢT 2 — một migration duy nhất, owner chạy một lần

### Migration

Tạo `database/migrations/2026-11-08_v2_features.sql`. Yêu cầu:
- Idempotent (dùng IF NOT EXISTS), chạy trong một transaction duy nhất.
- Chỉ đụng schema `app`.

Nội dung:

```sql
-- app.flashcard_reviews: trạng thái SM-2 theo từng thẻ và từng người
id bigserial PK, flashcard_id bigint NOT NULL REFERENCES app.flashcards(id) ON DELETE CASCADE,
user_id bigint NOT NULL, repetitions int NOT NULL DEFAULT 0, ease_factor numeric(4,2) NOT NULL DEFAULT 2.50,
interval_days int NOT NULL DEFAULT 0, due_at timestamptz NOT NULL DEFAULT now(),
last_rating smallint CHECK (last_rating BETWEEN 0 AND 5), last_reviewed_at timestamptz,
UNIQUE (flashcard_id, user_id)

-- app.study_plan_items: kế hoạch học tuần
id bigserial PK, user_id bigint NOT NULL, course_id bigint, plan_date date NOT NULL,
source_type varchar(20) NOT NULL CHECK (source_type IN ('assign','quiz','resource','flashcards','custom')),
source_id bigint, title varchar(255) NOT NULL, planned_minutes int NOT NULL CHECK (planned_minutes > 0),
status varchar(10) NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','done','skipped')),
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
-- index (user_id, plan_date)
```

Grants: thêm vào `database/grants_lms_group_app.sql`:
- `flashcard_reviews`: SELECT, INSERT, UPDATE.
- `study_plan_items`: SELECT, INSERT, UPDATE, DELETE.
- `app.notification_preferences`: SELECT, INSERT, UPDATE.
- USAGE và SELECT trên các sequence tương ứng.

Không cấp gì thêm cho schema `lms`.

### Script cho owner

Viết `tools\Apply-V2Migration.ps1` theo khuôn `Invoke-GroupRestore.ps1`:
1. Hỏi mật khẩu postgres ẩn, chỉ giữ trong biến môi trường của process.
2. Kiểm tra đúng cluster `D:\DLU-LMS\PostgreSQL\data` và `127.0.0.1:55432`, DB tồn tại, ổ C ≥ 15 GiB.
3. Sao lưu schema app: `pg_dump -n app` vào `D:\DLU-LMS\Backups\app-before-v2-<stamp>.sql`.
4. `psql --single-transaction -f` migration, sau đó áp grants.
5. Báo cáo quyền dạng tổng hợp, giống `-ReportOnly`.
6. Ghi log vào `D:\DLU-LMS\PostgreSQL\logs\`.

**DỪNG và nhờ owner chạy script.** Trong lúc chờ, tiếp tục viết code N5–N7 kèm test (test không cần DB).

### V2-N5. Ôn tập ngắt quãng SM-2 (sinh viên)

**Khác Moodle:** thẻ không được ôn theo kiểu lật hết một lượt; ứng dụng tự xếp lịch thẻ nào cần ôn hôm nay.

**Thuật toán SM-2** (hàm thuần):
- 4 nút ứng với q: Quên = 1, Khó = 3, Được = 4, Dễ = 5.
- Nếu q < 3: repetitions = 0, interval = 1.
- Ngược lại: repetitions + 1; interval = 1 ở lần 1, 6 ở lần 2, các lần sau = round(interval × EF).
- EF' = EF + (0,1 − (5−q)(0,08 + (5−q)·0,02)), tối thiểu 1,3.
- due_at = now + interval ngày. Thẻ chưa có review thì đến hạn ngay.

**API:**
- `GET …/students/{userId}/flashcards/due?courseId=`
- `POST …/students/{userId}/courses/{courseId}/flashcards/{id}/review` với body `{rating}`; trả về lịch kế tiếp.

**UI:**
- Thay luồng "Bắt đầu ôn tập" bằng phiên ôn: mặt trước → chạm để lật → 4 nút, mỗi nút ghi khoảng thời gian kế tiếp (ví dụ "1 ngày", "6 ngày") → màn tổng kết phiên.
- Trên dashboard có chip "Hôm nay cần ôn N thẻ".

**Test:** bảng các trường hợp SM-2 (lặp lại nhiều lần, quên rồi học lại, chặn EF ở 1,3); security (thẻ của người khác, khóa chưa ghi danh).

### V2-N6. Kế hoạch học tuần tự động — "Hôm nay học gì" (sinh viên)

**Khác Moodle:** Moodle liệt kê hạn nộp. Ứng dụng biến danh sách đó thành lịch học từng ngày vừa với quỹ thời gian của sinh viên.

**Đầu vào:**
- `unified_tasks` chưa xong (quá hạn, hoặc đến hạn trong 14 ngày).
- Số thẻ đến hạn ôn (N5).
- Gợi ý ôn lại (N2).
- Quỹ phút mỗi ngày: 30, 60, 90 hoặc 120 do sinh viên chọn.

**Thuật toán** (hàm thuần, kết quả xác định):
- Ước lượng thời lượng: assign 90 phút, quiz 45 phút, tài liệu gợi ý 20 phút, thẻ ôn 1,5 phút/thẻ.
- Xếp việc quá hạn trước ("Gỡ việc tồn"), sau đó theo hạn sớm nhất.
- Mỗi việc đặt vào ngày sớm nhất còn đủ chỗ và trước hạn ít nhất 1 ngày. Một assign có thể tách thành 2 phần 45 phút.
- Việc không xếp kịp trước hạn thì đưa vào cảnh báo "Quá tải" kèm tên việc.

**Lưu trữ:**
- Ghi vào `app.study_plan_items`.
- Tạo lại kế hoạch thì xóa các mục `planned` từ hôm nay trở đi, giữ nguyên mục `done`.

**API:**
- `POST …/students/{userId}/study-plan/generate` với body `{dailyMinutes}`
- `GET …/students/{userId}/study-plan?from=&to=`
- `PUT …/students/{userId}/study-plan/items/{id}/status`

**UI:**
- Màn "Kế hoạch tuần": dải 7 ngày, danh sách việc từng ngày có checkbox, thanh phút đã dùng / quỹ phút, thẻ cảnh báo quá tải.
- Đầu dashboard thêm thẻ "Hôm nay: 3 việc · 105 phút", bấm vào mở kế hoạch.

**Test:** ngày bị quá tải, tách assign, việc quá hạn, tạo lại kế hoạch vẫn giữ mục done, security.

### V2-N7. Nhắc học trên điện thoại kể cả khi không mở app, kèm cài đặt nhắc (sinh viên)

**Khác Moodle:** nhắc theo kế hoạch cá nhân và theo thẻ đến hạn ôn, không chỉ theo hạn nộp.

**Backend:** `GET/PUT …/students/{userId}/notification-preferences` dùng bảng `app.notification_preferences` sẵn có. Chưa có dòng thì trả mặc định; PUT dùng upsert.

**Flutter:**
- Thêm `flutter_local_notifications` và `timezone`. Lấy phiên bản ổn định, ghi phiên bản vào HANDOFF.
- Android 13+ cần quyền POST_NOTIFICATIONS. Không dùng exact alarm nếu không bắt buộc.
- Màn "Cài đặt nhắc" gồm:
  - bật/tắt nhắc hạn nộp, nhắc ôn thẻ, nhắc kế hoạch;
  - số giờ nhắc trước hạn (`default_reminder_before_hours`);
  - giờ nhắc hằng ngày;
  - nút "Gửi thử thông báo".
- Lên lịch:
  - hạn nộp còn ở tương lai;
  - nhắc hằng ngày "Hôm nay cần ôn N thẻ · M việc trong kế hoạch".
- Hạn đã qua thì không lên lịch. Màn hình ghi rõ "Không có hạn nộp sắp tới".

**Test:** test hàm tính lịch nhắc (hạn trong quá khứ thì bỏ qua, đổi số giờ trước hạn); widget test màn cài đặt; plugin dùng mock.

**Cuối Đợt 2:** APK, chạy trên emulator, chụp ảnh `n5-…`, `n6-…`, `n7-…`. Ảnh N7 cần có thông báo thật hiện trên thanh thông báo của emulator. Ghi HANDOFF.

## 4. ĐỢT 3 — tiện ích cho giảng viên

### V2-N8. Nhắc riêng một sinh viên, có lời nhắc mẫu, và xuất danh sách cần hỗ trợ

**Nhắc riêng:**
- Thêm nút "Nhắc riêng" ở chi tiết sinh viên và trong danh sách N4.
- Composer mở với đúng 1 người nhận.
- Có 3 mẫu lời nhắc (quá hạn, lâu không truy cập, điểm thấp), điền sẵn số liệu thật từ lý do cảnh báo của sinh viên đó.
- Đọc `TeacherReminderService.send`. Nếu payload chưa nhận danh sách studentIds tùy ý thì mở rộng, vẫn giữ kiểm tra roster.
- Test: 1 sinh viên trong lớp gửi được; sinh viên ngoài lớp trả 404 và không ghi dữ liệu.

**Xuất CSV:**
- Trong khóa của giảng viên, nút "Xuất danh sách cần hỗ trợ" tạo file CSV UTF-8 có BOM.
- Cột: MSSV, họ tên, điểm theo dõi, lý do, dự báo qua môn (N4), ghi chú gần nhất.
- Chia sẻ bằng `share_plus` (file tạm trong thư mục cache của app).
- Test: hàm dựng CSV (escape dấu phẩy, dấu ngoặc kép, tiếng Việt).

## 5. Tùy chọn — CHỈ làm khi owner ghi rõ `DOI_NGAY_DEMO=CO`

Dữ liệu mẫu có hạn nộp quanh tháng 9/2026 nên "Sắp hạn", kế hoạch tuần và nhắc hạn trông như toàn việc tồn. Nếu owner đồng ý:
- Tạo DB **riêng** `lms_mobile_group_demo`, restore từ cùng file dump (giữ nguyên SHA).
- Trong DB này, dời mọi cột thời gian epoch của `lms` thêm cùng một số ngày, sao cho hôm bảo vệ có việc sắp hạn trong 1–7 ngày tới. Viết script có danh sách cột rõ ràng.
- DB gốc `lms_mobile_group_dev` giữ nguyên.
- Backend chọn DB qua `.local\backend.json`.
- Ghi vào báo cáo: "dữ liệu mẫu đã dời mốc thời gian để minh họa".

Không có dòng `DOI_NGAY_DEMO=CO` thì bỏ qua toàn bộ mục này.

## 6. Mẫu báo cáo trong HANDOFF (sau mỗi chức năng)

```
### V2-Nx <tên> — <ngày giờ>
Files: <danh sách file thêm/sửa>
API: <endpoint mới>
Tests: backend <tổng>/<fail>/<error>/<skip>; flutter <tổng> pass; test mới: <tên>
Gate: Test-Backend -Package exit <n>, JAR SHA256 <8 ký tự đầu…8 ký tự cuối>; Test-Flutter exit <n>
Runtime: <đã chạy trên emulator? ảnh nào>
Còn thiếu / giới hạn: <trung thực>
```

## 7. Kết thúc

1. Cập nhật TASK_BOARD: V2-N1…N8 ở trạng thái DONE, BLOCKED hoặc NOT_RUN.
2. Quay video màn hình emulator: `adb shell screenrecord --time-limit 170 /sdcard/v2-<n>.mp4` cho từng đợt, `adb pull` vào `D:\DLU-LMS\Artifacts\v2\video\`.
3. Tắt emulator, backend, postgres theo thứ tự.
4. Báo owner một đoạn ngắn:
   - chức năng nào xong và đã chạy thật;
   - chức năng nào còn thiếu;
   - đường dẫn ảnh và video.

Phiên cloud sẽ tự kiểm chứng lại, rồi cập nhật báo cáo, slide và video demo.
