# Flutter verification — current GROUP_39_20 staging, 22–23/09/2026

## Final checkpoint — PASS for read-only staging demo

- `dart format .`: PASS, 123 files, 0 further changes; `flutter analyze`: PASS.
- `flutter test`: **167 PASS**, one opt-in live test skipped by default. The
  separate opt-in real Render payload test PASS for SV001/SV002 profiles, overview,
  courses, content, assignments, grades, calendar and GV001 monitoring.
- Existing backend suite: **54 PASS** before this Flutter-only continuation;
  backend runtime source did not change.
- `flutter build apk --debug -t lib/main_staging.dart`: PASS. APK installed with
  `adb install -r` on existing `DLU_LMS_Pixel` (Android 15 x86_64).
- APK: `D:\DoAnTotNghiep\evidence\mobile\DLU_LMS_Support_staging_final_debug.apk`,
  221142809 bytes, `vn.edu.dlu.lmsmobile`, minSdk24, targetSdk36, SHA256
  `CD8F6F80E9FE5E9747DA02AC134C37E06863E56AC938476FB78992CE8A03EF93`.
  This is a staging debug APK, not a signed production release.

Emulator Student runtime PASS: SV002 session restore and Profile (empty department
handled), Home, three Courses, Course Detail with assignment/quiz, Assignment
Detail/status, Grades, Progress and empty upcoming/reminder states. Student
assignment CTA opened the official `https://lms.dlu.edu.vn/` in Chrome. SV001
was then selected and loaded its own Home/Profile.

Emulator Teacher runtime PASS: GV001 Home, two own Courses, course detail, four
course-scoped Student monitoring records and expanded progress, Work/assignment
counts, Calendar, Profile and official LMS grading CTA. Switching GV001 → SV001
changed identity, course/progress content and navigation to Student-only; no
Teacher work remained in the Student shell. Public scope tests also cover GV002,
cross-course 404, missing/mixed identity 401 and query override 400.

`NOTIFICATION_RUNTIME = NOT_VERIFIED`: Android notification permission is granted,
but current read-only staging assignments have no future due dates and the app
has no eligible reminder to schedule 1–2 minutes ahead. No synthetic future date,
clock shift or notification screenshot was introduced. Render Free cold start
exceeded a restore timeout once after emulator restart; explicit role selection
then loaded the real API and completed QA. This limitation belongs in the demo
warm-up checklist.

Real screenshots: `evidence/mobile/group39-20-final/` (15 PNGs; no fake
notification image). Offline council backup: `evidence/council-backup/group39-20-final/`
(ignored by Git), 9 reviewed inputs and 15 screenshots; old 22/10 backup retained.
Storage after backup: C 38.72 GB, D 87.19 GB. No Android Studio or new AVD.

DLU Authentication/Web Services remain TO_VERIFY_DLU. The staging development
database is synthetic; official submission and grading remain on DLU LMS.

## Historical verification — 19/09/2026

## Final quality gate

- `dart format .`: PASS, 117 files (2 formatted in final batch).
- `flutter analyze`: PASS, no issues, 96.4 seconds.
- `flutter test`: **150 PASS**, 29 seconds. Role/route isolation, Student API
  contracts, fail-closed production, LMS origin validation, reminder persistence
  and scheduler/widgets, Teacher 320/390px with text scale 1.3 included.
- `flutter build apk --debug -t lib/main_staging.dart`: PASS, 180.7 seconds.
  One final build after label/contrast edits; no subsequent Flutter source change.
- APK: `D:\DoAnTotNghiep\evidence\mobile\DLU_LMS_Support_staging_2026-09-19-debug.apk`
  **221140410 bytes**, `vn.edu.dlu.lmsmobile`, v0.1.0 (1), minSdk24, targetSdk36.
  Debug/staging, not signed production release.
- SHA256: `612CE05B56633C915531D24446962BCD298B0BC64C1FEDF5B73611E75F492DE1`.
- `adb install -r`: Success, DLU_LMS_Pixel / emulator-5554, Android15 x86_64.
  Scope/reminder survived update. Free storage afterward: C36.57GB, D87.87GB.
  SDK/cache/build on D; no Android Studio or new AVD/dependency install.

## Runtime

Final app-process log scan: 0 matches for fatal crash, ANR, RenderFlex, uncaught
or Flutter framework exception markers. Notification permission remains granted
and app alarm registration remains present after the APK update.

Student PASS: identity restore, Home, Courses, Course Detail/resources,
Assignment list/detail, Progress and Profile. Reminder save/restore across
navigation, role change/restart and enable/disable work. Human granted notification
permission; Android alarm registration verified. **Future delivery not observed.**
Student “Nộp bài trên LMS” opens secure official LMS in external Chrome.
No login, upload/submission or private academic data extraction was performed.

Teacher fixture PASS: Home, teaching Courses, sections/resources, Work counts,
Calendar, Profile and switch back to Student. “Chấm bài trên LMS” opens official
LMS, not a grading form. Fixture is not a deployed Teacher API and is not
synchronized with Student Render data.

Final real screenshots: `evidence/mobile/01_student_home_final.png` through
`09_open_lms_final.png`. Generic action reads “Mở LMS”. An intermediate scrolled
Progress capture hid the title; a top-of-list recapture confirms no clipping.

Native Computer Use capture failed with monitor-crop errors after runtime reset;
user-authorized ADB UI inspection/capture continued. Build warnings are
nonblocking: flutter_timezone KGP future migration and SDK XML version warning.
Review on the next toolchain upgrade, not by installing Android Studio.

Overall council status **PARTIAL**: group schema export and Teacher API alignment
remain incomplete; official DLU auth/Web Services unverified. Activity-specific
deep links also PARTIAL: safe official-home handoff only.
