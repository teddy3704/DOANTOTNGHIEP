# LMS Support Mobile — current scope

| Area | Source / boundary | Current result |
|---|---|---|
| Student identity, courses, content, assignments, grades, progress, deadlines | Verified read-only Render Student Support API; explicit staging selection SV001/SV002 | Automated/runtime PASS |
| Teacher identity, teaching courses, work summaries, monitoring, calendar, profile | Real read-only Render GROUP_39_20 API; course-context guards; TeacherSupportApiRepository | Public API/automated PASS; final runtime record in FLUTTER_TEST_RESULT.md |
| Personal reminders | Mobile-owned secure local metadata + Android local notifications, no academic write | Save/restore/toggle/scheduling PASS; future delivery not observed |
| Official academic actions | One HTTPS exact-host LMS launcher; broad official home until a real activity mapping is approved | Unit/runtime PASS; activity deep links PARTIAL |
| Production identity/API | Default unconfigured adapters fail closed; no staging injection from `main.dart` | TO_VERIFY_DLU |

Mobile submission, quiz submission, grading, feedback entry, course administration
and separate official account/password database: **NO**. Those operations belong
to DLU LMS. Student and Teacher use the same GROUP_39_20 development/staging
database through API repositories. Teacher fixture remains test-only, never an
error fallback. UI marks all staging data as simulated.
