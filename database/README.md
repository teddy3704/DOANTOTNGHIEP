# Group database: isolated restore preparation

STATUS: **BLOCKED** for restore/runtime verification; read-only preparation only.
Date: 2026-10-27. No database connection, import, seed, migration or backend
startup is authorized by these files. Keep the existing system unchanged.

> **Update 2026-10-31 (Claude):** the exact backup is available again at `D:\doan\lms_mobile_learning_backup.sql`; SHA256 re-verified as `936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4`. File availability is resolved; restore remains gated (no approved target or import authorization). See docs/HANDOFF.md.

## Evidence and current blocker

The reviewed original was
`C:\Users\admin\Downloads\lms_mobile_learning_backup.sql`, with SHA256
`936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4`.
That path is currently unavailable. The project owner must restore/provide the
exact original local artifact and confirm its source and permission to use it.
Do not reconstruct it from mock files, old DDL, startup code or an old database.

Evidence retained in
`D:\DLU-LMS\Artifacts\GroupReview-2026-10-26\DATABASE_TAKEOVER_NOTES.md`
is a prior **static** inventory, not live PostgreSQL verification:

| Snapshot item | Expected |
| --- | ---: |
| Application schemas | `app`, `lms`, `derived` |
| Physical tables | 44: 37 `lms`, 7 `app` |
| Derived views | 21 |
| Physical columns | 583 |
| Primary / foreign / UNIQUE constraints | 44 / 41 / 15 |
| Explicit `CREATE INDEX` statements | 104 |
| COPY blocks / sequence setval statements | 44 / 42 |
| OWNER statements | 71 |

The 104 statements are not an expected total `pg_index` row count: constraints
also create indexes. The 71 OWNER statements are not an ownership policy or an
expected distinct-owner count. No row-count baseline is available here.

The present backend schema contains 39 tables and 20 views. The captured review
records five additional snapshot tables (`app.flashcards`,
`app.learning_reflections`, `app.teacher_notes`, `lms.cohort`,
`lms.cohort_members`) and `derived.student_academic_profile`. Existing table/view
definitions reportedly matched the snapshot after whitespace normalization;
the missing original must be rechecked before restore.

## Required evidence before isolated restore

1. `GROUP_DATABASE_DUMP_REQUIRED`: project owner supplies the original local
   dump and its provenance/usage permission; verify SHA256 without displaying
   COPY rows. A different hash is a new artifact requiring a fresh review.
2. `ISOLATED_POSTGRES_TARGET_REQUIRED`: operator identifies and approves a
   new, empty target database and connection endpoint, with written evidence
   that it is not the old system or DLU production. No existing target is reused
   or cleared. The script's database-name check does not validate host/port.
3. `POSTGRES_COMPATIBILITY_REQUIRED`: operator confirms compatible client and
   server. Reviewed header says PostgreSQL/pg_dump 18.6; this is plain SQL for
   `psql`, not a custom archive for `pg_restore`. It contains `\restrict`,
   `\unrestrict` and `SET transaction_timeout`. Do not strip commands to force
   an unsupported restore. This note does not authorize software installation.
4. `RESTORE_OWNER_MAPPING_REQUIRED`: database operator reviews the 71 OWNER
   statements and approves target ownership/least-privilege roles. Do not
   recreate privileged source roles, change passwords, edit `pg_hba.conf`, or
   modify server settings. Application runtime access and restore authority
   must be separate. Credentials stay in the operator's normal local secure
   workflow; never paste them into chat, source files or command arguments.
5. `RESTORE_EXECUTION_APPROVAL_REQUIRED`: explicit approval for the actual
   restore after the above evidence exists. Review dump SQL as executable code;
   stop on errors, keep logs local/restricted and redact data/context before
   reporting. This directory deliberately provides no restore command/script.

Do not put the raw dump, credentials or restored personal data into Git, cloud
uploads or the transcript. Successful restore alone would not prove DLU live
integration, authorised data provenance, valid authentication or safe ownership.

## Read-only verification script

`verify_group_catalog.sql` is a **psql** script to run only after an approved
isolated restore, before any migration or seed changes the baseline. It contains
no connection string or secret and does not initiate a connection itself.
Use a fresh dedicated approved connection with startup files disabled (`-X`),
not a reused session with pending work/an open transaction. Set the psql
variable `expected_database` to the approved target name and execute this file.
Verify host/port separately first. Missing/mismatched target names cause an
immediate stop. Guards use a
deliberate read-only division-by-zero assertion, with a preceding `BLOCKED`
message; `ON_ERROR_STOP` stops a batch with exit code 3. Do not disable guards
to accept another database shape. This follows the documented
[psql script/error behaviour](https://www.postgresql.org/docs/18/app-psql.html).

The script:

- Uses a repeatable-read, read-only transaction and ends with `ROLLBACK`;
  limits each statement to 30 seconds and lock waits to 5 seconds.
- Compares table/view/column/constraint counts and all 65 expected relation
  names, reports auth table presence, owners and current-role privileges.
- Reports missing/nullable flashcard ownership metadata and unvalidated
  constraints. Zero app foreign keys matches the snapshot but is a known risk,
  not a positive security result.
- Checks required columns before reading data. Cohort columns and new view
  aliases are deliberately not guessed from their names.
- Outputs only metadata and aggregate counts: app owner/user/course orphan
  checks plus assignment/quiz module-instance and course consistency checks.
  No user IDs, usernames, passwords, hashes, emails, free text, row exports or
  view bodies are output. Counts can still be sensitive: keep reports local.
- Sets `row_security = off` so affected reads fail rather than silently count
  a policy-filtered subset; this grants no bypass rights. Permission/RLS
  failures are stop conditions, not permission to elevate or alter policies.

`MATCHES_SNAPSHOT` means only that one inventory value matches. Exit code zero
means queries completed, **not** that their reported integrity counts were zero.
Review every reported count; nonzero orphan/mismatch/unvalidated results block
acceptance. An empty table can pass existence checks without proving usable
data. All constraints, exact DDL/index definitions, sequences, all view queries,
API semantics, user/teacher capabilities and data authorisation still require
separate verification. `app.auth_account` creation changes the 44/7/583 baseline;
record an explicitly approved post-migration baseline separately, never quietly
change these expectations to make a run pass.

## Known ownership and authentication gaps

- The snapshot has no foreign keys on `app` tables. Aggregate orphan checks
  only test referenced-row existence, not whether a teacher is entitled to see
  a student/course or the caller owns a record.
- `app.flashcards.userid` is nullable and has a default in the captured dump.
  Original startup code adds it with `DEFAULT 205`; that default is not proof
  of the correct owner. Do not repair/import owners using a demo identity.
- `app.auth_account` is absent from the snapshot. A separate group file,
  `backend/db/auth/001_create_auth_account.sql`, defines it, including a user
  FK and password-hash column. It is **not** part of this baseline and must not
  be run automatically. No login account has been provisioned or tested here.
- Original `LmsMobileBackendApplication.java` contains startup `CREATE TABLE`
  and `ALTER TABLE` operations. Confirm these are disabled/isolated before any
  application or `SpringBootTest` start. Other work may harden this; do not
  assume it has happened from this database README alone.

## Existing scripts: DO NOT RUN during takeover

These files are retained source material, not approved restore inputs:

| Backend-relative file | Observed static risk |
| --- | --- |
| `db/mock/seed_demo_v3.sql` | 1,131 INSERT statements; creates demo data. |
| `db/mock/seed_demo_v4.sql` | 11 INSERT statements; multiple column lists do not match the present DDL (e.g. `user_enrolments.user_id/course_id/role/enrol_time`, `assign.course_id/due_date`, `learning_goals.title/target_date`). |
| `db/auth/002_seed_demo_auth.sql` | Inserts demo auth records; not a real identity/provisioning workflow. Do not display its credential-bearing content. |
| `db/schema/current_mock_data.sql` | 512 INSERT statements and 39 `pg_catalog.setval` calls. |
| `db/audit/lms_mobile_learning_mock_data.sql` | 1,643 INSERT statements and 39 `pg_catalog.setval` calls. |
| `db/schema/lms_mobile_learning_schema.sql` and `db/audit/lms_mobile_learning_schema.sql` | Older DDL, not the complete 44-table/21-view snapshot; executes schema writes. |
| `db/auth/001_create_auth_account.sql` | Separate manual schema mutation; requires review/approval, not automatic execution. |

Counts above are static statement-prefix inventories, not proof a file contains
no other side effects. INSERT-only files still mutate data, can collide with
identities and can pollute a restored snapshot. Do not mix mock/seed files with
the real snapshot or silently fall back to them while the dump is unavailable.

## Handoff

- FILES CHANGED: `database/README.md`, `database/verify_group_catalog.sql`.
- WHAT WAS IMPLEMENTED: isolated-restore prerequisites and count-only,
  read-only verification preparation.
- TESTS: static checks find 44 table names / 21 view names, balanced psql
  conditionals, no statement-leading data/DDL writes, and no `SELECT *` row
  exports. SQL has not been executed or database-parsed; psql was not on PATH
  during this preparation.
- COMMANDS RUN: `git status --short` before preparation (no Git repository yet)
  and after (the parallel root task had initialized Git; files are untracked),
  local metadata/source inspection, and local static checks. No PostgreSQL
  connection.
- RESULT: preparation is PARTIAL; database/API/auth acceptance is BLOCKED.
- BLOCKERS: original dump, isolated target, compatibility, owner mapping and
  explicit restore approval as listed above; valid authorised test accounts
  are also needed for later auth/runtime tests.
- NEXT STEP: receive/review the exact original and operator evidence; only then
  propose a scoped restore for explicit approval. No commit or cutover performed.
