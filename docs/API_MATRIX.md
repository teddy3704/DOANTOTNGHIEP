# Moodle API Matrix

**Status:** Discovery backlog; `0` functions verified against DLU.
**Cập nhật:** 2026-08-12

## Cách đọc bảng

- Tên function dưới đây là **candidate standard Moodle functions**, không phải cam kết rằng DLU version/service expose chúng.
- `Student`/`Teacher` mô tả persona cần kiểm thử, không khẳng định quyền.
- Permission/capability cuối cùng phải lấy từ DLU live API documentation và test trong đúng Moodle context.
- Tất cả WRITE functions giữ `BLOCKED` cho đến khi có test environment và explicit permission.

| Feature | Candidate Moodle function/endpoint | Permission evidence cần xác nhận | Student | Teacher | Status | Notes |
|---|---|---|---|---|---|---|
| Site/user info | `core_webservice_get_site_info` | Function in service; valid token/session | VERIFY | VERIFY | BLOCKED | First post-auth validation call candidate |
| User profile lookup | `core_user_get_users_by_field` | User privacy + function access | VERIFY own only | VERIFY scoped | BLOCKED | Prefer site-info fields when sufficient |
| My courses | `core_enrol_get_users_courses` | Enrolment visibility and target user scope | VERIFY | VERIFY | BLOCKED | Exact response varies by Moodle version |
| Timeline courses | `core_course_get_enrolled_courses_by_timeline_classification` | Function availability and enrolment visibility | VERIFY | VERIFY | BLOCKED | Optional alternative to course list |
| Course contents | `core_course_get_contents` | Course/module visibility, enrolment/context | VERIFY | VERIFY | BLOCKED | Must respect hidden/restricted modules |
| Course details | `core_course_get_courses_by_field` | Course visibility and service allowlist | VERIFY | VERIFY | BLOCKED | Avoid broad course enumeration |
| Enrolled users | `core_enrol_get_enrolled_users` | Roster/user visibility in course context | EXPECT DENY unless allowed | VERIFY | BLOCKED | Teacher UI only after permission evidence |
| Assignments list | `mod_assign_get_assignments` | Course/module visibility | VERIFY | VERIFY | BLOCKED | Map nested course/assignment payload carefully |
| Own submission status | `mod_assign_get_submission_status` | Assignment access and own submission scope | VERIFY | VERIFY where relevant | BLOCKED | Read-only first |
| Submission list | `mod_assign_get_submissions` | Grading/submission visibility in context | EXPECT DENY | VERIFY | BLOCKED | Contains sensitive student data |
| Save submission | `mod_assign_save_submission` | Submit capability, assignment state, file policy | VERIFY on test only | N/A/VERIFY | BLOCKED-WRITE | No production probe |
| Save grade/feedback | `mod_assign_save_grade` | Grading capability in course/module context | DENY | VERIFY on test only | BLOCKED-WRITE | No production probe; exact contract version-dependent |
| User grades | `gradereport_user_get_grade_items` | Grade visibility and target user scope | VERIFY own only | VERIFY scoped | BLOCKED | Sensitive academic data; minimize cache/logging |
| Upcoming calendar | `core_calendar_get_calendar_upcoming_view` | Event visibility and user context | VERIFY | VERIFY | BLOCKED | Candidate for dashboard deadlines |
| Action events | `core_calendar_get_action_events_by_timesort` | Event visibility/function availability | VERIFY | VERIFY | BLOCKED | Candidate alternative for actionable deadlines |
| Popup notifications | `message_popup_get_popup_notifications` | Messaging/notification visibility | VERIFY own only | VERIFY own only | BLOCKED | Confirm plugin/component enabled |
| File metadata | File fields returned by content functions | Course/module/file visibility | VERIFY | VERIFY | BLOCKED | Do not expose tokenized URLs |
| File download | DLU-approved authenticated Moodle file endpoint | Service download flag + file context permission | VERIFY | VERIFY | BLOCKED | Endpoint/path must be confirmed from DLU contract |
| File upload | DLU-approved Moodle upload endpoint | Service upload flag + draft/file-area permission | VERIFY on test only | VERIFY on test only | BLOCKED-WRITE | Needed only for approved submission flow |

## Authentication matrix

| Strategy | DLU evidence required | Client secret handling | Status |
|---|---|---|---|
| Moodle username/password token acquisition | Approved endpoint, service shortname/policy, CAPTCHA/MFA/SSO compatibility | Password exists in memory only for request; token in secure storage; no logs | BLOCKED |
| Browser-based SSO/deep link | IdP protocol, allowed redirect URI, app registration, token/session exchange | System browser; validate state/redirect; store approved session secret | BLOCKED |
| Administrator-issued per-user test token | Service/function scope, expiry/IP rules, secure delivery | Never commit; secure storage/runtime injection | BLOCKED |

Không chọn strategy trước khi DLU xác nhận. Không dùng embedded WebView scraping như fallback.

## Verification criteria per row

Một row chỉ chuyển sang `PASS` khi:

1. Function/endpoint xuất hiện trong live DLU API documentation hoặc contract được administrator duyệt.
2. Request/response được kiểm thử bằng test account đúng persona/context.
3. Success, permission denied, invalid token, empty data và relevant error behavior được ghi nhận.
4. Sanitized DTO contract/test fixture tồn tại.
5. Không có token/PII trong source, logs hoặc test artifact.

Nếu function không tồn tại nhưng use case được đáp ứng bằng function chuẩn khác, cập nhật row theo bằng chứng. Chỉ mở custom plugin proposal sau khi API gap được ghi rõ.
