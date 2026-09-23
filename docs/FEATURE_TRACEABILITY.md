# Production Feature Traceability

Current staging Student/Teacher GROUP_39_20 implementation is traced separately
in `TRACEABILITY_MATRIX.md` (22/09/2026). Staging API PASS does not remove the DLU
production blockers in this table; official auth/Web Services remain TO_VERIFY_DLU.

**Updated:** 2026-09-18 ICT

| Production Feature | DLU Evidence | Moodle API/Data Source | DTO/Domain Model | Repository | Provider | Screen | Tests | Status / Gap |
| ------------------ | ------------ | ---------------------- | ---------------- | ---------- | -------- | ------ | ----- | ------------ |
| Authentication | `UI-AUTH-OPTION-001`, `NET-TOKEN-002` | Mobile Web Services currently report disabled; approved auth strategy `UNKNOWN` | `AuthSession` foundation only | `UnconfiguredAuthRepository`; DEV fixture separate | `authControllerProvider` | Login | Production fail-closed + DEV flow tests | `BLOCKED_EXTERNAL`: `AUTHENTICATION_METHOD_UNCONFIRMED`, `MOODLE_WEB_SERVICES_NOT_ENABLED` |
| Current user / Profile | `UI-AUTH-001`, `UI-PROFILE-001` | Successful current-user API response `UNKNOWN` | `AppUser` contains DEV/foundation fields; live DTO absent | `UnconfiguredUserRepository`; DEV fixture separate | `currentUserProvider` | Profile | Foundation state/widget coverage | `BLOCKED_EXTERNAL`: no `VERIFIED_API` contract |
| Dashboard | `UI-DASH-001` | Depends on verified user/course/calendar APIs | No Dashboard DTO | Composes repositories | Auth/course/profile providers | Dashboard | DEV demo flow | `FOUNDATION_ONLY`; production sections cannot use fixtures |
| My Courses | `UI-COURSES-001` | Enrolled-course function `UNKNOWN` | `Course` foundation model; live DTO absent | `UnconfiguredCourseRepository`; DEV fixture separate | `myCoursesProvider` | Courses | Loading/empty/error/retry + DEV flow | `BLOCKED_EXTERNAL`: no enabled service/function response |
| Course Detail | `UI-COURSE-001` to `UI-COURSE-005` | Course-content function `UNKNOWN` | No `CourseSection`/`CourseModule` live model | Foundation `getCourse` only | `courseDetailProvider` | Course Detail | DEV demo flow | `BLOCKED_EXTERNAL`: HTML evidence is not an API contract |
| Course files | `UI-COURSE-003` | Authenticated file mechanism/policy `UNKNOWN` | No file DTO/domain model | None | None | None | None | `BLOCKED_EXTERNAL`: service and file policy required |
| Current-user grades | `UI-GRADES-001` | Own-grades function `UNKNOWN` | No Grade model | None | None | None | None | `BLOCKED_EXTERNAL`; sensitive data minimized |
| Calendar | `UI-CALENDAR-001` | Calendar function `UNKNOWN` | No CalendarEvent model | None | None | None | None | `BLOCKED_EXTERNAL` |
| Notifications | `UI-NOTIFY-001` | Notification function `UNKNOWN` | No Notification model | None | None | None | None | `BLOCKED_EXTERNAL`; content not opened. This is separate from the app-owned local reminder row below. |
| Network/config safety | `NET-REST-001`, `NET-TOKEN-001/002` | Central HTTPS client; no live function | `AppFailure`/safe diagnostics | N/A | `moodleApiClientProvider` | User-friendly error surfaces | Config/network origin/redaction unit tests | Local hardening PASS; live envelope mapping waits for a verified contract |

## Interpretation

DEV fixture tests prove the Flutter foundation and UI states only. They are not evidence of DLU production integration. A row can move to live `PASS` only after a DLU-approved authentication path, enabled service/function, sanitized successful response contract, typed mapper, repository wiring and tests all exist.

## Separate Student Support development/staging traceability

The `PASS` entries below retain the verified read-only staging baseline. Rows
marked as an extension have source and focused tests in the current worktree but
remain pending the combined final Flutter quality/emulator gate; they are never
evidence of production Moodle authentication, authorization or write support.

| Non-production feature | Verified API contract | Flutter boundary | UI scope | Status / quality gate |
| --- | --- | --- | --- | --- |
| Read-only preview session | `/api/v1/me`, HTTPS Render staging, development identity header | `StagingStudentIdentityProvider` + `StagingPreviewAuthRepository` through `AuthRepository` | Splash → explicit sample-scope selector → Dashboard | `PASS` baseline; selector/401-invalidation extension pending combined final gate. It has no DLU password/token or production fallback. |
| Student profile/dashboard | `/api/v1/me`, `/courses`, `/progress`, `/deadlines`, `/overview` | `StagingUserRepository`, `StagingCourseRepository` | Profile, Dashboard | `PASS`: mapper/provider tests and emulator Dashboard/Profile verification |
| Courses and content/resources | `/courses`, `/courses/{courseId}/content`, `/resources` | `StagingCourseRepository`, `StagingCourseContentRepository` | Courses, Course Detail, Resource Detail | `PASS`: read-only adapter and emulator route verification; no download/deep-link fabrication |
| Assignment status, grades and official LMS handoff | `/assignments`, `/assignment-status`, `/grades`; no verified activity deep link | `StagingAssignmentRepository`, `StagingGradeRepository`, `OfficialLmsLauncher` | Assignment list/detail, Grades, canonical external LMS handoff | Extension pending combined final gate: no submit/grade/write route exists; only the exact official LMS home may be opened externally. |
| Course progress | `/progress` | `StagingCourseRepository` through `CourseRepository` | Progress | Extension pending combined final gate: renders server-supplied course values only; no completion mutation or inferred GPA. |
| Deadline calendar | `/deadlines` | `StagingCalendarRepository` | Calendar, reached contextually from Dashboard | Extension pending combined final gate: assignment deadlines only, not a live DLU calendar. |
| App-owned personal reminders | No API operation; a reminder starts from an already-read assignment deadline | `LearningReminder` → `SecureLocalReminderRepository` → secure local storage + `FlutterLocalReminderScheduler` | Assignment Detail editor; Profile → Reminder Manager | Local implementation: owner-scoped create/update/enable/disable/delete with minimal opaque metadata and generic Android notification. Analysis is clean and the 137-test suite passes; final APK/emulator delivery verification is pending. No Moodle, Render, Neon or Supabase write is involved. |

This table traces only the verified development/staging API. It must not be read
as an update to the production table above: all DLU-specific rows remain
`BLOCKED_EXTERNAL` until the documented Moodle evidence and approval gates exist.
