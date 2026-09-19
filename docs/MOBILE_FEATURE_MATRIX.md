# LMS Support Mobile — current scope

| Area | Source / boundary | Current result |
|---|---|---|
| Student identity, courses, content, assignments, grades, progress, deadlines | Verified read-only Render Student Support API; explicit staging selection SV001/SV002 | Automated/runtime PASS |
| Teacher identity, teaching courses, work/submission summaries, calendar, profile | Explicit staging fixture adapter over existing canonical Moodle subset; GV001 maps to synthetic instructor 101, course-context roles/enrolment constrain scope | Automated/runtime PASS; Teacher API PARTIAL/not deployed |
| Personal reminders | Mobile-owned secure local metadata + Android local notifications, no academic write | Save/restore/toggle/scheduling PASS; future delivery not observed |
| Official academic actions | One HTTPS exact-host LMS launcher; broad official home until a real activity mapping is approved | Unit/runtime PASS; activity deep links PARTIAL |
| Production identity/API | Default unconfigured adapters fail closed; no staging injection from `main.dart` | TO_VERIFY_DLU |

Mobile submission, quiz submission, grading, feedback entry, course administration
and separate official account/password database: **NO**. Those operations belong
to DLU LMS. Teacher fixture is neither a Render Teacher endpoint nor synchronized
with Student API data; it is an explicitly selected read-only development source,
never an error fallback. UI marks all staging data as simulated.
