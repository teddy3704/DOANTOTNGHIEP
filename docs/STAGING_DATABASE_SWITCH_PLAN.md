# GROUP_39_20 staging switch — APPLIED / PASS

## Applied and verified

The user privately applied the candidate connection and `DATABASE_MODEL=group_39_20`.
Render deployment `dep-danalep42hec73drngpg` (code `f9d3ff6`) is Live.
Post-switch public health/docs/OpenAPI, both Student scopes, both Teacher scopes,
course content/monitoring, negative 401/404 and query override controls PASS.
Five Teacher GET routes are published; no academic writes. The script
`integration-api/scripts/staging-group-smoke.ts` reproduces these checks without
loading database credentials. Mobile Student/Teacher emulator QA PASS (15 real
screenshots; see `FLUTTER_TEST_RESULT.md`). Previous 22/10 database and deploy
remain intact. The following plan and
handoff description are historical; do not repeat the restore or secret change.

## Proven locally

- Candidate restore/catalog/view/app checks PASS (3/39/20, 39 PK, 38 FK, 548 columns).
- Student contract/identity/course-scope HTTP checks PASS; minimum read-only
  Teacher API and cross-course 401/404 controls PASS.
- Backend 54 tests, formatting, typecheck and build PASS. No Flutter change yet.
- Fixed synthetic aliases only; no DLU authentication or academic writes.

## Before switching

1. Preserve current Neon branch/database and existing local 22/10 DDL/seed backup.
   Keep the old Render secret privately in the user's configured current `.env`;
   never copy it to this document, Git, screenshots or Postman.
2. Deploy the verified backward-compatible backend code to the existing Free
   service, using the existing deployment branch only; no main merge/force push.
   Root `integration-api`; build `npm ci --include=dev && npm run build`;
   start `npm start` (verified against existing Render settings).
   Keep `DATABASE_MODEL` absent/default `current_22_10` for this code-only deploy.
3. Verify current public `/health` and SV001 courses still work; record deployed
   commit. Keep old APK and screenshots available.

## Switch (only after the above gates)

4. In one Render environment update set `DATABASE_MODEL=group_39_20` and replace
   `DATABASE_URL` with the private candidate connection. Retain `APP_ENV=staging`
   and `DEMO_AUTH_ENABLED=true`. Candidate endpoint/database are strictly guarded.
   If secure secret transfer is unavailable, stop at
   `ACTION_REQUIRED_RENDER_DATABASE_SECRET`; user enters it privately.
5. Redeploy and verify public health, Student profile/courses/content/grades/
   progress, both Teacher profiles/courses/overview/monitoring, cross-course 404,
   missing identity 401, `/docs` and `/openapi.json`. No academic writes.
6. Only after deployed Teacher verification, replace Flutter staging Teacher
   fixture injection with the GET-only API adapter. Run targeted tests, one final
   Flutter gate/build and real Student/Teacher emulator walkthrough. Keep main.dart
   fail-closed and official submission/grading on LMS. Never silently fall back.

## Rollback

- If any backend public gate fails, restore the previous Render database secret
  and `DATABASE_MODEL=current_22_10` together, redeploy and verify old Student
  health/courses. Backward-compatible code keeps the legacy adapter available.
- If code itself fails, restore the known-good previous Render deploy/commit.
- Do not delete either database or branch. Do not use migration rollback SQL on
  the current database. Do not leave an unverified mobile APK as the final demo.

## Current disposition

Code-only deployment **PASS**: `f9d3ff6d5134176ffb81a403f3149dc08265f6fd`,
existing service `srv-dalmjc6k1f9s738oqua0`, deploy `dep-dan6e93tqb8s73a8qd8g`.
Pushed non-force to the existing `integration-api-render-staging` branch; main
unchanged. Render reports Live; visible build/start logs contain no connection
string or obvious credential assignment. Public health is 200/reachable, SV001
courses 200/count 2, missing identity 401, docs/OpenAPI 200.

Database switch: **NOT_APPLIED**. Render/current Neon remain 22/10; public OpenAPI
has no Teacher paths while the legacy model is active. Local candidate API
verification is not proof of a deployed Teacher API. The environment secret
handoff/switch is next, before Flutter integration. Known-good previous deploy:
`dep-damac6ek1f9s73e7lgtg` (`4eac146`). Both databases remain available.

Human handoff: **ACTION_REQUIRED_RENDER_DATABASE_SECRET**. Existing environment
editor is open; `DATABASE_MODEL=group_39_20` is an unsaved draft. Replace the
existing database connection privately with the candidate value from the ignored
candidate config, then use Save, rebuild, and deploy. Do not save only the model
change. No environment update has been submitted. After confirmation, resume
public checks in step 5; do not restore the already populated candidate again.
