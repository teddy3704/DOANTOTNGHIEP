# API contract — Student Support Development

**This is NOT the production DLU LMS API.** Current source: dữ liệu mẫu của mô
hình PostgreSQL Neon `lms_mobile_learning`, schema `lms`. Không có PII DLU thật,
không có ghi nghiệp vụ Moodle. Future production source: Moodle Web Services được
DLU cấp quyền qua integration boundary; trạng thái tất cả chức năng: **TO_VERIFY_DLU**.

## Contract chung

Base URL local: `http://localhost:3000`. Hợp đồng máy đọc được tại `/openapi.json`,
Swagger UI `/docs`. OpenAPI **3.0.3** là version được chọn để tương thích rõ ràng với
Fastify Swagger/UI hiện tại; không khai báo 3.1/3.2 khi chưa được pipeline xác nhận.
Không đưa LMS DLU vào OpenAPI `servers`. Development dùng localhost như trên;
staging dùng server tương đối `/` (same-origin), để Swagger gửi request về đúng
host đang phục vụ API thay vì localhost của người xem. Public Render staging đã
xác minh `/health`, `/docs` và `/openapi.json` HTTP 200; xem
`INTEGRATION_STATUS.md` cho evidence/negative checks, không coi đó là DLU proof.

Mọi `/api/v1/me` endpoint yêu cầu `X-Demo-Student-Code`, ví dụ `SV001`. Mã phải
đúng pattern `^SV[0-9]{3}$` và là student mẫu đang hoạt động trong data source.
Đây là identity development, **không phải authentication**. Không query/body
parameter chọn user; không chấp nhận query parameter ngoài contract. Course ID là
chuỗi số dương tối đa 15 chữ số, lấy từ courses response, không dùng ID Moodle thật.

### Flutter staging scope selection

`main_staging.dart` obtains this header only from an explicit, allowlisted sample
student selection. The client stores at most that non-secret sample code in
platform-backed storage; it never asks for, transmits or persists a DLU password,
Moodle token or database credential. The code is loaded at request time rather
than copied into a domain user profile.

If the API returns 401 for a selected scope, the Flutter adapter clears the local
selection and the auth state returns to the selector. This limits stale preview
state only: it is not a production login flow, does not make the header a DLU
authorization grant, and must not be copied into `main.dart`.

- List: `{ "data": [], "meta": { "count": 0 } }`; count là số item trả về,
  không phải pagination total. Không pagination/filter chưa được hỗ trợ.
- Single: `{ "data": { ... } }`; overview là single object.
- Health dùng object riêng, không có `data` envelope.
- Empty list hợp lệ trả 200. Không bịa item để lấp trạng thái rỗng.
- Timestamp dùng ISO 8601; nullable fields giữ null. Decimal SQL được ánh xạ sang
  JSON number, IDs dùng string, không trả `Date` hoặc SQL numeric string tùy tiện.
- Content/resource/assignment/status/deadline có `deepLink: null` và
  `deepLinkStatus: "TO_VERIFY_DLU"`. Không có URL download hoặc deep-link giả.
- Response có `Cache-Control: no-store` và `X-Content-Type-Options: nosniff`.

## Endpoints, nguồn và quyền sở hữu

Tất cả dòng dưới là **GET**. Trừ health (vận hành), ownership là **Moodle**;
development representation không chuyển quyền sở hữu nghiệp vụ sang Neon/API.
Các bảng/view ghi dưới đây thuộc `lms`; điều kiện student/active enrollment/
course-module visibility được data source áp dụng, không chỉ dựa vào tên view.

| Path / operationId | Mục đích / SV | Nguồn PostgreSQL | HTTP thực tế |
|---|---|---|---|
| `/health` — `getHealth` | Reachability/read-only database, không kiểm chứng Moodle DLU | Read-only health query, không trả catalog/host | 200, 400, 500, 503 |
| `/api/v1/me` — `getStudentProfile` | Profile current synthetic student, hỗ trợ SV-01..09 | `users`, role/context/student checks | 200, 400, 401, 500, 503 |
| `/api/v1/me/courses` — `getCourses` | Khóa học đang ghi danh, SV-01 | `vw_student_courses` | 200, 400, 401, 500, 503 |
| `/api/v1/me/courses/{courseId}/content` — `getCourseContent` | Section/activity course được phép, SV-02 | `vw_student_courses` membership + `vw_course_content` | 200, 400, 401, 404, 500, 503 |
| `/api/v1/me/resources` — `getResources` | Metadata tài liệu, SV-03 | `vw_student_resources` | 200, 400, 401, 500, 503 |
| `/api/v1/me/assignments` — `getAssignments` | Danh mục bài tập và hạn nộp, SV-04 | `vw_student_assignments` | 200, 400, 401, 500, 503 |
| `/api/v1/me/assignment-status` — `getAssignmentStatus` | Chỉ đọc trạng thái lần nộp, SV-05 | `vw_assignment_status`, giới hạn bài tập hiển thị | 200, 400, 401, 500, 503 |
| `/api/v1/me/grades` — `getGrades` | Điểm/feedback của current student, SV-07 | `vw_student_grade_overview`, giới hạn bài tập hiển thị | 200, 400, 401, 500, 503 |
| `/api/v1/me/progress` — `getProgress` | Completion hoạt động có tracking, SV-08 | `vw_student_progress` | 200, 400, 401, 500, 503 |
| `/api/v1/me/deadlines` — `getDeadlines` | Bài tập sắp tới còn cần xử lý tại thời điểm query, SV-09 | `vw_upcoming_deadlines`, giới hạn bài tập hiển thị | 200, 400, 401, 500, 503 |
| `/api/v1/me/overview` — `getOverview` | Tổng hợp cùng nguồn scoped, SV-01/04/05/07/08/09 | Profile + courses/status/grades/progress/deadlines | 200, 400, 401, 500, 503 |

Course không tồn tại và course ngoài ghi danh đều trả 404, không tiết lộ existence.
Các response schema chung có 403 dự phòng, nhưng phiên bản này không tuyên bố có
nhánh authorization 403 đang được phát ra. Unsupported path/method trả 404, không
có endpoint POST/PATCH/PUT/DELETE nghiệp vụ. Swagger tự phục vụ tài nguyên UI.

## Important response fields

| Endpoint | Trường trong `data` hoặc item |
|---|---|
| Health | Object ngoài envelope: `status=ok`, `environment=development|staging`, `database=reachable`, `dataSource=neon-development-model`; không username/version/schema URI |
| Profile | `studentCode`, `fullName`, `email`, `department`, `role=student` |
| Courses | `courseId`, `courseCode`, `courseName`, `categoryName`, `summary`, `startsAt`, `endsAt?`, `teacherNames?` |
| Course content | `courseCode`, `sectionNumber`, `sectionName`, `courseModuleId`, `position`, `activityType`, `activityName`, `description`, `assignmentCode?`, `dueAt?`, `filenames?`, `totalSizeBytes?`, deep-link fields |
| Resources | `courseId`, `courseCode`, `courseName`, `sectionName`, `resourceId`, `resourceName`, `description`, `filename?`, `fileSizeBytes?`, `mimeType?`, deep-link fields |
| Assignments | `courseId`, `courseCode`, `courseName`, `assignmentId`, `assignmentCode`, `assignmentName`, `description`, `opensAt`, `dueAt`, `maxGrade`, deep-link fields |
| Assignment status | `courseCode`, `courseName`, `assignmentCode`, `assignmentName`, `submissionStatus`, `submittedAt?`, `isLate`, `attemptNumber?`, deep-link fields |
| Grades | `courseCode`, `courseName`, `assignmentCode`, `gradeItem`, `score`, `maxGrade`, `percentage?`, `gradeResult`, `feedback?`, `gradedAt`, `teacherName` |
| Progress | `courseId`, `courseCode`, `courseName`, `totalActivities`, `completedActivities`, `progressPercent` |
| Deadlines | `courseCode`, `courseName`, `assignmentCode`, `assignmentName`, `dueAt`, `submissionStatus`, `daysRemaining`, deep-link fields |
| Overview | `student`, `courseCount`, `upcomingDeadlineCount`, `assignmentSummary`, `progressSummary`, `gradeSummary.gradedItemCount`, `nextDeadline?` |

`?` trong bảng nghĩa là giá trị được phép null, không có nghĩa field bị bỏ khỏi
response. `submissionStatus` thuộc `graded`, `returned_for_resubmission`, `draft`,
`late`, `submitted`, `missing`, `not_submitted`; đây là đọc trạng thái, không API
thay đổi state. Không dùng `isLate` thay cho toàn bộ trạng thái bài tập.

`assignmentSummary`: `total` là tổng status; `submitted` đếm submitted/late/graded;
`graded` đếm graded; `outstanding` đếm not_submitted/missing/draft/returned;
`late` đếm `isLate=true`. Các nhóm có thể giao nhau, không cộng thành một tổng mới.
`nextDeadline` là phần tử đầu danh sách deadline có sắp xếp hoặc null. Progress
không phải GPA hay điều kiện đậu; không tính trung bình điểm khác thang đo.

## Errors

Response lỗi: `{ "error": { "code": "...", "message": "..." } }`.

| HTTP | Code | Ý nghĩa |
|---|---|---|
| 400 | `INVALID_REQUEST` | Path/query/shape sai contract, không trả chi tiết SQL/schema validation nội bộ |
| 401 | `DEVELOPMENT_IDENTITY_REQUIRED` | Thiếu/sai format header hoặc demo identity đã tắt |
| 401 | `DEVELOPMENT_IDENTITY_INVALID` | Mã đúng format nhưng không resolve thành active synthetic student |
| 404 | `COURSE_NOT_FOUND` | Course không tồn tại hoặc current student không được đọc |
| 404 | `NOT_FOUND` | Không có route/method được yêu cầu |
| 503 | `DATA_SOURCE_UNAVAILABLE` | Query/dependency failure, message an toàn và có thể thử lại |
| 500 | `INTERNAL_ERROR` | Lỗi nội bộ khác đã được che chi tiết |

Không trả stack, raw exception, SQL, credential, host/role database hoặc môi trường.
Không tạo payload lỗi giả chứa secret chỉ để trình diễn. Test negative dùng dữ
liệu không bí mật và kết quả thật.

## App-owned local reminder boundary (SV-10)

SV-10 is intentionally **outside** this HTTP/OpenAPI contract. Creating,
editing, enabling, disabling or deleting a personal reminder makes no API call,
does not use a Neon table/view, and creates no Moodle event or notification.
The reminder starts from an already-read assignment deadline and persists only
opaque owner/course/assignment references, due/reminder times and enabled state
in secure local storage. Assignment title, description, grade, feedback,
submission/file data, password, token and full API response are not persisted.

When a learner enables a reminder, Android local-notification permission is
requested by the device scheduler. Scheduled text is generic and contains no
academic content. This is not an official Moodle notification; device delivery
remains pending manual APK/emulator verification even though `flutter analyze`
is clean and the full Flutter suite currently passes 137 tests.

## Future production và phần không triển khai

Nguồn tương lai từng endpoint được truy vết ở `TRACEABILITY_MATRIX.md`; upstream
Moodle candidates **không phải** xác nhận DLU đã enable. SV-06 chỉ design deep-link,
SV-09 hiện có assignment deadline chứ chưa general calendar events endpoint và
SV-10 chỉ là local app-owned setting ngoài API. Resource binary/open action và DLU
identity không được suy ra từ contract này. Flutter staging consumer đã PASS
quality/emulator gate riêng qua explicit entrypoint chỉ đọc; current extension
still awaits its combined format/build/emulator gate and does not biến contract
này thành production Moodle integration hoặc cấp quyền upload/submission/grading.

The current Assignment Detail handoff is deliberately outside this API contract:
until a specific activity URL is verified, it may open only the canonical official
LMS home through the platform external-browser mechanism. It never constructs an
activity URL from response/sample IDs and offers no mobile submission control.

Versioned route `/api/v1` cho phép evolve contract có kiểm soát. Thay data source
không được âm thầm đổi ownership/visibility hoặc đưa synthetic data vào production.
