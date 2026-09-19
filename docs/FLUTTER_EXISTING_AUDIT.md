# Flutter existing-code audit

**Date:** 2026-09-18
**Scope:** Flutter client in this worktree only; this is an inventory and
classification, not a proposal to replace the application.

## Evidence boundary

- Current Flutter worktree HEAD is `04c5add` — `feat: add read-only student
  support staging integration`.
- The current verified toolchain record is Flutter **3.44.9** with Dart
  **3.12.2**. `pubspec.yaml` requires Dart `^3.12.2`.
- The project manifest names `dlu_lms_mobile`, is not published, and declares
  `dio`, `flutter_riverpod`, `flutter_secure_storage`, `go_router` and
  `supabase_flutter`; the test/lint dependencies are `flutter_test` and
  `flutter_lints`.
- The checked code and current test record show 24 Dart test files and 93
  `test`/`testWidgets` declarations. The latest recorded Flutter gate for this
  worktree is format/analyze/test PASS with 93 tests.
- This audit does not read or reproduce any `.env` file. The repository ignore
  rules exclude `.env`, `.env.*`, signing/key files, APK/AAB artifacts, local
  SDK/emulator/AVD directories, build output, Gradle state and Pub cache.

`04c5add` is an explicitly selected, **read-only** Student Support staging
consumer. It adds `main_staging.dart`, an HTTPS/GET-only client, typed staging
repositories, boundary tests and eight emulator screenshots. It is not selected
by `main.dart`; it is not DLU password authentication; it does not implement
uploads, submissions, grading, or any other write operation. No secret,
credential, token, or database connection value is part of this audit.

## Classification meanings

| Classification | Meaning in this audit |
| --- | --- |
| **KEEP** | Retain as the current supported foundation and evolve without replacing it. |
| **REFACTOR** | Preserve behavior/coverage, but extend or reshape it before a verified live capability depends on it. |
| **LEGACY_OUT_OF_SCOPE** | Deliberately retained development-only or prior-scope code; not selected by the current staging or production composition root. |
| **REMOVE_ONLY_IF_SAFE** | Local/generated material that is not a source input; delete only after an exact ownership and regeneration check. No deletion is authorized by this audit. |
| **NEW_REQUIRED** | Not present as a verified implementation and must wait for its documented contract/authority before being added. |

## Platform, toolchain, and project manifest

| Area | Evidence in workspace | Classification | Rationale / constraint |
| --- | --- | --- | --- |
| Flutter/Dart baseline | Flutter 3.44.9, Dart 3.12.2; `sdk: ^3.12.2` | **KEEP** | Matches the current verified Flutter gate. |
| Dependency set | `dio`, Riverpod, secure storage, GoRouter, Supabase client | **KEEP** | All are used by the existing architecture; no duplicate networking/state/routing framework is present. |
| Android application foundation | `vn.edu.dlu.lmsmobile`; Java 17 compile options; Internet permission; cleartext disabled | **KEEP** | Android target is present without Android Studio dependency. Release signing remains intentionally unconfigured. |
| Other generated platform directories | Android plus generated Flutter platform folders exist in the project tree | **KEEP** | They are framework-owned platform scaffolding, not an invitation to re-scaffold the app. |
| Generated build/cache/toolchain state | `build/`, `.gradle/`, `.dart_tool/`, local SDK/emulator/AVD/Pub-cache patterns are ignored | **REMOVE_ONLY_IF_SAFE** | They are not Git inputs. Any cleanup must verify the exact local path and preserve active toolchain state. |

## Composition roots, configuration, routing, and state

| Area | Evidence in workspace | Classification | Rationale / constraint |
| --- | --- | --- | --- |
| Bootstrap composition roots | `main.dart`, `main_development.dart`, `main_staging.dart` | **KEEP** | Production, fixture development, and staging are explicitly separate. `main.dart` uses production configuration and does not silently select fixture or staging repositories. |
| App configuration | `AppConfig` has development, staging and production environments and validates HTTPS LMS origins | **KEEP** | The configuration boundary prevents development fixtures outside development mode. |
| Navigation | GoRouter routes: Splash, Login, Dashboard, Courses, Calendar, Profile, Course Detail, Assignment Detail and Grades | **KEEP** | Existing redirects use `AuthState`; path parameters are URI encoded; staging detail routes add a read-only frame. |
| State management | Riverpod providers, `StateNotifier<AuthState>`, and `FutureProvider.autoDispose` feature queries | **KEEP** | This is already the shared presentation state pattern and has route/widget coverage. |
| Authentication session model | `AuthSession` currently has `userId` and `displayName`; `AppUser.roleLabel` is display data | **REFACTOR** | Keep the current fail-closed flow, but a verified live authorization contract needs typed role/capability/session fields rather than treating a display label as authority. |
| Role-aware navigation and authorization | No verified Moodle role/capability adapter is present | **NEW_REQUIRED** | Add only after DLU supplies approved authentication and capability evidence; it must be enforced by the backend/Moodle rather than only by presentation routing. |

## Core safety, networking, storage, and external-data boundaries

| Area | Evidence in workspace | Classification | Rationale / constraint |
| --- | --- | --- | --- |
| Failure and user-message layer | Typed `AppFailure` subclasses and `failure_message.dart` are used by async screens | **KEEP** | Preserves sanitized, user-facing error mapping instead of surfacing raw transport errors. |
| Moodle client boundary | `MoodleApiClient` validates same-origin requests, applies an authorizer only when required, and sanitizes diagnostics | **KEEP** | It is a safe foundation, not proof of a live Moodle service. The default authorizer is unconfigured/fail-closed. |
| Production repositories | Unconfigured auth/course/content/assignment/grade/calendar/user repositories return configuration failures | **KEEP** | This is the correct current behavior while Moodle mobile authentication and Web Services remain unverified. |
| Secure token abstraction | `SecureTokenStorage` wraps `flutter_secure_storage` under the `moodle_access_token` key | **KEEP** | The abstraction exists but is not a substitute for an approved DLU authentication flow. |
| Student Support staging API client | `StudentSupportApiClient` is HTTPS-only, same-origin and GET-only, with a static route allowlist and typed envelopes | **KEEP** | Retain as a distinct staging adapter. It must remain outside `main.dart` and must not become a production fallback. |
| Student Support staging repositories | `Staging*Repository` adapters map profile, courses, content, assignments, grades and calendar data into existing domain contracts | **KEEP** | They demonstrate repository interchangeability for the verified read-only staging contract only. |
| Development fixtures | `SyntheticFixtureDataSource` and `Dev*Repository` classes are injected only by `main_development.dart` | **LEGACY_OUT_OF_SCOPE** | Retain for offline development/tests; do not promote them to production or staging fallback. |
| Supabase app-owned preferences | Typed config/client/identity/mobile-preferences layers exist; default identity is unconfigured | **KEEP** | It remains a separate app-owned preferences foundation, not a Moodle clone and not the source for courses, grades or assignments. |
| Live Moodle DTOs and repository adapters | No DLU-specific successful API response/approved function contract is present | **NEW_REQUIRED** | Implement only after the documented external blockers are resolved; do not infer endpoints, service names or credentials. |
| Upload, submission, grading and teacher write APIs | Current staging client is GET-only; no approved DLU write contract exists | **NEW_REQUIRED** | Do not fabricate client writes or connect Flutter directly to a Moodle database. |

## Feature modules and presentation layer

| Area | Evidence in workspace | Classification | Rationale / constraint |
| --- | --- | --- | --- |
| App shell and responsive UI | Material 3 app, shared spacing/radius/layout tokens, navigation bar/rail shell and staging read-only notice | **KEEP** | The current implementation is the common production-quality visual foundation. |
| Theme | `AppTheme.light/dark`, Material 3 seed scheme, and in-memory `ThemeMode` provider | **KEEP** | It is already wired into `MaterialApp.router`; persistence is not currently wired to the Supabase preferences repository. |
| Theme preference synchronization | Remote `mobile_preferences` repository exists but is not wired to `appThemeModeProvider` in the inspected bootstrap | **REFACTOR** | Retain both sides and join them only with an approved identity/session mapping; do not add an unverified identity bridge. |
| Splash and login | Splash route plus auth controller and login UI with production fail-closed messaging/staging preview behavior | **KEEP** | Login must continue to avoid presenting unapproved DLU credential exchange as operational. |
| Dashboard | Courses, upcoming assignments and upcoming events use typed async states and retry | **KEEP** | It already consumes the repository contracts and has widget coverage. |
| Courses and content | Course list/detail, sections, assignment/resource activities, resource information sheet | **KEEP** | Keep the feature-first domain/presentation separation and replace only the repository implementation when a real contract exists. |
| Assignments and grades | Typed status/grade models, assignment detail and grade screens | **KEEP** | Current behavior is read-only; nullable cutoff/minimum fields correctly avoid fabricating unavailable values. |
| Calendar and profile | Typed calendar repository, profile model and profile/theme UI | **KEEP** | Uses loading/error/success state and existing repository contracts. |
| Teacher workflow | No teacher-specific domain, route, repository or presentation module is present in the inspected tree | **NEW_REQUIRED** | Add after verified role/capability and test-environment permissions; do not reuse a label alone as authorization. |

## Domain model and repository inventory

The current feature-first domain contracts are suitable to retain:

- `CourseRepository` / `Course`, `CourseContentRepository` / `CourseSection` /
  `CourseActivity`;
- `AssignmentRepository` / `AssignmentDetail` / `SubmissionState`;
- `GradeRepository` / `GradeEntry`;
- `CalendarRepository` / `LearningEvent`;
- `UserRepository` / `AppUser`; and
- `AuthRepository` / `AuthSession`.

The required refactor is confined to the authentication/authorization shape when
an approved live contract is available. The existing contracts and provider
boundaries should be extended rather than bypassed with direct UI network calls.

## Test, asset, and evidence inventory

| Area | Evidence in workspace | Classification | Rationale / constraint |
| --- | --- | --- | --- |
| Automated tests | Core, app, feature, fixture and staging-client/repository/config tests; 93 declarations in 24 Dart test files | **KEEP** | Continue adding deterministic mapper, failure, state and route tests alongside changes. |
| Staging emulator evidence | Eight screenshots under `docs/screenshots/student-support-staging/` cover Dashboard through Profile | **KEEP** | They evidence the verified read-only walkthrough and should not be confused with live DLU evidence. |
| Declared Flutter asset | `database/fixtures/dlu_lms_fixture.json` | **LEGACY_OUT_OF_SCOPE** | It belongs to the development fixture entrypoint, not the production or staging composition root. |
| Schema/seed files | Reviewed synthetic Moodle subset files under `database/moodle_subset/` | **LEGACY_OUT_OF_SCOPE** | Retain as documented synthetic analysis/development material; not a runtime production data store. |
| APKs/logs/transient exports | Ignored by `.gitignore` | **REMOVE_ONLY_IF_SAFE** | Not source-controlled; preserve only if required as external evidence and never stage by default. |

## Non-destructive next boundary

The existing Flutter code should be extended from its present repository and
composition-root boundaries. The next production-facing implementation cannot be
classified as ready until DLU provides an approved mobile authentication method,
Web Services/function/capability evidence and a test identity. Until then,
`main.dart` remains fail-closed; the fixture and Student Support staging paths
remain explicitly isolated and read-only.
