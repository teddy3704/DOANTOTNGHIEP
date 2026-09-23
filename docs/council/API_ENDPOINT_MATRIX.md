# Matrix endpoint thực tế — development/staging only

Tất cả endpoint dưới đây có trong `integration-api/openapi.group-39-20.json`. Mọi route dữ liệu là GET; Teacher không có route chấm điểm. “Nguồn” mô tả read model/bảng chủ yếu ở adapter hiện tại, không phải quyền truy cập database từ Flutter. `/docs` và `/openapi.json` là route tài liệu ngoài contract nghiệp vụ.

| Method | Path | Role | Mục đích | R/W | Nguồn chính | Flutter |
|---|---|---|---|---|---|---|
| GET | `/health` | Public | Reachability DB | Read | kiểm tra PostgreSQL | kiểm tra demo |
| GET | `/api/v1/me` | Student | Hồ sơ đang chọn | Read | `lms."user"`, scoped enrolment | Profile/Home |
| GET | `/api/v1/me/courses` | Student | Học phần và người dạy | Read | `course`, `course_categories`, role/context, enrolment | Courses |
| GET | `/api/v1/me/resources` | Student | Metadata tài nguyên | Read | `resource`, `course_modules`, `course_sections` | Course detail |
| GET | `/api/v1/me/assignments` | Student | Danh sách bài tập | Read | `assign`, scoped course | Assignments |
| GET | `/api/v1/me/assignment-status` | Student | Trạng thái nộp/điểm | Read | `assign_submission`, `grade_items`, `grade_grades` | Assignment detail |
| GET | `/api/v1/me/grades` | Student | Điểm đã có/feedback | Read | `grade_items`, `grade_grades`, `assign` | Grades |
| GET | `/api/v1/me/progress` | Student | Tiến độ module | Read | `course_modules_completion` + course | Progress |
| GET | `/api/v1/me/deadlines` | Student | Hạn sắp tới | Read | `assign`/submission scoped | Calendar/reminders |
| GET | `/api/v1/me/courses/{courseId}/content` | Student | Nội dung course | Read | `student_course_learning_items`, sections/modules | Course detail |
| GET | `/api/v1/me/overview` | Student | Tổng quan học tập | Read | các query Student scoped | Home |
| GET | `/api/v1/me/teacher` | Teacher | Hồ sơ GV | Read | `lms."user"`, teacher scoped courses | Profile/Home |
| GET | `/api/v1/me/teacher/overview` | Teacher | Tổng quan lớp | Read | `teacher_course_overview`, course/assignment | Teacher Home |
| GET | `/api/v1/me/teacher/courses` | Teacher | Course đang dạy | Read | `teacher_course_overview`, sections/resources | Teacher Courses |
| GET | `/api/v1/me/teacher/assignments` | Teacher | Công việc/bài cần theo dõi | Read | `teacher_assignment_monitoring`, `assign` | Công việc |
| GET | `/api/v1/me/teacher/courses/{courseId}/students` | Teacher | Sinh viên trong course được phép | Read | `teacher_student_monitoring`, user, scoped course | Student Monitoring |

`/api/v1/me/*` cần identity Student mẫu; `/api/v1/me/teacher/*` cần identity Teacher mẫu, không được trộn. Production phải thay bằng cơ chế DLU được duyệt, không mở demo header ra môi trường dữ liệu thật.
