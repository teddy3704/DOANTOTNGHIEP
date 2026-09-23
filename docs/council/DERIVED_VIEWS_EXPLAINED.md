# 20 read model derived cần giải thích

Danh sách khớp chính xác 20 câu `CREATE VIEW derived.*` trong schema nhóm. “Nguồn” dưới đây nêu nhóm dữ liệu chính để thuyết trình, không thay DDL của từng view. Tất cả là **development/staging**, không là view production DLU.

| # | View | Người dùng, ý nghĩa | Nguồn chính / cách dùng và giới hạn |
|---|---|---|---|
| 1 | `student_attendance_summary` | Student/Teacher: chuyên cần | `attendance*`, user/course; thông tin buổi học của mô hình mẫu, không xác nhận sổ điểm DLU. |
| 2 | `student_course_progress` | Student/Teacher: tiến độ course | `course_modules_completion`, `course_completions`, ghi danh; completion không đồng nghĩa đã nộp. |
| 3 | `unified_tasks` | Student/Teacher: Assignment + Quiz trên một luồng công việc | `assign`, `assign_submission`, `quiz`, `quiz_attempts`, course; trạng thái tổng hợp để đọc, thao tác chính thức mở LMS. |
| 4 | `student_course_learning_items` | Student: nội dung course | section/module cùng resource/folder và activity; chỉ metadata/điều hướng, không suy quyền tải file private. |
| 5 | `student_continue_learning` | Student: học tiếp | course learning items, completion/last access; gợi ý điều hướng, không thay lịch sử LMS. |
| 6 | `student_engagement` | Student/Teacher: hoạt động gần đây | `logstore_standard_log`, `user_lastaccess`; sự vắng log không tự là không học. |
| 7 | `student_task_summary` | Student/Teacher: tổng số việc cần làm | `unified_tasks` theo người/course; phụ thuộc các trạng thái của seed. |
| 8 | `student_course_overview` | Student: thẻ học phần | course/enrolment + progress/task summary; API giới hạn theo identity. |
| 9 | `student_dashboard` | Student: Home | các student read model và user; tổng quan, không dữ liệu production. |
| 10 | `student_grade_category_summary` | Student: điểm theo nhóm | grade categories/items/grades; không tự tính điểm tổng kết chính thức. |
| 11 | `student_grade_overview` | Student/Teacher: điểm đã có | gradebook/assignment/quiz; `null` là chưa có dữ liệu, không biến thành 0. |
| 12 | `student_risk_indicator` | Teacher: mức ưu tiên hỗ trợ | progress/task/engagement; chỉ heuristic LOW/MEDIUM/HIGH, không AI. |
| 13 | `student_learning_analytics` | Student: tóm tắt học tập | progress, attendance, grade, task và engagement; chỉ số hỗ trợ, không quyết định học vụ. |
| 14 | `teacher_course_overview` | Teacher: học phần phụ trách | teacher role/context, course, enrolment và các tổng hợp; phải lọc course thuộc giáo viên. |
| 15 | `teacher_assignment_monitoring` | Teacher: bài nộp/chưa nộp/cần chấm | `assign`, `assign_submission`, `assign_grades`, teacher course overview; Mobile không chấm. |
| 16 | `teacher_course_analytics` | Teacher: tổng quan lớp | student progress/engagement/grade/attendance/risk theo course; số liệu staging, không kết luận chính thức. |
| 17 | `teacher_dashboard` | Teacher: Home | `teacher_course_overview`; dashboard tổng hợp các course đã cấp phạm vi. |
| 18 | `teacher_grade_overview` | Teacher: điểm trong course mình dạy | student grade/progress + teacher course; chỉ đọc, không ghi. |
| 19 | `teacher_quiz_monitoring` | Teacher: tiến độ quiz | quiz/attempts/grades + teacher course; Mobile chỉ theo dõi. |
| 20 | `teacher_student_monitoring` | Teacher: theo dõi người học | student progress/task/engagement/risk + teacher course + user; API từ chối course ngoài phạm vi. |

Trong app hiện tại, Student dùng các endpoint `/api/v1/me/*`; Teacher dùng `/api/v1/me/teacher/*`. **Không phải cả 20 view đều có một màn hình riêng.** Có view hỗ trợ view khác hoặc phục vụ phân tích; chỉ nêu API/màn nào đã triển khai theo OpenAPI và runtime evidence. Ứng dụng nhắc việc hiện cục bộ, không phải đồng bộ `app.learning_reminders` staging.
