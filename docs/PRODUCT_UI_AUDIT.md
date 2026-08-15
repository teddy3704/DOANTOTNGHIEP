# Product UI audit

Audit date: 2026-08-15

Baseline: `e7996e1adaee849e488a35de218531494f8fd2d0`

Device: `DLU_LMS_Pixel`, Android 15 (API 35), 1080 x 2400

Scope: the running development entry point and every user-facing route available at the baseline.

This is the required pre-edit inventory for the production-polish milestone. Internal fixture guards and evidence labels remain valid engineering controls; this audit only removes them from the student-facing experience.

## KEEP

- Material 3 light/dark foundations, DLU LMS wordmark, responsive shell and production fail-closed behavior.
- Login as the only public entry point; development repositories remain injected only by `main_development.dart`.
- Student-facing course search, category, progress and next-deadline information.
- Course overview, collapsible learning content, resources, assignments and course grades.
- Assignment deadline, submission, grade and feedback states.
- Profile avatar, verified identity fields and logout.
- Repository/provider separation and loading/empty/error/retry state contracts.

## REMOVE

- Every visible `DEV`, `FIXTURE`, `MOCK`, `SYNTHETIC`, `DEBUG`, sample/demo label and implementation disclaimer.
- Raw blocker codes, Web Service state, endpoint, token, secure-storage, repository, JSON, schema and environment details.
- Dashboard integration-status hero and the notification button/snackbar without a real notification data source.
- Unverified user identifier on Profile.
- The locally calculated unweighted grade average and decorative grade chart, because Moodle weighting is unknown.
- Resource/assignment warnings that describe internal fixture or API capability gates.

## REWRITE

- Login copy as natural student guidance; production stays fail-closed with one friendly service-unavailable message and no credential fields.
- Loading, empty and error text as task-oriented Vietnamese without backend terminology or raw diagnostic messages.
- Course content terminology from internal `section/activity` language to `chủ đề/nội dung học tập`.
- Deadlines as natural phrases such as `Còn 2 ngày`, `Hôm nay` and `Quá hạn 3 ngày` while retaining the exact date.
- Resource labels as `Tên tệp`, `Định dạng`, `Kích thước` and a neutral unavailable action.
- Generated presentation data to plausible, wholly fictional Vietnamese names and course content. Internal IDs, `@example.test` addresses and `SYNTHETIC_DATA` metadata stay unchanged and non-visible.

## REDESIGN

- Final primary navigation: `Trang chủ`, `Khóa học`, `Lịch`, `Hồ sơ`. No Notifications tab until a real data source exists.
- Dashboard hierarchy: greeting, urgent work, current courses, upcoming calendar items, then secondary progress.
- Courses as compact, scannable cards that remain usable on narrow phones and with large text.
- Course Detail as a clear overview followed by content/resources/assignments/grades, with a scroll-safe resource sheet.
- Grades as a readable list of released grade items without inferred aggregate meaning.
- Calendar as a real screen grouped by day with course context; never show raw Moodle event types or IDs.
- Profile as identity and useful settings only, with no infrastructure details.
- Central spacing/radius/layout tokens, shared section/error/loading components, semantic labels and controlled system-bar contrast.

## Runtime observations

- A first login attempt immediately after a fresh debug install coincided with an Android ANR prompt while the app was still compiling/attaching. Relaunching with the Flutter process attached and waiting for the first frame produced a stable flow. This milestone must repeat a fresh-run test and confirm the prompt does not recur.
- No route crash occurred during the completed baseline walk-through.
- Course Detail contains a nullable-deadline force unwrap and a non-scrollable resource sheet; both are release risks to fix even though the baseline fixture did not trigger them.

## Screen decisions

| Screen | Decision |
|---|---|
| Splash | KEEP; polish system bars and timing only if required by QA. |
| Login | REWRITE; hide all development and backend status details. |
| Dashboard | REDESIGN; remove integration hero and fake notifications. |
| Courses | REDESIGN; retain search and useful course context. |
| Course Detail | REDESIGN; organize student tasks and remove internal terminology. |
| Resource sheet | REWRITE; student labels and scroll-safe layout. |
| Assignment | REWRITE; retain only actionable learning information. |
| Grades | REDESIGN; remove inferred average/chart. |
| Calendar | ADD within approved student scope using the existing repository. |
| Profile | REDESIGN; identity/settings/logout only. |
