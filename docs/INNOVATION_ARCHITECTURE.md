# Learning decision support — innovation extension

## Current hardening — 07/10/2026

Current branch `innovation-perfection-hardening` extends preserved `2e04089`.
The baseline sections below are historical: hardening deliberately corrects three
derived definitions (migrations 002/003) and adds five app CHECKs while preserving
every original physical row and column/type signature. Current catalog: 42/20/588.

Priority heuristics are centralized in `domain/priority-rules.ts`; missing deadline
is `null`, missing tracking is not inferred failure. Scoped APIs recheck active
enrolment/course/owner; handled/resolved states cannot be reopened by stale writes.
Five-second identical follow-up protection is bounded transaction retry control,
not durable idempotency. Original-owner Flutter subscriptions survive the network
await but are invalidated on identity changes. Editor and card operations both
pin the original coordinator; confirmation never adopts a newly selected user.

Readiness verifies actual model/workflow surfaces; process liveness is separate.
Pino emits sanitized startup/request/error codes without secrets, headers, bodies
or raw driver diagnostics. Finite HTTPS request timeout is 60s with cancellation
and an 8s slow-loading hint; no silent write retry/fallback. Current Render runs
backend `c5231e2`, existing service, same secret/database. Architecture remains
Flutter → HTTPS → Fastify → scoped academic SELECT + app-owned workflow WRITE.
Official submission/quiz/grading stays LMS ONLY. Candidate owner bypasses RLS;
production requires a SELECT-source/WRITE-app role plus verified DLU identity.

Evidence and current limits: `PERFECTION_FINAL_QA.md`, `DATABASE_HARDENING_AUDIT.md`,
`BACKEND_HARDENING_AUDIT.md`. No second backend or new dependency was introduced.

Branch: `innovation-study-planner-intervention`; baseline preserved at `06ad157`.
This extends the existing Fastify/Neon/Flutter staging system, not a second LMS.

## Implemented boundary

```text
Scoped lms academic reads → Fastify InnovationService → explainable priorities
                                               ↓
Flutter staging repositories → HTTPS → app-owned plan / support workflow
                                               ↓
                                  Neon app.* + local device reminders
Official submission / quiz / grade / administration → DLU LMS only
```

`main_staging.dart` injects the two new API repositories. Presentation uses domain
contracts; `main.dart` does not enable this synthetic staging composition or
silently fall back to it. The HTTPS transport has a separate closed mutation
allowlist; academic endpoints remain read-only. Late responses are rejected if
the selected identity changes.

## Rules actually supported by current data

Student inputs: visible assignments, matching submission status, tracked course
progress, existing personal plan state. Outstanding states: missing,
not-submitted, draft, returned. Unknown status is not assumed missing.

| Signal | Contribution |
|---|---:|
| Overdue / within 24h / within 72h / within 7d / later | 70 / 60 / 45 / 25 / 10 |
| Returned / draft | +20 / +10 |
| Progress below 50%, with tracked activities present | +10 |

Scores cap at 100. High ≥65, medium ≥30, otherwise low. Stable ordering uses
score descending, deadline ascending, assignment ID. Each response includes
Vietnamese reasons; 45 minutes is an adjustable planning default, **not** an
estimate of measured study effort. Planned items remain labelled planned;
handled plan items are omitted from suggestions without altering LMS status.

Teacher signals: overdue tasks (20 each, cap 60), pending tasks (5 each, cap 20),
progress below 50% (+20), cap 100. A zero-score row is not counted as needing
attention. Ordering is stable. Inactivity, attendance and low-grade signals are
not used: current verified contracts do not provide adequate fields. These are
heuristics for teacher attention, not failure predictions or academic decisions.

## Minimal persistence

Migration `integration-api/migrations/001_innovation_support.up.sql` adds only:

- `app.study_plan_items`: owner, actual assignment/course FKs, immutable source
  snapshot, schedule, duration, notes, planned/handled. A separate day/header
  table adds no use case; day/week are projections of the schedule.
- `app.teacher_interventions`: owner teacher, scoped student/course, action,
  reasons and baseline snapshot, next follow-up, open/following-up/resolved.
- `app.intervention_followups`: append-only notes, outcome and observed metrics.

Existing `lms` tables and `derived` views are untouched. New FKs are indexed;
owner/schedule and owner/status/due indexes support bounded reads. A partial
unique index permits at most one active teacher/student/course record.

Snapshots compare source observations, not causal improvement. If metrics do not
change, the UI shows no improvement. Resolving support does not grade a student.

## Ownership and safeguards

Server identity is resolved from the existing fixed staging aliases; client user
IDs are never accepted. SQL rechecks active course roles, visible enrolment and
ownership on reads and writes. Cross-owner inaccessible/nonexistent records use
the same 404. Inputs are closed schemas, 500-character notes, 5–480-minute plans,
bounded record counts, short transactions and 30 workflow writes/minute/actor.

These aliases are **not secure production authentication**. This public synthetic
staging environment holds no real PII. Production deployment requires verified
DLU auth/capabilities, least-privilege database credentials and an authenticated
rate limit; do not repurpose the demonstration selector for real records.

## Migration/rollback

Candidate-only runner: `node tool/innovation_database.mjs rehearse` then `apply`.
Private off-repository baseline backup is retained under
`D:\DLU-LMS\Backups\innovation-2026-10-03`. Rehearsal applies in a transaction
and rolls back. Verification compares every original table's row digest, all
`lms` columns and every derived view. API startup never applies a migration.
Down migration refuses to drop any nonempty workflow table. Once records exist,
rollback the service branch to its previous deployed code and retain the added
tables; export/review and obtain approval before any data-bearing removal.

## APIs

Student: `GET /api/v1/me/recommendations`, `GET /api/v1/me/study-plan`,
`POST /api/v1/me/study-plan/items`, `PATCH/DELETE .../items/{id}`.

Teacher: `GET /api/v1/me/teacher/attention`, `/interventions`, `/followups`,
`GET/PATCH .../interventions/{id}`, `POST .../interventions`,
`POST .../interventions/{id}/followups`.

OpenAPI is generated from actual routes. `tool/innovation_smoke.mjs` verifies
local candidate and public staging, including persistence, forbidden writes and
Student/Teacher isolation. Final result paths and counts belong in PROJECT_STATUS.
