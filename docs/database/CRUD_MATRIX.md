# CRUD Matrix

**Subset:** `MOODLE_SUBSET_V1`

**Current production posture:** `READ_BLOCKED_UNTIL_VERIFIED_API`; all live writes `BLOCKED_WRITE`

## Non-negotiable data path

```text
Flutter mobile -> HTTPS -> approved Moodle application/API layer -> Moodle data layer
```

Mọi `R/C/U/D` trong ma trận đều có nghĩa là thao tác qua Moodle application/API đã được xác minh, không phải SQL trực tiếp. Flutter không được kết nối MySQL, giữ database credential, truy vấn các bảng bên dưới hoặc dùng synthetic schema làm production backend. Tên bảng chỉ mô tả domain ownership và traceability của fixture.

Hiện tại chưa có live DLU API contract nào được response-verified cho các feature này. Vì vậy mọi live read đều là `BLOCKED_API` và mọi live write đều là `BLOCKED_WRITE`. `DEV_READ_ONLY` chỉ là dữ liệu `SYNTHETIC_DATA`, không làm thay đổi trạng thái live.

## Legend

- `R` — đọc projection đã được server authorize qua Moodle API/file response đã xác minh.
- `C`, `U`, `D` — tạo, cập nhật hoặc xóa qua Moodle application/API operation đã xác minh; tuyệt đối không direct SQL.
- `BLOCKED_API` — chưa ghi nhận DLU-approved function được bật và response-verified.
- `BLOCKED_WRITE` — chưa xác minh endpoint, capability, context, test account và safe test environment.
- `DEV_READ_ONLY` — chỉ render deterministic `SYNTHETIC_DATA` trong build development/test.
- `N/A` — client không được cung cấp thao tác đó trong scope hiện tại.

## Mobile operation matrix

| Feature | Table | Student Read | Student Write | Teacher Read | Teacher Write |
|---|---|---|---|---|---|
| Authenticate / session | `user` chỉ là identity projection; không có table CRUD để login | `BLOCKED_API` — cần auth method/API được DLU xác nhận | `N/A` — không lưu password, không ghi bảng | `BLOCKED_API` — cần auth method/API được DLU xác nhận | `N/A` — không lưu password, không ghi bảng |
| Own profile | `user` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`U`) | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`U`) |
| My Courses | `user_enrolments`, `enrol`, `course`, `course_categories` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `N/A` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U/D` course/enrolment) |
| Course sections and modules | `course`, `course_sections`, `course_modules`, `modules` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `N/A` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U/D`) |
| Resource metadata / download | `resource`, `course_modules`, `modules`, `context`, `files` | `BLOCKED_API`; DEV: metadata only | `N/A` | `BLOCKED_API`; DEV: metadata only | `BLOCKED_WRITE` (`C/U/D`) |
| Assignment details / deadlines | `assign`, `course_modules`, `modules`, `event` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `N/A` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U/D`) |
| Own submission status | `assign_submission`, `assign` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U/D` qua workflow assignment; plugin content ngoài V1) | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`U` state chỉ qua workflow được phép) |
| Assignment grade | `assign_grades`, `assign_submission`, `assign` | `BLOCKED_API` — chỉ own grade; DEV: `DEV_READ_ONLY` | `N/A` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U` qua grading API) |
| Course gradebook | `grade_items`, `grade_grades`, `course`, `user` | `BLOCKED_API` — chỉ own visible grades; DEV: `DEV_READ_ONLY` | `N/A` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U` qua grading API) |
| Activity completion | `course_modules_completion`, `course_modules`, `user` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`U` chỉ qua Moodle completion semantics) | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`U`/override nếu capability cho phép) |
| Upcoming calendar items | `event`, `course`, `user`, `course_categories` | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U/D`) | `BLOCKED_API`; DEV: `DEV_READ_ONLY` | `BLOCKED_WRITE` (`C/U/D`) |
| Contextual role display | `role_assignments`, `role`, `context`, `user` | `BLOCKED_API` — presentation hint, không phải authorization | `N/A` | `BLOCKED_API` — presentation hint, không phải authorization | `BLOCKED_WRITE` (`C/U/D` role assignment) |
| Manage enrolments / courses / content / roles | Các bảng selected liên quan | `N/A` | `N/A` | `BLOCKED_API` | `BLOCKED_WRITE` (`C/U/D`); ngoài student milestone |

## Write release gate

Không write control nào được chuyển khỏi `BLOCKED_WRITE` trước khi toàn bộ điều kiện sau được ghi nhận và kiểm thử:

1. DLU phê duyệt authentication method và Moodle service mục tiêu.
2. Exact standard/custom API function, request schema và sanitized response/error contract được xác minh.
3. Required capability và context được nhận diện; Moodle/backend vẫn là authoritative authorization boundary.
4. Có least-privilege test account và non-production/test course.
5. Token handling, input validation, retry/idempotency và safe error mapping được triển khai.
6. Automated tests cover allowed, denied, expired-session, invalid-input và duplicate-request.
7. Kiểm thử không để lộ credential, dữ liệu cá nhân hoặc database access cho client.

Database table coverage không đáp ứng release gate này. `TEACHER_SCHEMA_REFERENCE` và `SYNTHETIC_DATA` đều không chứng minh một DLU API operation tồn tại hoặc đang được bật.

## Delete policy

Mobile scope hiện tại không expose delete operation. Mọi thao tác delete-like trong tương lai phải dùng Moodle domain workflow, không xóa row trực tiếp. Hành động destructive trên production cần authorization riêng, auditability và xác nhận rõ ràng.
