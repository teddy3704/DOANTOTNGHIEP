# Chức năng V2 — DLU LMS Group

Tài liệu cho báo cáo. Mọi con số trên màn hình lấy từ truy vấn ghi ở cột "Nguồn dữ liệu". Không có số cứng, không có dữ liệu bịa.
Thiếu dữ liệu thì màn hình hiện trạng thái rỗng kèm giải thích.

Nhãn:
- **Khác biệt**: cả Moodle web và Moodle App đều không có.
- **Tiện ích**: Moodle App có dạng tương tự; cột ghi chú nêu ứng dụng làm khác ở điểm nào.

Ràng buộc kỹ thuật chung:
- Runtime role `lms_group_app` chỉ đọc schema `lms` qua các view `derived` đã cấp; không có quyền trên `lms.grade_*`.
- Vì vậy engine điểm không đọc được `aggregation`, `aggregationcoef`, `hidden`, `aggregateonlygraded` của Moodle. Engine giả định "Mean of grades" (aggregation 0), đúng với dữ liệu khóa học hiện có, và ghi rõ giả định này trên màn hình.

## Bảng tổng hợp

| Chức năng | Vai trò | Nhãn | Nguồn dữ liệu | Thuật toán / công thức | Test |
| --- | --- | --- | --- | --- | --- |
| N1 Mô phỏng điểm, "điểm cần đạt" | SV | Khác biệt | `derived.student_grade_overview` (mọi bài của khóa + điểm của SV), `derived.student_course_learning_items` (module hiển thị, hạn, link) | Cây 2 tầng, trọng số hiệu dụng, need (mục N1) | `GradeForecastServiceTest` (13), `V2SecurityTest`, `grade_forecast_test.dart` (4) |
| N9 Tình trạng học tập của tôi | SV | Khác biệt | `derived.student_risk_indicator` + `derived.student_course_progress` (chỉ `userid` của chính SV) | `RiskScore` dùng chung với giảng viên (mục N9) | `LearningHealthServiceTest` (6, gồm "điểm SV = điểm GV"), `learning_health_test.dart` (3) |
| N2 Gợi ý ôn lại theo chương | SV | Khác biệt | learning items theo section, điểm của SV, trung bình lớp theo bài (chỉ số tổng hợp) | 3 điều kiện "chương yếu", ≤3 gợi ý (mục N2) | `StudyRecommendationServiceTest` (6), `study_recommendation_test.dart` (3) |
| N4 Dự báo qua môn của cả lớp | GV | Khác biệt | Engine N1 cho từng SV trong roster (`TeacherRepository.findStudents`) | Nhóm theo need (mục N4) | `TeacherForecastTest` (3), `class_forecast_test.dart` (2) |
| N3 Vị trí của tôi trong lớp (ẩn danh) | SV | Khác biệt | `derived.student_course_progress`, trung bình điểm theo SV từ `derived.student_grade_overview`; repository chỉ trả (là tôi?, giá trị) | Phần trăm thấp hơn, trung vị, histogram 5 khoảng, ẩn khi <5 SV (mục N3) | `PeerComparisonServiceTest` (6), `peer_comparison_test.dart` (2) |
| N5 Ôn tập ngắt quãng SM-2 | SV | Khác biệt | `app.flashcards` của SV (khóa đã ghi danh), `app.flashcard_reviews` (trạng thái SM-2 theo thẻ và người) | SM-2 (mục N5) | `Sm2Test` (16), `FlashcardReviewServiceTest` (8), `V2SecurityTest`, `flashcard_review_test.dart` (12) |
| N6 Kế hoạch học tuần | SV | Khác biệt | `derived.unified_tasks` của SV (chưa xong, quá hạn hoặc hạn ≤14 ngày), số thẻ đến hạn (N5), gợi ý N2; lưu ở `app.study_plan_items` | Xếp tham lam xác định theo ưu tiên + hạn, tách assign 2×45′, cảnh báo quá tải (mục N6) | `StudyPlannerTest` (9), `StudyPlanServiceTest` (8), `V2SecurityTest`, `study_plan_test.dart` (5) |
| N7 Nhắc học trên điện thoại + cài đặt | SV | Khác biệt | `app.notification_preferences` (dòng của chính SV), việc chưa xong có hạn (`/tasks`), thẻ đến hạn (N5), kế hoạch (N6) | Lịch nhắc = hạn − N giờ (bỏ hạn đã qua), nhắc hằng ngày 7 lần kế tiếp (mục N7) | `NotificationPreferenceServiceTest` (6), `V2SecurityTest`, `reminder_test.dart` (13) |
| N10 Phiên học tập trung (Pomodoro) + mục tiêu phút học | SV | Khác biệt | `app.study_sessions` (chỉ phiên của SV), `app.study_plan_items` (đánh dấu xong), `derived.student_course_progress` (ghi danh) | Thời gian còn lại tính từ mốc bắt đầu; kiểm hợp lệ phía server; tổng theo ngày/khóa; tiến độ mục tiêu `study_minutes` (mục N10) | `StudySessionServiceTest` (8), `V2SecurityTest`, `InsightsApiTest`, `focus_timer_test.dart` (6) |
| N8 Nhắc riêng 1 SV + xuất CSV cần hỗ trợ | GV | Tiện ích (Moodle có nhắn tin; ứng dụng điền sẵn lời nhắc bằng số liệu thật của SV và xuất danh sách kèm dự báo N4) | roster + insights lớp (điểm theo dõi, lý do), N4, `app.teacher_notes` (ghi chú mới nhất), ghi `app.notifications` + `app.teacher_notes` | 3 mẫu chỉ hiện khi có dữ kiện; CSV RFC 4180 UTF-8 BOM, chặn công thức | `InsightsApiTest` (gửi 1 SV, ngoài lớp 404 không ghi), `remind_one_test.dart` (6) |
| N16 Phân tích bài kiểm tra | GV | Tiện ích (Moodle web có thống kê quiz; ứng dụng tóm thành cờ hành động được trên mobile) | `derived.teacher_quiz_monitoring`, `lms.quiz`, `lms.quiz_attempts` (lượt cuối của SV trong roster), `lms.course_modules` | Histogram 5 khoảng, TB, trung vị thời gian, tỷ lệ chưa làm, 3 cờ (mục N16) | `QuizInsightsServiceTest` (8), `V2SecurityTest`, `quiz_insights_test.dart` (3) |
| N15 Bản đồ nhiệt tương tác của lớp | GV | Khác biệt (trên mobile) | `lms.logstore_standard_log` theo tuần, chỉ SV trong roster | Ma trận SV × tuần, 4 mức theo phần tư tuần cao nhất, SV im lặng lâu nhất lên đầu (mục N15) | `InsightsApiTest` (heatmap + endpoint), `HeatLevelTest`, `heatmap_levels_test.dart` |
| N11 Xem khi mất mạng | SV | Tiện ích (Moodle App có offline; ứng dụng cache các màn tổng hợp riêng của mình) | phản hồi GET đã tải thành công (lưu trên máy) | Danh sách đường dẫn được phép; lỗi mạng → dữ liệu lưu + banner; khóa ghi (mục N11) | `offline_cache_test.dart` (5) |
| N12 Lịch tổng hợp + xuất .ics | SV | Tiện ích (Moodle có lịch; ứng dụng gộp thêm kế hoạch N6 và buổi điểm danh, xuất .ics có nhắc theo N7) | `derived.unified_tasks`, `app.study_plan_items`, `lms.attendance_sessions` (khóa đã ghi danh) | Gộp 3 nguồn, UID ổn định, RFC 5545 (mục N12) | `StudentCalendarServiceTest` (2), `V2SecurityTest`, `calendar_ics_test.dart` (3) |
| N13 Tìm kiếm nhanh | SV, GV | Tiện ích (Moodle có tìm kiếm; ứng dụng tìm cả việc, thẻ ghi nhớ, SV theo MSSV, không phân biệt dấu) | dữ liệu của chính người gọi: khóa, hoạt động, việc, thẻ (SV); khóa, roster, bài tập, quiz (GV) | Chuẩn hóa NFD bỏ dấu, mọi từ phải khớp, ≤ 20 kết quả nhóm theo loại (mục N13) | `SearchServiceTest` (6), `V2SecurityTest`, `search_test.dart` (1) |
| N14 Tuần của bạn | SV | Khác biệt | `app.study_plan_items`, `app.study_sessions`, `app.flashcard_reviews`, `lms.course_modules_completion`, `lms.logstore_standard_log` (chỉ của SV) | Tuần T2–CN giờ VN so với tuần trước, ẩn dòng không có dữ liệu (mục N14) | `WeeklyReportServiceTest` (3), `V2SecurityTest`, `weekly_report_test.dart` (2) |
| N17 Thành tích | SV | Tiện ích (động lực) | `lms.assign_submission` + `derived.unified_tasks`, `app.flashcard_reviews`, `app.study_plan_items`, `app.study_sessions`, mục tiêu (GoalService), N9 | 6 quy tắc thận trọng, không bảng mới, không xếp hạng (mục N17) | `AchievementServiceTest` (5), `V2SecurityTest`, `achievements_test.dart` (2) |
| N18 Đánh bóng giao diện | SV, GV | Tiện ích | cài đặt trên máy (không nhạy cảm) | Chế độ tối, cỡ chữ 1.3, giới thiệu 3 bước, nhãn truy cập, bộ chọn giờ tiếng Việt (mục N18) | `polish_n18_test.dart` (5) |

Mọi endpoint mới nằm dưới `/api/v1/dev/students/{userId}/…` hoặc `/api/v1/dev/teachers/{teacherId}/…`:
- `PathIdentityAuthorizationManager` chặn người khác: 403.
- Service kiểm tra ghi danh hoặc roster: 404.
- `V2SecurityTest` kiểm 401/403/404 bằng chuỗi filter thật.

## N1. Mô phỏng điểm — Khác biệt

**Mục đích:** Moodle chỉ cho xem điểm đã có. Ứng dụng tính được còn cần bao nhiêu ở các bài chưa chấm để qua môn hoặc đạt mục tiêu, và cho thử "nếu bài X được Y điểm".

**Cây điểm:**
- Gốc là danh mục cha của khóa. Con của gốc gồm các danh mục con, và các bài đặt thẳng ở gốc.
- Bài "ẩn" là bài không có module hiển thị; bài ẩn bị loại.

**Trọng số hiệu dụng:**
- wᵢ = (tỷ phần của nhóm ở gốc) × (tỷ phần của bài trong nhóm).
- Tỷ phần chia đều (Mean of grades). Nếu mọi anh em có `coef` > 0 thì chia theo hệ số.
- Chỉ một phần anh em có hệ số thì chia đều và bật `approximation = true`.
- Tổng mọi wᵢ = 1.

**Điểm hiện tại:**
- Theo kiểu Moodle "chỉ tính bài đã chấm": nhóm không có bài nào chấm thì bị bỏ khỏi gốc, không tính là 0.
- Ví dụ thật, khóa 13 của SV 205: nhóm 1 = (95+92+0)/3 = 62,33; nhóm 2 = (94+0)/2 = 47; hiện tại = 54,67%.

**Điểm cần đạt:**
- need = (mục tiêu − Σ wᵢ·sᵢ của bài đã chấm) / Σ wⱼ của bài chưa chấm.
- Trạng thái:
  - `ACHIEVED`: need ≤ 0.
  - `FEASIBLE`: need ≤ 100.
  - `NOT_FEASIBLE`: need > 100.
  - `NO_REMAINING`: không còn bài chưa chấm.

**Ngưỡng qua môn:**
- Lấy gradepass/grademax chung của các bài; dữ liệu hiện có là 50/100.
- Nếu các bài khác nhau hoặc không có gradepass thì dùng 50% và màn hình ghi "mặc định".

**Mô phỏng:**
- Client tính điểm dự kiến = Σ wᵢ·sᵢ (đã chấm) + Σ wⱼ·slider_j, dùng chính các wᵢ server trả về.
- Đổi mục tiêu thì mọi slider đặt về đúng need.
- Nút "Lưu làm mục tiêu" tạo goal `target_grade` cho khóa đó qua API goals sẵn có.

## N9. Tình trạng học tập của tôi — Khác biệt

**Mục đích:** giảng viên thấy điểm theo dõi và lý do (+40 vì N ngày không truy cập…), còn chính SV thì không. N9 cho SV thấy đúng con số đó, chỉ về bản thân.

**Công thức** (`RiskScore`, dùng chung với `ClassInsightsService`), chặn ở 100:

| Tín hiệu | Ngưỡng | Điểm |
| --- | --- | --- |
| Không truy cập | ≥14 ngày hoặc chưa từng truy cập | +40 |
| Không truy cập | 7–13 ngày | +25 |
| Bài quá hạn | ≥3 bài | +30 |
| Bài quá hạn | 1–2 bài | +15 |
| Tiến độ | <30% | +25 |
| Tiến độ | <60% | +10 |
| Không có hoạt động trong 7 ngày | — | +10 |

**Mức:** Xanh <30, Vàng 30–59, Đỏ ≥60 (cùng mốc với LOW/MEDIUM/HIGH của view).

**Bằng chứng tính nhất quán:**
- Unit test so sánh 5 bộ số với `ClassInsightsService.studentDetails`.
- Trên DB thật, 46/46 hàng có luật Java = `risk_score` lưu = điểm giảng viên thấy.

**"Làm gì để lên Xanh":** tối đa 3 việc, sắp theo số điểm giảm được.
- Vào học (mở hoạt động chưa xong đầu tiên trên LMS). Việc này gộp hai tín hiệu "không truy cập" và "không hoạt động 7 ngày".
- Hoàn thành N bài quá hạn (mở Việc cần làm).
- Hoàn thành thêm K hoạt động để đạt 30%/60% tiến độ, với K = ⌈ngưỡng × tổng/100⌉ − đã xong (mở mục "Nên ôn lại").

## N2. Gợi ý ôn lại theo chương — Khác biệt

**Chương yếu** khi thỏa ít nhất một điều kiện:
- (a) Trung bình các bài đã chấm trong chương < ngưỡng qua.
- (b) Thấp hơn trung bình lớp của cùng các bài đó ≥10 điểm %.
- (c) Có bài tính điểm (assign/quiz) đã quá hạn, chưa hoàn thành, chưa có điểm. Bài "submitted" không tính là quá hạn.

**Riêng tư:** trung bình lớp của một bài chỉ được dùng khi có **≥5 SV** đã có điểm ở bài đó. Khóa nhỏ hơn thì điều kiện (b) không áp dụng và không hiện số của lớp.

**Mức độ yếu** (để xếp hạng) = (ngưỡng − TB chương)⁺ + (TB lớp − TB chương)⁺ + 20 × số bài quá hạn.

**Gợi ý** (≤3 mục trong cùng chương), theo thứ tự:
1. Tài liệu hoặc hoạt động không chấm điểm chưa hoàn thành.
2. Bài tính điểm quá hạn.
3. Bài có điểm thấp nhất, ghi số. Ví dụ "MVP3 - Quiz 3.1: 0,0% (lớp 36,5%)".

Mỗi gợi ý có nút "Mở trên LMS" và "Tạo thẻ ghi nhớ" (mở dialog thêm thẻ của đúng khóa, điền sẵn tên hoạt động).

## N4. Dự báo qua môn của cả lớp — Khác biệt

Chạy engine N1 cho từng SV trong roster, dùng **1 truy vấn điểm cho cả lớp**. Ngưỡng nhóm, với need = trung bình còn cần ở các bài chưa chấm để đạt ngưỡng qua:

| Nhóm | Điều kiện |
| --- | --- |
| Đã chắc qua | need ≤ 0, hoặc đã chấm hết và đạt |
| An toàn | 0 < need ≤ 60 |
| Cần cố gắng | 60 < need ≤ 85 |
| Nguy cơ cao | 85 < need ≤ 100 |
| Không còn khả thi | need > 100, hoặc đã chấm hết mà chưa đạt |
| Chưa có bài tính điểm | khóa không có bài tính điểm |

Khác điểm theo dõi (đo hành vi): ví dụ thật ở MVP3, SV "Le An" có tiến độ 100% nên điểm theo dõi chỉ "trung bình", nhưng điểm TB 0% nên N4 xếp "Nguy cơ cao" (cần 100% hai bài còn lại).

## N3. Vị trí của tôi trong lớp — Khác biệt

**Tính toàn bộ ở server.** Repository chỉ trả cặp (là tôi?, giá trị), không có id, tên hay email.

**Công thức:**
- percentBelow = số bạn khác có giá trị < của tôi / số bạn khác có dữ liệu × 100.
- Trung vị lấy trên cả lớp có dữ liệu.
- Histogram 5 khoảng [0,20), [20,40), [40,60), [60,80), [80,100].

**Ngưỡng ẩn danh:** lớp có < 5 SV có dữ liệu thì `suppressed = true`, chỉ trả sĩ số; UI hiện "Lớp quá nhỏ để so sánh ẩn danh". Dữ liệu hiện có:
- Khóa 13 và 14 có 4 SV, nên bị ẩn.
- MVP3-LEARN có 15 SV (tiến độ) và 10 SV có điểm.

Test khẳng định JSON trả về không có `userid`, `name`, `fullname`, `email`, `student_code`.

## N5. Ôn tập ngắt quãng SM-2 — Khác biệt

**Khác Moodle:** Moodle không có thẻ ghi nhớ cá nhân và không xếp lịch ôn. Ứng dụng tự tính thẻ nào cần ôn hôm nay, thay cho kiểu lật hết một lượt.

**Thuật toán SM-2** (`Sm2.next`, hàm thuần). Bốn nút ứng với chất lượng q: Quên = 1, Khó = 3, Được = 4, Dễ = 5.
- q < 3: repetitions = 0, khoảng cách I = 1 ngày.
- q ≥ 3: repetitions + 1; I = 1 ngày (lần 1), 6 ngày (lần 2), sau đó I = round(I_trước × EF_trước).
- EF' = EF + (0,1 − (5−q)(0,08 + (5−q)·0,02)), làm tròn 2 chữ số (cột numeric(4,2)), tối thiểu 1,3. EF ban đầu 2,5.
- due_at = thời điểm trả lời + I ngày. Thẻ chưa ôn lần nào thì đến hạn ngay. I tối đa 36.500 ngày.
- Ví dụ trả "Được" liên tục: 1 → 6 → 15 → 38 → 95 ngày. Quên ở bất kỳ lúc nào: quay lại sau 1 ngày, EF giảm 0,54.

**Nguồn dữ liệu:** `app.flashcards` của chính SV, chỉ trong khóa đã ghi danh; trạng thái lưu ở `app.flashcard_reviews` (một dòng cho mỗi thẻ và người). Server trả kèm khoảng cách kế tiếp của từng nút để hiển thị trên nút trước khi SV chọn.

**API:** `GET /api/v1/dev/students/{userId}/flashcards/due[?courseId=]`; `POST …/students/{userId}/courses/{courseId}/flashcards/{id}/review` với `{rating}` ∈ {1, 3, 4, 5}. Khóa chưa ghi danh hoặc thẻ không thuộc SV/khóa: 404, không ghi gì.

**UI:** phiên ôn (mặt trước → chạm lật → 4 nút kèm "1 ngày", "6 ngày"… → tổng kết theo từng nút); chip "Hôm nay cần ôn N thẻ" trên dashboard (ẩn khi không có thẻ đến hạn); nút "Bắt đầu ôn tập · N thẻ đến hạn" trong màn thẻ của khóa.

## N6. Kế hoạch học tuần — Khác biệt

**Khác Moodle:** Moodle liệt kê hạn nộp. Ứng dụng biến danh sách đó thành lịch học từng ngày vừa với quỹ thời gian SV tự chọn.

**Đầu vào:** việc trong `derived.unified_tasks` của SV chưa hoàn thành/nộp/làm xong, có hạn, quá hạn hoặc đến hạn trong 14 ngày; số thẻ đến hạn ôn (N5); tối đa 3 gợi ý ôn lại (N2, mục đầu của mỗi chương yếu); quỹ phút/ngày ∈ {30, 60, 90, 120}.

**Thuật toán** (`StudyPlanner.plan`, hàm thuần, kết quả xác định, chân trời 7 ngày từ hôm nay):
- Thời lượng ước lượng: assign 90′, quiz 45′, tài liệu gợi ý 20′, thẻ ôn ⌈1,5′ × số thẻ⌉.
- Thứ tự: việc quá hạn ("Gỡ việc tồn") → thẻ ôn hôm nay → việc có hạn theo hạn sớm nhất → gợi ý ôn lại; hòa thì theo khóa, mã nguồn, tên.
- Mỗi việc đặt vào ngày sớm nhất còn đủ chỗ và trước hạn ít nhất 1 ngày (hạn hôm nay/ngày mai: muộn nhất là hôm nay). Assign không vừa ngày nào thì tách thành 2 phần 45′ ở hai ngày khác nhau.
- Việc có hạn không xếp kịp → danh sách "Quá tải" kèm tên và hạn. Hạn ngoài 7 ngày mà chưa xếp được thì chỉ hoãn (đếm `deferred`). Thẻ ôn và gợi ý là tùy chọn: hết chỗ thì bỏ.
- Tạo lại kế hoạch: xóa các mục `planned` từ hôm nay trở đi (một transaction), giữ mục `done`/`skipped`; phút của mục `done` trừ vào quỹ của ngày đó và vào thời lượng còn lại của việc.

**API:** `POST /api/v1/dev/students/{userId}/study-plan/generate` `{dailyMinutes}`; `GET …/study-plan?from=&to=` (mặc định 7 ngày từ hôm nay, tối đa 31 ngày); `PUT …/study-plan/items/{id}/status` `{status ∈ planned|done|skipped}`. Mục của người khác → 404 (câu UPDATE lọc theo `user_id`), không ghi.

**UI:** màn "Kế hoạch tuần": chọn quỹ 30/60/90/120′, nút "Lập kế hoạch", dải 7 ngày (thanh phút đã xếp/quỹ), danh sách việc theo ngày có checkbox và "Bỏ qua", thẻ cảnh báo quá tải. Thẻ "Hôm nay: N việc · M phút" trên dashboard mở màn này.

## N7. Nhắc học trên điện thoại + cài đặt nhắc — Khác biệt

**Khác Moodle:** Moodle nhắc theo hạn nộp. Ứng dụng nhắc cả theo kế hoạch cá nhân (N6) và theo số thẻ đến hạn ôn (N5), chạy được khi không mở app (thông báo cục bộ đã lên lịch trong hệ điều hành).

**Cài đặt** (`GET/PUT /api/v1/dev/students/{userId}/notification-preferences`, bảng sẵn có `app.notification_preferences`, một dòng mỗi người; chưa có dòng → mặc định của bảng: bật hết, 24 giờ; PUT là cập nhật từng phần + upsert):
- `pushEnabled` (công tắc chung), `assignmentReminder`, `quizReminder` (nhắc hạn), `learningReminder` (nhắc hằng ngày: thẻ ôn + kế hoạch), `reminderBeforeHours` 0–168.
- Giờ nhắc hằng ngày lưu **trên máy** (`shared_preferences`), vì bảng không có cột này và gói V2 chỉ có một migration; không gửi lên server.

**Lịch nhắc** (`planReminders`, hàm thuần trong `lib/core/reminder_schedule.dart`):
- Nhắc hạn: mỗi việc chưa xong có hạn ở tương lai → thời điểm = hạn − N giờ. Hạn đã qua, hoặc thời điểm nhắc đã qua, thì không lên lịch. Tối đa 40 nhắc hạn.
- Nhắc hằng ngày: 7 lần kế tiếp của giờ đã chọn. Lần đầu ghi số thẻ đến hạn; mỗi lần ghi số việc và số phút còn lại trong kế hoạch của đúng ngày đó. Ngày không có gì để nhắc thì bỏ qua.
- Mỗi lần mở app hoặc đổi cài đặt: hủy mọi nhắc cũ rồi lên lịch lại. Nguồn nào lỗi thì coi là rỗng, không chặn nguồn khác.
- Android: `flutter_local_notifications` 23.0.0 + `timezone` 0.11.2 (Asia/Ho_Chi_Minh), `AndroidScheduleMode.inexactAllowWhileIdle` (không cần quyền exact alarm), quyền `POST_NOTIFICATIONS` (Android 13+) xin lúc chạy, `RECEIVE_BOOT_COMPLETED` để lên lịch lại sau khởi động máy.

**UI:** nút chuông trên AppBar trang chủ SV → "Cài đặt nhắc": các công tắc, "Nhắc trước hạn" (1/3/6/12/24/48/72 giờ), "Giờ nhắc hằng ngày", "Gửi thử thông báo", mục "Sắp nhắc" (≤5 nhắc hạn kế tiếp, nhắc hằng ngày đầu tiên; "Không có hạn nộp sắp tới" khi không còn hạn ở tương lai). Mỗi thay đổi được lưu ngay; lưu lỗi thì hoàn tác công tắc.

## N10. Phiên học tập trung (Pomodoro) và mục tiêu phút học — Khác biệt

**Khác Moodle:** Moodle không ghi nhận thời gian tự học. Trước N10, `GoalService` phải từ chối mục tiêu `study_minutes`; nay ứng dụng tự ghi phút tập trung nên mục tiêu này tính được.

**Ghi phiên** (`POST /api/v1/dev/students/{userId}/study-sessions` `{startedAt, endedAt, focusMinutes, courseId?, planItemId?, markPlanItemDone?}`; `StudySessionService.validate` là hàm thuần):
- 1 ≤ focusMinutes ≤ 180; endedAt > startedAt; focusMinutes ≤ số phút nguyên giữa hai mốc + 1.
- Không ở tương lai (cho lệch đồng hồ 1 phút), không cũ hơn 2 ngày.
- courseId phải là khóa SV đã ghi danh, planItemId phải là mục kế hoạch của chính SV; sai thì 404 và không ghi gì. `markPlanItemDone` đặt mục kế hoạch N6 thành `done`.

**Tổng hợp** (`GET …/study-sessions/summary?from=&to=`, mặc định 7 ngày gần nhất, tối đa 62 ngày): phút và số phiên của **mọi** ngày trong khoảng (ngày không học = 0, là số thật vì có ghi phiên), và theo khóa. Ngày tính theo giờ Asia/Ho_Chi_Minh.

**Mục tiêu `study_minutes`:** mục tiêu là số nguyên 1–10.000 phút; tiến độ = tổng phút tập trung từ ngày bắt đầu đến min(ngày kết thúc, hôm nay), lọc theo khóa nếu mục tiêu gắn khóa; có cảnh báo chậm tiến độ như mục tiêu số hoạt động.

**UI:** màn "Học tập trung": chọn 25/5 hoặc 50/10, chọn việc trong kế hoạch hôm nay (tự chọn khóa của việc đó) và/hoặc khóa học; vòng đếm ngược; "Kết thúc và lưu" (lưu số phút đã học, dưới 1 phút không lưu), "Hủy phiên"; hết giờ thì tự lưu rồi chuyển sang nghỉ. Thời gian còn lại luôn tính từ mốc bắt đầu và đồng hồ, không cộng dồn từng tick, nên đúng cả khi app chạy nền. Lưu lỗi thì giữ phiên và có "Thử lưu lại". Lối vào: thẻ "Học tập trung · Hôm nay N phút" trên dashboard, nút đồng hồ và mục "Học tập trung" trong Kế hoạch tuần. Màn Phân tích có biểu đồ "Phút học 7 ngày".

## N8. Nhắc riêng một sinh viên + xuất danh sách cần hỗ trợ — Tiện ích

**Khác Moodle:** Moodle có nhắn tin nhưng GV phải tự tra số liệu rồi tự viết. Ứng dụng soạn sẵn lời nhắc từ đúng số liệu của SV đó và xuất danh sách cần hỗ trợ kèm dự báo qua môn (N4) và ghi chú gần nhất.

**Nhắc riêng:** nút "Nhắc riêng" ở màn chi tiết SV và ở từng SV trong "Dự báo qua môn" (N4). Composer mở với đúng 1 người nhận ("Nhắc riêng <tên>"), có các mẫu (`reminderTemplates`, hàm thuần), mẫu chỉ hiện khi dữ kiện tồn tại:
- **Quá hạn** (khi có bài quá hạn): số bài + tối đa 3 tên bài.
- **Lâu không truy cập** (khi ≥ 7 ngày): số ngày từ `days_since_last_activity`.
- **Điểm thấp** (khi điểm TB các bài đã chấm < 50%): điểm TB thật.
- **Chung** (luôn có).
GV sửa được tiêu đề và nội dung trước khi gửi. Backend dùng lại `POST …/teachers/{teacherId}/courses/{courseId}/reminders` (đã nhận danh sách `student_ids` tùy ý): kiểm roster; **SV ngoài lớp → 404, không ghi gì** (trước V2-N8 là 400). Mỗi lần nhắc ghi `app.notifications` cho SV và lưu `app.teacher_notes` "Đã gửi nhắc nhở: …" để mục "Hiệu quả hỗ trợ" theo dõi.

**Xuất CSV:** nút "Xuất danh sách cần hỗ trợ" ở tab Phân tích của khóa. SV thuộc nhóm "Cần hỗ trợ"/"Cần theo dõi", sắp theo điểm theo dõi giảm dần. Cột: MSSV, Họ tên, Điểm theo dõi, Lý do (các tín hiệu cảnh báo), Dự báo qua môn (N4), Ghi chú gần nhất (`GET /teachers/{id}/notes?courseId=`). RFC 4180 (dấu phẩy/ngoặc kép/xuống dòng được bọc), UTF-8 có BOM để Excel hiện tiếng Việt, ô bắt đầu bằng = + - @ được thêm dấu ' để không thành công thức. Chia sẻ bằng `share_plus` 13.3.1 (`XFile.fromData`, không cần ghi file ra bộ nhớ ngoài). Dự báo hoặc ghi chú tải lỗi thì cột đó để trống, danh sách vẫn xuất.

## N16. Phân tích bài kiểm tra (giảng viên) — Tiện ích

**Khác Moodle:** Moodle web có báo cáo thống kê quiz nhưng là bảng số trên máy tính. Ứng dụng tóm mỗi quiz thành vài con số và cờ cảnh báo kèm nút hành động ngay trên điện thoại.

**Dữ liệu:** danh sách quiz của khóa từ `derived.teacher_quiz_monitoring` (lọc theo GV + khóa); với mỗi SV **trong roster** lấy lượt làm cuối (`lms.quiz_attempts`, mọi trạng thái). Điểm % một lượt = `quiz_attempts.sumgrades / quiz.sumgrades × 100` (role chạy không có quyền `lms.quiz_grades`); thời gian làm = `timefinish − timestart`.

**Mỗi quiz** (`QuizInsightsService.analyze`, hàm thuần):
- Histogram 5 khoảng 20% (100% vào khoảng cuối) trên các lượt đã nộp có điểm; điểm TB.
- Thời gian làm trung vị (lượt đã nộp có đủ mốc thời gian).
- Chưa làm = SV roster không có lượt nào; tỷ lệ = chưa làm / sĩ số.
- Cờ: **Quá khó** khi TB < 50% và ≥ 3 lượt có điểm; **Nhiều sinh viên bỏ** khi chưa làm ≥ 40%; **Làm quá nhanh** khi trung vị < 20% thời gian giới hạn, chỉ xét khi quiz có `timelimit`.

**API:** `GET /api/v1/dev/teachers/{teacherId}/courses/{courseId}/quiz-insights` (khóa không thuộc GV → 404). Trả số tổng hợp; danh sách id SV chưa làm (chỉ id trong roster mà GV vốn đã xem được) để dùng cho nút nhắc.

**UI:** mục "Phân tích bài kiểm tra" trong tab Phân tích của khóa: mỗi quiz một thẻ (quiz có cờ lên đầu), chip cờ, các số liệu, biểu đồ cột 5 khoảng (2 khoảng dưới 40% tô màu cảnh báo), nút "Nhắc N SV chưa làm" (mở composer N8 với lời nhắc theo bài) và "Mở trên LMS".

## N15. Bản đồ nhiệt tương tác của lớp (giảng viên) — Khác biệt (trên mobile)

**Đối chiếu trước khi làm:** tab Phân tích đã có `ActivityHeatmapSection` ("Lịch sử vào học theo tuần", có từ trước gói V2) với gần đủ yêu cầu N15: ma trận SV × tuần, chỉ SV trong roster, xếp SV "ngừng học"/"chưa vào học" và im lặng lâu nhất lên đầu, bấm tên mở chi tiết SV. N15 **không làm lại** phần này mà chỉ bổ sung phần còn thiếu:
- **4 mức màu** thay cho dải màu liên tục: mức = ⌈4 × số sự kiện / tuần cao nhất của lớp⌉ (0 khi không có sự kiện), cùng một quy tắc ở server (`ClassInsightsService.heatLevel`) và app (`heatLevel`); chú thích 5 ô (xám + 4 mức) và ghi rõ cách chia trong "Cách tính".
- **Endpoint riêng** `GET /api/v1/dev/teachers/{teacherId}/courses/{courseId}/engagement-heatmap?weeks=8` (4–16 tuần; khóa không thuộc GV → 404) dùng **chung** hàm `activityHeatmap` với class-insights nên hai nơi luôn khớp; trả thêm `levels` từng ô. Dùng cho E2.
- Tuần tính theo đồng hồ của server; trên DB demo đã dời ngày (DOI_NGAY_DEMO) nên 8 tuần gần nhất có dữ liệu.

**Nguồn:** `lms.logstore_standard_log` (userid, courseid, timecreated, bỏ log ẩn danh). Không cộng thêm `course_modules_completion` vì Moodle đã ghi sự kiện cập nhật hoàn thành vào chính log này — cộng thêm sẽ đếm trùng.

## E2. Hiệu năng API (số liệu cho Chương 5)

**Cách đo** (`tools\Measure-Api.ps1`, không cài công cụ mới): đăng nhập demo 1 lần mỗi vai trò; mỗi endpoint 10 lần khởi động không tính + 200 lần đo, tuần tự (1 người dùng), chỉ GET (không ghi CSDL); thời gian = gửi request đến khi nhận xong body; p50/p95 theo nearest-rank. Máy: Intel Core i7-1355U (10 nhân/12 luồng), RAM 15,7 GiB, Windows 11; backend Spring Boot + PostgreSQL 18 cục bộ; DB `lms_mobile_group_demo`. Kết quả gốc: `D:\DLU-LMS\Artifacts\v2\perf-20261110-130614.csv` (+ `-machine.txt`). **Đo cục bộ, 1 người dùng** — không phải tải đồng thời.

| Endpoint (LMS) | Vai trò | p50 (ms) | p95 (ms) | max (ms) | Lỗi |
| --- | --- | ---: | ---: | ---: | ---: |
| dashboard | SV | 6,4 | 10,2 | 33,6 | 0 |
| tasks | SV | 5,5 | 8,5 | 13,2 | 0 |
| courses | SV | 3,6 | 5,3 | 17,6 | 0 |
| grades (khóa 14) | SV | 2,4 | 3,3 | 5,9 | 0 |
| grade-forecast N1 | SV | 5,0 | 9,2 | 14,3 | 0 |
| study-recommendations N2 | SV | 9,3 | 15,6 | 17,7 | 0 |
| learning-health N9 | SV | 9,9 | 20,8 | 27,1 | 0 |
| study-plan N6 | SV | 2,2 | 3,4 | 6,1 | 0 |
| flashcards/due N5 | SV | 1,8 | 3,1 | 6,5 | 0 |
| teacher courses | GV | 3,8 | 8,6 | 10,7 | 0 |
| grade-forecast lớp N4 | GV | 10,9 | 21,2 | 41,3 | 0 |
| engagement-heatmap N15 | GV | 13,9 | 28,7 | 43,5 | 0 |

Không endpoint nào có p95 > 500 ms → không đề xuất index.

**Portal (V3, đo 09/11, dữ liệu mô phỏng, xem HANDOFF "V3 — Chạy thật API"):** mỗi lời gọi Portal chưa cache 140–255 ms; endpoint ghép nhiều lời gọi khi chưa cache 1,1–2,5 s (summary, rèn luyện 6 học kỳ, lớp cố vấn dò 6 học kỳ; lần đo lại 10/11 trên DB demo: 0,97 / 1,61 / 2,53 s); khi đã cache 2–27 ms (TTL 10 phút). Vì vậy độ trễ người dùng cảm nhận ở màn Học vụ chủ yếu do Portal ở lần mở đầu, còn các màn LMS đều dưới 30 ms ở p95.

## N11. Xem khi mất mạng — Tiện ích

**Nhãn trung thực:** Moodle App có chế độ offline. Ứng dụng chỉ lưu các màn tổng hợp riêng của mình để xem lại khi mất mạng.

- Lưu phản hồi GET thành công của: dashboard, việc cần làm, khóa học, điểm và mô phỏng điểm của khóa, kế hoạch tuần, thẻ ghi nhớ của khóa, thẻ đến hạn (`isOfflineCacheable`, danh sách cố định). Lưu bằng `shared_preferences` kèm thời điểm lưu. Không lưu Portal và không lưu màn giảng viên.
- Lỗi mạng hoặc quá thời gian → trả dữ liệu đã lưu và hiện banner "Đang ngoại tuyến · dữ liệu lúc 21:30 16/11" ở đầu ứng dụng SV. Không có bản lưu → báo lỗi kết nối như cũ. Đọc bản lưu có giới hạn 2 giây để không treo màn hình.
- Khi đang ngoại tuyến mọi thao tác ghi bị chặn với thông báo "Đang ngoại tuyến nên chưa lưu được thay đổi…". Một GET thành công tắt trạng thái ngoại tuyến.
- **Bảo mật:** khóa lưu là đường dẫn API (đã chứa userId); không lưu token; xóa toàn bộ khi đổi vai trò (`demoLogin`) hoặc đăng xuất.

## N12. Lịch tổng hợp và xuất sang Google Calendar — Tiện ích

**Nhãn trung thực:** Moodle có lịch sự kiện. Ứng dụng gộp thêm kế hoạch học (N6) và buổi điểm danh vào cùng một lịch, và xuất được file .ics kèm nhắc theo cài đặt N7.

**API:** `GET /api/v1/dev/students/{userId}/calendar?from=&to=` (mặc định tháng hiện tại, tối đa 62 ngày). Gộp: hạn nộp trong `derived.unified_tasks` của SV; mục kế hoạch N6 (bỏ mục "skipped"); buổi điểm danh `lms.attendance_sessions` của các khóa SV đã ghi danh (có giờ bắt đầu và kết thúc theo `duration`). Mỗi sự kiện có `uid` ổn định (`deadline-assign-<id>`, `plan-<id>`, `attendance-<id>` + `@dlu-lms-group`) nên nhập lại vào Google Calendar sẽ cập nhật chứ không nhân đôi.

**UI:** màn "Lịch học" (nút lịch trên AppBar trang chủ SV): lưới tháng, mỗi ngày có chấm màu theo loại (đỏ hạn nộp, xanh lá kế hoạch, xanh dương buổi học), bấm ngày ra danh sách việc kèm giờ, khóa, "Mở trên LMS"; chuyển tháng trước/sau.

**Xuất .ics** (`buildIcs`, hàm thuần): RFC 5545, UTF-8, CRLF, gập dòng ≤ 75 byte không cắt giữa ký tự tiếng Việt, escape `\ ; , xuống dòng`. Giờ ghi dạng UTC (`…Z`), ứng dụng lịch tự đổi về giờ máy (Asia/Ho_Chi_Minh) — không cần khối VTIMEZONE; mục kế hoạch là sự kiện cả ngày (`VALUE=DATE`, theo ngày địa phương). Hạn nộp có `VALARM` trước N giờ = `reminderBeforeHours` của N7 (24 giờ nếu không đọc được cài đặt; không có nhắc nếu SV tắt thông báo). Mục đã xong không xuất. Chia sẻ bằng `share_plus` để mở trong Google Calendar.

## N13. Tìm kiếm nhanh (cả hai vai trò) — Tiện ích

**Nhãn trung thực:** Moodle có tìm kiếm. Ứng dụng tìm trong dữ liệu tổng hợp của chính người dùng, không phân biệt dấu tiếng Việt.

**API:** `GET /api/v1/dev/students/{userId}/search?q=` và `GET /api/v1/dev/teachers/{teacherId}/search?q=`; q dài 2–100 ký tự (sai → 400).
- **SV** tìm trong: khóa đã ghi danh, hoạt động/tài liệu (`student_course_learning_items`, kèm chương), việc cần làm, thẻ ghi nhớ của mình (mặt trước + mặt sau).
- **GV** tìm trong: khóa giảng dạy, SV trong roster (tên hoặc MSSV), bài tập, quiz.

**So khớp** (`SearchService`, hàm thuần `fold` + `rank`): chuẩn hóa NFD, bỏ dấu kết hợp, đ→d, chữ thường, gộp khoảng trắng — "nguyen" khớp "Nguyễn". Mọi từ trong q phải xuất hiện; kết quả bắt đầu bằng từ đầu tiên xếp trước; nhóm theo loại; tối đa 20 (trả kèm tổng số và `truncated`).

**An toàn:** dữ liệu được lấy bằng các truy vấn sẵn có, chỉ theo id của người gọi (đã qua `PathIdentityAuthorizationManager`); **chuỗi q không bao giờ đi vào SQL**, nên `' OR 1=1 --` chỉ là một chuỗi không khớp gì (có test).

**UI:** nút kính lúp trên AppBar trang chủ SV và GV → màn tìm kiếm (gõ ≥ 2 ký tự, chờ 300 ms mới gọi), kết quả nhóm theo loại; bấm khóa/việc/thẻ mở chi tiết khóa, bấm SV mở chi tiết SV, có "Mở trên LMS" khi có link.

## N14. "Tuần của bạn" — báo cáo tuần cá nhân — Khác biệt

**Khác Moodle:** Moodle không tổng hợp cho SV một tuần học của chính mình (kế hoạch, thời gian tự học, ôn thẻ) và không so với tuần trước.

**API:** `GET /api/v1/dev/students/{userId}/weekly-report[?week=yyyy-MM-dd]` (tuần chứa ngày đó; mặc định tuần hiện tại). Tuần = thứ Hai → Chủ nhật theo giờ Asia/Ho_Chi_Minh, so với tuần liền trước.

| Dòng | Nguồn |
| --- | --- |
| Việc trong kế hoạch đã xong (x/y) | `app.study_plan_items` (N6), bỏ mục "skipped" |
| Phút học tập trung | `app.study_sessions` (N10) |
| Thẻ ghi nhớ đã ôn | `app.flashcard_reviews` (N5) — chỉ lưu lần ôn **gần nhất** mỗi thẻ, nên thẻ ôn ở cả hai tuần chỉ tính ở tuần sau |
| Hoạt động LMS hoàn thành | `lms.course_modules_completion` (thời điểm Moodle cập nhật trạng thái) |
| Ngày có vào học | `lms.logstore_standard_log` |
| Chuỗi ngày học | cùng công thức streak của màn Phân tích |

**Chỉ dữ liệu thật:** dòng nào cả tuần này và tuần trước đều không có dữ liệu thì **ẩn**, không hiện 0. **Không có dòng "điểm mới nhận"**: các dòng điểm mà ứng dụng được đọc (`derived.student_grade_overview`) không có mốc thời gian, nên không biết điểm nhận vào tuần nào.

**UI:** thẻ "Tuần của bạn" đầu màn Phân tích (ẩn khi không có gì): giá trị, mũi tên ↑/↓/– so với tuần trước kèm số tuần trước, chuỗi ngày học. Nút "Chia sẻ": chụp thẻ thành PNG bằng `RepaintBoundary` (×3) và chia sẻ qua `share_plus`.

## N17. Thành tích — Tiện ích (động lực)

6 huy hiệu tính từ sự kiện thật, **không có bảng mới**, chỉ chính SV xem (không có bảng xếp hạng). Quy tắc **thận trọng**: khi lịch sử lưu trong CSDL không đủ để chứng minh thì không trao huy hiệu.

| Huy hiệu | Quy tắc | Ngày đạt | Giới hạn dữ liệu |
| --- | --- | --- | --- |
| Đúng hạn 3 lần liền | 3 bài tập liên tiếp (theo hạn, chỉ hạn đã qua) có bài nộp `submitted` với `timemodified` ≤ hạn | ngày nộp của bài thứ 3 | sửa bài sau hạn bị tính là trễ |
| Ôn thẻ 7 ngày liền | 7 ngày liên tiếp trong các ngày có lần ôn **gần nhất** của thẻ | ngày thứ 7 | chỉ lưu lần ôn gần nhất mỗi thẻ → là cận dưới, có thể chưa trao dù SV đã ôn đủ |
| Tuần kế hoạch 80% | một tuần T2–CN có ≥ 80% mục kế hoạch (bỏ "skipped") đã xong | Chủ nhật của tuần (hoặc hôm nay nếu là tuần hiện tại) | — |
| 300 phút tập trung | tổng phút N10 ≥ 300 | ngày tổng đạt 300 | — |
| Đạt mục tiêu | có mục tiêu ở trạng thái "đã đạt" | không ghi (ngày đạt không được lưu) | — |
| Không còn khóa Đỏ | đang có khóa và không khóa nào ở mức Đỏ (N9) | không ghi | **khác đặc tả** "hết Đỏ ở một khóa": không lưu lịch sử mức N9 nên không phát hiện được lúc chuyển từ Đỏ sang mức khác; dùng trạng thái hiện tại |

**API:** `GET /api/v1/dev/students/{userId}/achievements`: 6 huy hiệu (đã đạt?, ngày đạt nếu biết, tiến độ/mục tiêu). **UI:** thẻ "Thành tích · Đã đạt x/6" trong màn Phân tích → màn "Thành tích" (đã đạt lên đầu kèm ngày; chưa đạt có thanh tiến độ).

## N18. Đánh bóng giao diện — Tiện ích

- **Chế độ tối:** `AppTheme.darkTheme` (cùng màu gốc, bề mặt theo ColorScheme tối); mặc định theo hệ thống; nút "Giao diện sáng/tối" (Theo hệ thống / Sáng / Tối) ở màn chọn vai trò, lưu trên máy (`AppSettings`, `shared_preferences`).
- **Cỡ chữ lớn:** widget test ở `textScaler` 1.3, màn 360 dp, cả sáng và tối cho 5 màn mới (Kế hoạch tuần, Học tập trung, Cài đặt nhắc, Lịch học, Thành tích); các màn cũ đã có test 1.5/1.8 từ trước. Test tìm ra dải 7 ngày của Kế hoạch tuần tràn 15 px ở 1.3 → chiều cao dải nay tăng theo cỡ chữ.
- **Giới thiệu 3 bước** lần đầu chọn vai trò: "Mô phỏng điểm · Kế hoạch tuần · Ôn thẻ thông minh", có "Bỏ qua"; cờ đã xem lưu trên máy.
- **Nhãn truy cập:** rà mọi `IconButton` — nút duy nhất thiếu nhãn (xóa ngày kết thúc mục tiêu) đã có tooltip; các nút biểu tượng mới đều có tooltip/semanticLabel.
- **Bộ chọn giờ tiếng Việt:** "Chọn giờ", "Nhập giờ", "Giờ", "Phút" (trước đây hiện "Select time").

## Dữ liệu demo dời ngày (DOI_NGAY_DEMO=CO)

- DB riêng `lms_mobile_group_demo`, restore từ cùng file dump (SHA-256 không đổi). DB gốc `lms_mobile_group_dev` giữ nguyên.
- `database/demo/shift_demo_dates.sql` cộng cùng một số ngày nguyên vào 71 cột thời gian epoch có liệt kê rõ của schema `lms`. Độ dời chọn sao cho hạn nộp muộn nhất rơi vào ngày mục tiêu + 5 ngày.
- Không dời giá trị 0 ("chưa đặt") và không dời các cột thời lượng hoặc cờ.
- Ước tính với ngày mục tiêu 08/11/2026: dời 52 ngày, 7 hạn nộp nằm trong 7 ngày tới.
- Backend chọn DB qua `.local\backend.json` (`tools\Set-LocalBackendDatabase.ps1 -Target demo|dev`).
- Ghi trong báo cáo: "dữ liệu mẫu đã dời mốc thời gian để minh họa".
