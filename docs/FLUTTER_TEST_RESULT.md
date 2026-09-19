# Flutter verification — 19/09/2026

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
