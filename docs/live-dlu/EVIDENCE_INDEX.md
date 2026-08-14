# DLU LMS Evidence Index

**Updated:** 2026-08-14 ICT

| ID | Finding | Type | Source | Confidence | Used By |
| -- | ------- | ---- | ------ | ---------- | ------- |
| `UI-AUTH-001` | Existing browser session is signed in and exposes authenticated navigation | `VERIFIED_UI` | `/my/`; logout/session UI marker and private navigation | High | Auth classification, feature map |
| `UI-AUTH-OPTION-001` | Public login offers local username/password and Google OAuth2 routes | `VERIFIED_UI` | `/login/index.php` | High for options; backend/mobile strategy remains `UNKNOWN` | Auth discovery |
| `UI-DASH-001` | Dashboard exposes course overview, recent items and calendar-related blocks | `VERIFIED_UI` | `/my/` | High | Dashboard traceability |
| `UI-COURSES-001` | Current-user course overview contains enrolled-course cards/links | `VERIFIED_UI` | `/my/` course-overview block | High | Courses traceability |
| `UI-COURSE-001` | One enrolled course exposes multiple sections/activities | `VERIFIED_UI` | `/course/view.php?id=<redacted>` | High | Course Detail traceability |
| `UI-COURSE-002` | `COURSE-A` exposes assignment, forum, label, resource and URL activity types | `VERIFIED_UI` | Sanitized `COURSE-A` DOM | High | Course-content backlog |
| `UI-COURSE-003` | `COURSE-A` exposes resource and protected-file links | `VERIFIED_UI` | Sanitized `COURSE-A` DOM | High | File-policy backlog |
| `UI-COURSE-004` | `COURSE-A` exposes grade navigation | `VERIFIED_UI` | Sanitized `COURSE-A` DOM | High | Grades backlog |
| `UI-COURSE-005` | `COURSE-A` exposes participants navigation; list not collected | `VERIFIED_UI` | Sanitized `COURSE-A` DOM | High | Capability/privacy boundary |
| `UI-PROFILE-001` | Current-user profile container, avatar and grouped fields are present | `VERIFIED_UI` | `/user/profile.php?id=<redacted>` | High | Profile traceability |
| `UI-CALENDAR-001` | Calendar month, event and filter UI are present | `VERIFIED_UI` | `/calendar/view.php?<redacted>` | High | Calendar backlog |
| `UI-GRADES-001` | Current-user grade overview and course-grade navigation are present | `VERIFIED_UI` | `/grade/report/overview/index.php` | High; values omitted | Grades backlog |
| `UI-NOTIFY-001` | Notification navigation/control is present | `VERIFIED_UI` | Authenticated navigation | High for navigation only | Notifications backlog |
| `UI-MESSAGE-001` | Message navigation is present but target rendered a generic error state | `VERIFIED_UI` | `/message/index.php` | High for observed outcome; availability `UNKNOWN` | Feature map |
| `NET-NAV-001` | Authenticated Dashboard document loaded as HTML | `VERIFIED_NETWORK` | Browser read-only navigation to `/my/` | Medium; HTTP status unavailable | Network evidence |
| `NET-NAV-002` | Representative course document loaded as HTML | `VERIFIED_NETWORK` | Browser read-only navigation to sanitized course path | Medium; HTTP status unavailable | Network evidence |
| `NET-NAV-003` | Current-user Profile document loaded as HTML | `VERIFIED_NETWORK` | Browser read-only navigation to sanitized profile path | Medium; HTTP status unavailable | Network evidence |
| `NET-NAV-004` | Current-user Calendar document loaded as HTML | `VERIFIED_NETWORK` | Browser read-only navigation to sanitized calendar path | Medium; HTTP status unavailable | Network evidence |
| `NET-NAV-005` | Current-user grades overview loaded as HTML | `VERIFIED_NETWORK` | Browser read-only navigation to own grades overview | Medium; HTTP status unavailable | Network evidence |
| `NET-REST-001` | Anonymous REST entrypoint returned `403 text/html` | `VERIFIED_NETWORK` | GET `/webservice/rest/server.php` | High for response; denial layer `UNKNOWN` | Web Services gate |
| `NET-TOKEN-001` | Token entrypoint returned JSON `enablewsdescription` without a token | `VERIFIED_NETWORK` | GET `/login/token.php`, no credentials | High | Web Services gate |
| `NET-TOKEN-002` | Mobile `appsitecheck` returned JSON `enablewsdescription`, not success | `VERIFIED_NETWORK` | GET `/login/token.php?appsitecheck=1`, no credentials | High | `MOODLE_WEB_SERVICES_NOT_ENABLED` |
| `DOC-WS-001` | Standard Moodle token source gates token/site-check flow on `enablewebservices` | `VERIFIED_OFFICIAL_DOC` | Official Moodle stable source; DLU version not inferred | High for source semantics | Interpret `NET-TOKEN-001/002` |
| `API-000` | No DLU Moodle Web Service function has a successful response contract | `UNKNOWN` | No enabled service/token/function allowlist | High | API matrix, production blocker |
| `DB-000` | DLU physical database schema/version/prefix not provided | `UNKNOWN` | No database evidence | High | Database mapping |

## Evidence policy

- `VERIFIED_UI` establishes visible DLU behavior, not API availability.
- `VERIFIED_NETWORK` establishes only the sanitized request/response actually observed.
- `VERIFIED_API` remains absent until an approved Moodle function succeeds and its sanitized response contract is verified.
- No entry in this index contains a live identifier or secret.
