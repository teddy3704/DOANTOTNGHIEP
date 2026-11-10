# Dữ kiện để so sánh — mỗi chức năng của ứng dụng (cũ, V2, V3)

Mục đích: cung cấp dữ kiện kiểm chứng được (nguồn, màn hình, endpoint, test, lợi ích) để phiên cloud dựng bảng
"Moodle web / Moodle App / Portal ĐT / Ứng dụng nhóm". **Tài liệu này không khẳng định Moodle hay Portal có hay không có chức năng
nào**; việc đó do phiên cloud kiểm chứng.

Nguồn: **LMS** = bản sao CSDL Moodle (schema `lms`, `derived`, chỉ đọc); **app** = schema `app` của ứng dụng; **Portal** = API
Portal Online DLU Proxy (dữ liệu mô phỏng). Endpoint viết tắt: `S/` = `/api/v1/dev/students/{userId}/`, `T/` =
`/api/v1/dev/teachers/{teacherId}/`. Test: BE = backend (JUnit), FE = Flutter.

Trạng thái 10/11/2026 (hiện hành): chức năng cũ + V2 N1–N18, O1, E2 + V3 P0–P8 đã cài đặt, qua gate và chạy trên emulator với DB demo. Lịch sử: 09/11/2026 mới có N1, N9, N2, N4, N3, N5 và P0–P8.

## Sinh viên

| Chức năng | Nguồn | Màn hình | Endpoint | Test | Lợi ích cụ thể cho người dùng |
| --- | --- | --- | --- | --- | --- |
| Trang chủ: hồ sơ học tập, tiến độ, chuyên cần | LMS | Trang chủ | `S/dashboard` | BE `AcademicProfileApiTest`, `DevStudentControllerTest`; FE `day2_integration_test`, `student_overview_details_test` | Một màn thấy tiến độ và chuyên cần mọi khóa |
| Ưu tiên hôm nay, Việc cần làm (lọc, sắp theo hạn) | LMS (`derived.unified_tasks`) | Trang chủ, Việc cần làm | `S/tasks` | FE `task_logic_test`, `student_analytics_task_status_test` | Gom bài tập/quiz mọi khóa thành một danh sách theo hạn |
| Tiếp tục học | LMS | Trang chủ | `S/continue-learning` | FE `day2_integration_test`, `ux_polish_test` | Mở lại đúng hoạt động đang dở |
| Khóa học: nội dung, điểm, nhóm điểm, chuyên cần, việc của khóa | LMS | Khóa học › chi tiết | `S/courses`, `S/courses/{c}/learning-items`, `/grades`, `/grade-categories`, `/attendance`, `/tasks` | FE `student_course_detail_test`, `course_navigation_test`, `academic_ui_test` | Xem điểm và chuyên cần từng khóa trên điện thoại |
| Phân tích: streak, biểu đồ tuần | LMS | Phân tích | `S/insights`, `S/courses/{c}/analytics` | BE `InsightsApiTest`; FE `student_analytics_task_status_test` | Thấy nhịp học theo tuần |
| Mục tiêu học tập | app `learning_goals` | Mục tiêu | `S/goals` | BE `InsightsApiTest`, `LearningWriteSecurityTest`; FE `learning_support_test` | Đặt và theo dõi mục tiêu tiến độ/điểm |
| Nhật ký kèm mức hiểu bài | app `learning_reflections` | Nhật ký | `S/reflections` | BE `ReflectionApiTest`; FE `reflections_api_test` | Ghi lại phần chưa hiểu, gợi ý tạo thẻ ghi nhớ |
| Thẻ ghi nhớ (CRUD) | app `flashcards` | Thẻ ghi nhớ | `S/courses/{c}/flashcards` | BE `FlashcardApiTest`; FE `flashcard_ui_test` | Tự soạn thẻ theo khóa |
| Thông báo | app `notifications` | Thông báo | `S/notifications` | FE `teacher_reminder_notifications_test` | Nhận nhắc nhở của giảng viên |
| **N1** Mô phỏng điểm, điểm cần đạt | LMS | Khóa › Mô phỏng điểm | `S/courses/{c}/grade-forecast` | BE `GradeForecastServiceTest` 13, `V2SecurityTest`; FE `grade_forecast_test` | Biết cần bao nhiêu điểm ở bài còn lại để qua môn/đạt mục tiêu |
| **N9** Tình trạng học tập của tôi | LMS | Thẻ trang chủ, Tình trạng | `S/learning-health`, `S/courses/{c}/learning-health` | BE `LearningHealthServiceTest` 6; FE `learning_health_test` | Thấy cùng điểm theo dõi giảng viên thấy, kèm việc cần làm để lên Xanh |
| **N2** Gợi ý ôn lại theo chương | LMS | Trang chủ, khóa | `S/study-recommendations`, `S/courses/{c}/study-recommendations` | BE `StudyRecommendationServiceTest` 6; FE `study_recommendation_test` | Biết chương yếu và tài liệu nên ôn |
| **N3** Vị trí trong lớp (ẩn danh) | LMS | Khóa | `S/courses/{c}/peer-comparison` | BE `PeerComparisonServiceTest` 6; FE `peer_comparison_test` | So với lớp mà không lộ ai; ẩn khi lớp < 5 SV |
| **N5** Ôn tập ngắt quãng SM-2 | app `flashcards`, `flashcard_reviews` | Chip trang chủ, phiên ôn | `S/flashcards/due`, `S/courses/{c}/flashcards/{id}/review` | BE `Sm2Test` 16, `FlashcardReviewServiceTest` 8; FE `flashcard_review_test` 12 | Chỉ ôn thẻ đến hạn; mỗi nút cho biết lần ôn kế tiếp |
| **P1** Bảng điểm và GPA | Portal | Thẻ GPA đầu trang chủ; Học vụ › Bảng điểm | `S/portal/summary`, `S/portal/transcript` | BE `AcademicEngineTest`, `StudentPortalServiceTest`; FE `portal_test` | Thấy GPA tích lũy, tín chỉ và bảng điểm cả khóa ngay trong app học tập |
| **P2** Tiến độ CTĐT | Portal + LMS | Học vụ › Chương trình | `S/portal/program` | như trên | Biết còn thiếu bao nhiêu TC bắt buộc, học phần nào đủ điều kiện học kỳ tới, môn nào đang học trên LMS |
| **P3** Mô phỏng GPA, mục tiêu xếp loại | Portal + LMS (N1) | Học vụ › Mô phỏng GPA | `S/portal/gpa-simulation` | như trên; FE kiểm số khớp backend | Biết phong độ hiện tại trên LMS đưa GPA tích lũy tới đâu và cần trung bình bao nhiêu cho từng xếp loại |
| **P4** Điểm rèn luyện | Portal | Học vụ › Rèn luyện | `S/portal/conduct` | như trên | Xem điểm rèn luyện qua các học kỳ |
| **P5** Quyết định học vụ | Portal | Học vụ › Quyết định | `S/portal/decisions` | như trên | Thấy cảnh báo học vụ và đi thẳng tới mức cần đạt |
| **P7** Nguồn dữ liệu và quyền riêng tư | cấu hình server | Học vụ › Nguồn dữ liệu | `S/portal/sources` | FE `portal_test` | Biết app dùng dữ liệu gì, không dùng gì và vì sao |
| **N6** Kế hoạch học tuần | LMS + app `study_plan_items` | Trang chủ › Hôm nay; Kế hoạch tuần | `S/study-plan`, `S/study-plan/generate`, `S/study-plan/items/{id}/status` | BE `StudyPlannerTest`, `StudyPlanServiceTest`; FE `study_plan_test` | Biết mỗi ngày học gì, bao lâu, theo hạn nộp thật; cảnh báo khi quá tải |
| **N7** Nhắc học trên điện thoại | LMS + app `notification_preferences` | Cài đặt nhắc | `S/notification-preferences` | BE `NotificationPreferenceServiceTest`; FE `reminder_test` | Thông báo trước hạn nộp và nhắc ôn hằng ngày khi đã đóng app; xin quyền Android 13 lúc bật |
| **N10** Học tập trung + mục tiêu phút | app `study_sessions` | Học tập trung | `S/study-sessions`, `S/study-sessions/summary` | BE `StudySessionServiceTest`; FE `focus_timer_test` | Đếm giờ đúng khi app chạy nền, biểu đồ phút học 7 ngày |
| **N11** Xem khi mất mạng | bộ nhớ máy | Banner ngoại tuyến | (các GET tóm tắt) | FE `offline_cache_test` | Vẫn xem trang chủ, việc, kế hoạch khi mất mạng; khóa ghi; tách theo người dùng và môi trường |
| **N12** Lịch tổng hợp + .ics | LMS + app | Lịch học (tháng/tuần) | `S/calendar` | BE `StudentCalendarServiceTest`; FE `calendar_ics_test` | Hạn nộp, kế hoạch, buổi học trên một lịch; xuất sang Google Calendar |
| **N13** Tìm kiếm nhanh | LMS + app | Tìm kiếm | `S/search` | BE `SearchServiceTest`; FE `search_test` | Gõ không dấu vẫn ra khóa, việc, tài liệu, thẻ; mở thẳng khóa |
| **N14** Tuần của bạn | LMS + app | Thẻ trang chủ | `S/weekly-report` | BE `WeeklyReportServiceTest`; FE `weekly_report_test` | So với tuần trước, chuỗi ngày học; chia sẻ ảnh |
| **N17** Thành tích | LMS + app | Thành tích | `S/achievements` | BE `AchievementServiceTest`; FE `achievements_test` | 6 huy hiệu tính từ sự kiện thật, có tiến độ |
| **N18** Giao diện | máy | Mọi màn | — | FE `polish_n18_test`, `final_f2_test` | Chế độ tối, chữ lớn 1.3, màn 320–390 dp, giới thiệu 3 bước |

## Giảng viên

| Chức năng | Nguồn | Màn hình | Endpoint | Test | Lợi ích cụ thể cho người dùng |
| --- | --- | --- | --- | --- | --- |
| Trợ lý giảng dạy, việc cần làm tuần này | LMS | Trang chủ GV | `T/courses`, `T/courses/{c}/analytics` | FE `teacher_analytics_drilldown_test` | Một màn biết SV cần chú ý, bài cần chấm, hạn sắp tới |
| Danh sách SV có lọc, điểm theo dõi kèm lý do | LMS | Khóa › Sinh viên | `T/courses/{c}/students`, `/students/{u}` | BE `InsightsApiTest`; FE `risk_action_flow_test` | Biết vì sao SV bị cảnh báo (+40 vì không truy cập …) |
| Theo dõi bài tập và quiz | LMS | Khóa › Bài tập, Quiz | `T/courses/{c}/assignments`, `/quizzes` (+ `/students`) | FE `teacher_analytics_drilldown_test` | Thấy ai chưa nộp/chưa làm |
| Hiệu quả hỗ trợ, nhắc nhóm | LMS + app | Khóa › Phân tích | `T/courses/{c}/class-insights`, `/reminders` | BE `InsightsApiTest`; FE `teacher_reminder_notifications_test` | Nhắc nhóm SV và xem kết quả sau nhắc |
| Ghi chú SV | app `teacher_notes` | Ghi chú | `/api/v1/teachers/{t}/notes` | BE `TeacherNoteSecurityTest` | Lưu ghi chú hỗ trợ theo SV |
| **N4** Dự báo qua môn của lớp | LMS | Khóa › Dự báo | `T/courses/{c}/grade-forecast` | BE `TeacherForecastTest`; FE `class_forecast_test` | Nhóm SV theo mức điểm cần đạt để ưu tiên hỗ trợ |
| **N8** Nhắc riêng 1 SV + xuất CSV | LMS + app `notifications`, `teacher_notes` | Khóa › SV › Nhắc riêng | `T/courses/{c}/reminders` (1 SV) | BE `TeacherReminderService` (V2SecurityTest); FE `remind_one_test` | Mẫu nhắc theo lý do thật; ngoài roster → 404 |
| **N13** Tìm kiếm nhanh | LMS | Tìm kiếm | `T/search` | BE `SearchServiceTest` | Tìm SV trong roster theo tên không dấu/MSSV, bài tập, quiz |
| **N15** Bản đồ nhiệt tương tác | LMS | Khóa › Phân tích | `T/courses/{c}/engagement-heatmap` | FE `heatmap_levels_test` | Thấy tuần/ngày lớp ít hoạt động (4 mức màu) |
| **N16** Phân tích bài kiểm tra | LMS | Khóa › Quiz | `T/courses/{c}/quiz-insights` | BE `QuizInsightsServiceTest`; FE `quiz_insights_test` | Cờ quá khó / nhiều SV bỏ / làm quá nhanh cho từng câu |
| **P6** Lớp cố vấn học tập | Portal + LMS (N9) | Trang chủ GV › Lớp cố vấn | `T/portal/advisor/classes`, `/classes/{lop}`, `/classes/{lop}/students/{stt}`, `/classes/{lop}/export` | BE `AdvisorPortalServiceTest` 8, `PortalSecurityTest`; FE `portal_test` | Một màn: kết quả cả lớp cố vấn, ai cần quan tâm, kèm tín hiệu học tập trên LMS của SV trong khóa mình dạy; ẩn danh khi trình chiếu |
| **P7** Nguồn dữ liệu | cấu hình server | Lớp cố vấn › Nguồn dữ liệu | `T/portal/sources` | FE `portal_test` | Như bên SV |

## Bảo mật và vận hành (dùng chung)

| Hạng mục | Cài đặt | Bằng chứng |
| --- | --- | --- |
| Danh tính theo đường dẫn | `PathIdentityAuthorizationManager`: userId đường dẫn = userId token; sai → 403 | BE `V2SecurityTest`, `PortalSecurityTest`, `SecurityVulnerabilityTest` |
| Ghi danh/roster | Service kiểm tra; không thuộc → 404 | các `*SecurityTest`, `*ServiceTest` |
| Runtime DB tối thiểu quyền | role `lms_group_app`: SELECT lms/derived, ghi bảng app được cấp, không DDL | báo cáo quyền 09/11 (HANDOFF) |
| Portal privacy by design | allow-list trường, không miễn giảm học phí, không lưu CSDL, lọc theo người gọi, ẩn danh | `FEATURES_V3.md` mục Quyền riêng tư; BE `StudentPortalServiceTest`, `PortalClientTest` (log) |
| Hiệu năng Portal | cache 10 phút (server) + 5 phút (client) | E2: chưa cache 140–255 ms/lời gọi; có cache 2–27 ms |

Sơ đồ chi tiết: `docs/diagrams/01-context.mmd` … `11-activity-forecast.mmd` (mỗi file một ý).
