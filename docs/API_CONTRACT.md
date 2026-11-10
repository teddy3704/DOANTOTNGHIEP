# API contract — derived from source 2026-10-31

STATUS: SOURCE_STATIC. Read from current backend/frontend source; no request has been
executed. Runtime verification is task T09. Both agents follow this; change it in one place.

## Authentication

- `POST /api/v1/auth/demo-login` body `{"role":"STUDENT"|"TEACHER"}` only (any other key → 400).
  Exists only with profile `local-development` AND `app.demo-auth.enabled=true`, loopback bind,
  distinct server-configured student/teacher IDs. Not Moodle authentication; never deploy publicly.
  Response: `token`, `role`, `userId` (string).
- Bearer JWT HS256; issuer `dlu-lms-group`; audience `dlu-lms-mobile`; `iat`/`exp` required;
  default TTL 1 h (max 24 h); role ∈ {STUDENT, TEACHER}; subject = positive user id.
  Secret from `JWT_SECRET` (≥32 bytes), no default.
- Any `Authorization` header that is not a valid Bearer token → 401 (no anonymous fallback).

## Authorization rules (SecurityConfig)

| Path | Rule |
| --- | --- |
| `/api/v1/dev/students/{id}/**` | role STUDENT and `{id}` = token subject |
| `/api/v1/dev/teachers/{id}/**`, `/api/v1/teachers/{id}/**` | role TEACHER and `{id}` = token subject |
| `/api/v1/courses/**`, `/api/v1/students/me/**` | role STUDENT |
| `/api/v1/health` | authenticated |
| anything else | denied (403 with valid token, 401 without) |

## Endpoints used by the Flutter app

- Student (dev paths, `{id}` = session user): `dashboard`, `courses`, `tasks`, `continue-learning`,
  `courses/{c}/analytics|learning-items|grades|grade-categories|attendance|tasks`,
  `goals` (GET/POST), `goals/{g}/cancel` (POST), `insights?days=`, `notifications`,
  `notifications/{n}/read` (POST), `reflections` (GET `?courseId=`, POST),
  `courses/{c}/flashcards` (GET/POST, PUT/DELETE `/{f}`).
- Teacher (dev paths): `courses`, `courses/{c}/analytics|students|students/{s}|assignments|`
  `assignments/{a}/students|quizzes|quizzes/{q}/students|class-insights?weeks=`,
  `courses/{c}/reminders` (POST), `notifications`.
- Teacher notes: `/api/v1/teachers/{id}/notes` GET `?studentId=&courseId=`, POST
  `{studentId, courseId, note, status}`, PUT `/{noteId}/status` `{status}`.

## Server-side scope and validation

- Flashcards: caller must be enrolled in the course (`derived.student_course_progress`);
  update/delete match id + course + owner. Not found / not owned → 404.
- Reflections: optional `courseId` must be a JSON integer and an enrolled course → else 400/404;
  `understandingLevel` 1–5; content required.
- Teacher notes: `studentId`, `courseId` positive JSON integers (required on create);
  note 1–10000 chars; status `active|resolved`; teacher must own the course
  (`derived.teacher_course_overview`) and student must be on its roster; filtering by
  `studentId` requires `courseId`; list/update re-check `derived.teacher_student_monitoring`.
- Not called by the Flutter app today: `/api/v1/courses/{c}/flashcards`,
  `/api/v1/students/me/reflections` (STUDENT-only equivalents of the dev paths).
- Errors never include stack traces or messages from the server error page.
