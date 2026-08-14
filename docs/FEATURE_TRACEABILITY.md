# Production Feature Traceability

**Updated:** 2026-08-14 ICT

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
| Notifications | `UI-NOTIFY-001` | Notification function `UNKNOWN` | No Notification model | None | None | None | None | `BLOCKED_EXTERNAL`; content not opened |
| Network/config safety | `NET-REST-001`, `NET-TOKEN-001/002` | Central HTTPS client; no live function | `AppFailure`/safe diagnostics | N/A | `moodleApiClientProvider` | User-friendly error surfaces | Config/network origin/redaction unit tests | Local hardening PASS; live envelope mapping waits for a verified contract |

## Interpretation

DEV fixture tests prove the Flutter foundation and UI states only. They are not evidence of DLU production integration. A row can move to live `PASS` only after a DLU-approved authentication path, enabled service/function, sanitized successful response contract, typed mapper, repository wiring and tests all exist.
