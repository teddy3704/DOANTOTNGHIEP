# DLU LMS Evidence-Based Data Dictionary

**Updated:** 2026-08-14 ICT

This dictionary records semantic fields observed in DLU's current-user UI or network response. It does not claim JSON keys, database columns or Moodle Web Service availability. No real field value is retained.

| Entity | Field | Source | Evidence | Flutter Model | Used By |
| ------ | ----- | ------ | -------- | ------------- | ------- |
| Authenticated session | Signed-in state | Authenticated navigation/session marker at `/my/` | `VERIFIED_UI` (`UI-AUTH-001`) | `AuthSession` foundation only; live mapping `TBD` | Router/auth state after approved integration |
| User | Display identity | Dashboard/Profile UI; value intentionally omitted | `VERIFIED_UI` (`UI-AUTH-001`, `UI-PROFILE-001`) | `AppUser.displayName` is foundation semantics; API mapping `TBD` | Dashboard/Profile |
| User | Profile image | Current-user Profile UI | `VERIFIED_UI` (`UI-PROFILE-001`) | `TBD` | Profile |
| User | Profile field groups | Current-user Profile UI; labels/values not persisted | `VERIFIED_UI` (`UI-PROFILE-001`) | `TBD`; do not assume email/faculty/role | Profile |
| Course | Display name | Current-user course overview; value intentionally omitted | `VERIFIED_UI` (`UI-COURSES-001`) | `Course.fullName` foundation semantics; API mapping `TBD` | Dashboard/Courses |
| Course | Identifier | Sanitized `/course/view.php?id=<redacted>` pattern | `VERIFIED_UI` (`UI-COURSE-001`) | `Course.id` foundation semantics; API mapping `TBD` | Courses/Course Detail |
| Course | Sections collection | `COURSE-A` page | `VERIFIED_UI` (`UI-COURSE-001`) | No live domain model yet | Course Detail |
| Course module | Activity type | `COURSE-A` DOM structure | `VERIFIED_UI` (`UI-COURSE-002`) | No live domain model yet | Course Detail |
| Course resource | Protected file link presence | Sanitized `/pluginfile.php/<redacted>` link on `COURSE-A` | `VERIFIED_UI` (`UI-COURSE-003`) | No live model; authenticated mechanism `TBD` | Future file flow |
| Grade overview | Current-user course-grade rows | Own grades overview; values omitted | `VERIFIED_UI` (`UI-GRADES-001`) | No model | Future Grades |
| Calendar | Event metadata presence | Current-user month view; values omitted | `VERIFIED_UI` (`UI-CALENDAR-001`) | No model | Future Calendar |
| Moodle error envelope | `errorcode` | `/login/token.php` read-only checks | `VERIFIED_NETWORK` (`NET-TOKEN-001`, `NET-TOKEN-002`) | Generic safe failure mapping only; DLU API parser `TBD` | Integration diagnostics |

## Explicitly unverified model fields

- `AppUser.email`, `AppUser.roleLabel` and `AppUser.faculty` are DEV/foundation fields, not DLU API facts.
- `Course.shortName`, `Course.category`, `Course.progress` and `Course.nextActivity` are DEV/foundation fields, not DLU API facts.
- `Course.accentIndex` is presentation data and must not become a Moodle DTO field.
- Notification/message data and all database fields remain `UNKNOWN`.
