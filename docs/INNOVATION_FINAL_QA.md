# Innovation final QA — 06/10/2026

## Scope and source

`innovation-study-planner-intervention` extends baseline `06ad157` without changing
main. Existing synthetic Neon candidate and Render service are reused. No DLU
database, academic writes, authentication bypass or production fallback is involved.

## Quality gates

| Gate | Observed result |
|---|---|
| Backend | 82 tests, typecheck, build, format PASS; npm audit: 0 vulnerabilities |
| Candidate integrity | Additive migration PASS: original rows, lms columns and derived views unchanged |
| Current catalog | 3 schemas; 42 tables (35 lms + 7 app); 20 views; 42 PK; 45 FK; 588 columns |
| Real API workflow | 181 local and 181 public staging checks PASS |
| Public regression | 165 read-only/negative scope checks PASS after Fastify patch |
| Render | `a0c2cb7` Live, `dep-db2chubl550s73c9p520`, 46.0s; existing secret/environment unchanged |
| Flutter | dart format PASS, analyze 0 issues, 224 tests PASS; 1 opt-in live test skipped by default and separately PASS |
| Accessibility | Widget tests at 320/390px and text scale 1.3; keyboard/forms, loading/empty/error/retry and actual theme contrast PASS |
| APK | Final staging debug build 17.4s, installation Success on existing DLU_LMS_Pixel |

Commands: `dart format .`, `flutter analyze`, `flutter test`,
`flutter test --dart-define=RUN_STAGING_LIVE=true test/dev/student_support_api/staging_live_contract_test.dart`,
`flutter build apk --debug -t lib/main_staging.dart`,
`node --experimental-strip-types tool/innovation_smoke.mjs staging`,
`node --experimental-strip-types integration-api/scripts/staging-group-smoke.ts`.
The live contract/API gates were not rerun unnecessarily for form-only UI polish.

## Installed runtime stories

Student SV001: recommendation reason → create Java Collections study session →
Android reminder scheduled for 17:22 and delivered → postpone to 07/10 → edit to
60 minutes and a personal note → handled → related reminder cancelled. SV002's
week view remained empty; SV001's exact handled plan returned after switching back.
Only this newly created test plan was deleted through its confirmation dialog,
restoring a repeatable presentation. Course/assignment status was not changed.
Official launcher opened the secure `lms.dlu.edu.vn` public page, without constructing
a Moodle URL from staging IDs or entering credentials.

Teacher GV001: attention/inbox → Tran Cuong / Database Systems → contact note →
follow-up after 3 days → restart/update preserved the record → follow-up note →
close → recorded history. Snapshot comparison stayed 29% progress / 4 overdue
items; the app did not claim improvement or causality. No message was actually sent
to a student, and no official grade/submission was changed.

Runtime polish fixed: summary text contrast on the actual dark container;
500-character note limit aligned with the server; required-note error clears on
valid input before another save. Regression tests cover each correction.

## Artifact

`D:\DLU-LMS\Artifacts\DLU_LMS_Support_Innovation_Final_Debug.apk`

- Application ID: `vn.edu.dlu.lmsmobile`
- Version: `0.1.0` / code `1`; minSdk `24`; targetSdk/compileSdk `36`
- Size: `221242818` bytes (multi-ABI debug build, not a signed release)
- SHA256: `D34037F56D4D456D74B119E627A802DCEE4B70283EA7D328792BD70763B6AF06`
- Storage after final build: C `39.59 GB`, D `86.84 GB`; heavy tooling/build/cache stays on D.

## Evidence

Actual PNGs: `evidence/mobile/innovation-final/`, captured using
`node tool/android_innovation_qa.mjs capture <name>`; no baseline screenshot was
overwritten. 01–11 cover the requested stories; 12 is the delivered Android
notification, 13 context isolation, 14 closed history, 15 restored Student plan.
Notification text is generic and contains no academic/identity details.
`evidence/innovation/render-deploy-live.jpg` shows the actual successful patch deploy.
JSON API checks are in `evidence/innovation/local-smoke.json` and `staging-smoke.json`.
These JSON files each contain 181 workflow checks. The separate 165-check
GET-only regression after the Fastify patch is recorded in the runtime checkpoint.

## Handoff recheck — 07/10/2026

Restarted the existing DLU_LMS_Pixel and relaunched the installed final APK;
Student Today restored with zero test plans. No new build, reset, database
mutation or repeat of the completed full test suites was needed. A scoped scan
of the current app process log buffer found zero Flutter exception, RenderFlex,
fatal crash, ANR, navigation-exception and uncaught-async matches. This is not
a claim about unavailable historical log buffers.

Final candidate/index scan PASS: 416 files, zero actual secret matches, indexed
secret matches, private configs or forbidden staged artifacts. Private environment
files and build/cache remain ignored; `git diff --check` PASS. Only source, tests,
safe documentation and actual evidence are included. Main remains `c773b7e`.
The focused source commit and non-force feature-branch push receipt are returned
in the final handoff; Git is the source of truth for the commit hash.

## Limits

Synthetic aliases are demonstration identities, not verified DLU login. Render Free
may cold-start. Reminder delivery is Android inexact scheduling, not an exact-time
guarantee; tapping it opens the app and the user selects Kế hoạch. Teacher snapshot
comparison is descriptive, not an effectiveness prediction. Automated smoke history
is retained as labelled synthetic test history. DLU authentication, Web Services and
official academic actions remain **TO_VERIFY_DLU / LMS ONLY**.
