# DLU LMS Web Feature Map

**Status:** Public unauthenticated map. Authenticated evidence is maintained separately in `AUTHENTICATED_FEATURE_MAP.md`.

**Updated:** 2026-08-13 ICT

| Feature | Actual URL/Pattern | Visible | Requires Login | Student | Teacher | Notes |
|---|---|---:|---:|---:|---:|---|
| Public home | `/` | Yes | No | UNKNOWN | UNKNOWN | LMS branding, public blocks and category tree observed |
| Login | `/login/index.php` | Yes | No | UNKNOWN | UNKNOWN | Username/password form plus Google Login option observed |
| Password recovery | `/login/forgot_password.php` | Yes | No | UNKNOWN | UNKNOWN | Public recovery link observed; not opened/submitted |
| Google OAuth2 entry | `/auth/oauth2/login.php?...` | Yes | No | UNKNOWN | UNKNOWN | Link labelled Google Login; transient query state intentionally omitted |
| Course search | `/course/search.php?search=...` | Yes | No | UNKNOWN | UNKNOWN | Public GET search form observed; no query submitted |
| Course categories | `/course/index.php?categoryid=<id>` | Yes | No | UNKNOWN | UNKNOWN | Category links observed; no bulk traversal |
| Language selector | Current page with language menu | Yes | No | UNKNOWN | UNKNOWN | Vietnamese selected on observed page |

Dashboard, My Courses, course pages, profile, grades, calendar, notifications and messages remain intentionally absent from this public table. See `AUTHENTICATED_FEATURE_MAP.md` for features directly observed in the signed-in session. No default Moodle feature is treated as a DLU fact.
