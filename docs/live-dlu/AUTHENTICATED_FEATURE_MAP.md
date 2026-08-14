# DLU LMS Authenticated Feature Map

**Observed:** 2026-08-14 ICT

**Scope:** Existing current-user browser session, read-only, one representative enrolled course

No user name, course name, course ID, grade, message, cookie, token or `sesskey` value is retained in this document. `COURSE-A` denotes the single representative course inspected.

| Feature | URL Pattern | Evidence | Auth Required | Data Available | Flutter Feature |
| ------- | ----------- | -------- | ------------- | -------------- | --------------- |
| Authenticated session | `/my/` | `VERIFIED_UI` (`UI-AUTH-001`) | Yes | Current-user session marker and authenticated navigation; identity value not retained | Auth foundation exists; production provider remains unconfigured |
| Dashboard | `/my/` | `VERIFIED_UI` (`UI-DASH-001`) | Yes | Recently accessed courses/items, course overview, calendar month/upcoming and online-user blocks are present | Dashboard shell exists; live data source is blocked |
| My Courses | `/my/` course-overview block | `VERIFIED_UI` (`UI-COURSES-001`) | Yes | Current-user course cards and links are available; names and identifiers not retained | Courses loading/empty/error/retry UI exists; live repository is blocked |
| Course detail (`COURSE-A`) | `/course/view.php?id=<redacted>` | `VERIFIED_UI` (`UI-COURSE-001`) | Yes | Multiple sections and activities are present | Course Detail foundation exists; section/module domain contract is not implemented |
| Course activities (`COURSE-A`) | `/course/view.php?id=<redacted>` | `VERIFIED_UI` (`UI-COURSE-002`) | Yes | Assignment, forum, label, resource and URL activity types were observed; quiz was not observed in this course | No live activity model/repository yet |
| Course resources (`COURSE-A`) | `/course/view.php?id=<redacted>` and `/pluginfile.php/<redacted>` links | `VERIFIED_UI` (`UI-COURSE-003`) | Yes | Resource links and one protected-file link were present; no file was downloaded | No live file integration; file policy remains required |
| Course grades navigation (`COURSE-A`) | `/grade/report/<redacted>` | `VERIFIED_UI` (`UI-COURSE-004`) | Yes | Grade-report navigation is present; no grade value retained | No Grades feature yet |
| Course participants navigation (`COURSE-A`) | `/user/index.php?<redacted>` | `VERIFIED_UI` (`UI-COURSE-005`) | Yes | Participants navigation is present; list was not opened or collected | Not planned before capability evidence |
| Profile | `/user/profile.php?id=<redacted>` | `VERIFIED_UI` (`UI-PROFILE-001`) | Yes | Profile container, avatar and grouped profile fields are present; values not retained | Profile foundation exists; live field contract is blocked |
| Calendar | `/calendar/view.php?<redacted>` | `VERIFIED_UI` (`UI-CALENDAR-001`) | Yes | Month grid, event metadata and filters are present; event values not retained | No Calendar feature yet |
| Current-user grades overview | `/grade/report/overview/index.php` | `VERIFIED_UI` (`UI-GRADES-001`) | Yes | A grade overview and course-grade navigation are present; all values omitted | No Grades feature yet |
| Notifications navigation | `/message/output/popup/notifications.php` | `VERIFIED_UI` (`UI-NOTIFY-001`) | Yes | Notification control/route is present; content was not opened to avoid changing read state | No Notifications feature yet |
| Messages navigation | `/message/index.php` | `VERIFIED_UI` (`UI-MESSAGE-001`) | Yes | Navigation is present; the target rendered a generic error state, so message data availability is `UNKNOWN` | No Messages feature planned at current gate |

## Boundaries

- Authenticated HTML is discovery evidence only. It is not a supported production data source for Flutter.
- Browser `MoodleSession` and web `sesskey` are never extracted or reused.
- UI visibility does not prove a mobile API function, service permission or Moodle capability.
- No write control was activated. The observed Calendar create-event control is only UI evidence and does not authorize a write test.
