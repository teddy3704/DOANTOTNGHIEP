# MOODLE_SUBSET_V1 — local synthetic dataset

This directory contains a small, reproducible data projection for DLU LMS
Mobile development. It is safe to use offline and contains no record copied
from DLU.

## Classification boundary

- `TEACHER_SCHEMA_REFERENCE`: the table/column/type/declared-FK evidence came
  from the Moodle LMS 3.9 SchemaSpy site at
  <https://moodleschema.zoola.io/>. The site reports MySQL 5.7.31 and a schema
  generation time of 2020-08-12.
- `PROJECT_SUBSET_SCHEMA`: `schema.sql` is a selected-column projection of
  exactly 20 relevant tables. It is not a full Moodle schema and is not
  asserted to match the current DLU deployment.
- `SYNTHETIC_DATA`: `seed.sql` and
  `../fixtures/dlu_lms_fixture.json` are generated locally from seed `202608`.
  They contain 3 fictional teachers, 20 fictional students, `example.test`
  email addresses, and `GVTEST`/`SVTEST` identifiers.
- `DLU_LIVE_EVIDENCE`: none is represented by these files.

Neither the SQL nor JSON is a Moodle database dump. The projection omits many
columns (including authentication secrets), tables, triggers, application
rules, and plugin-specific submission content. It cannot be used to operate a
Moodle site and must never be treated as proof of DLU's production schema.

## Selected tables

`MOODLE_SUBSET_V1` contains exactly:

1. `user`
2. `course_categories`
3. `course`
4. `enrol`
5. `user_enrolments`
6. `course_sections`
7. `modules`
8. `course_modules`
9. `resource`
10. `assign`
11. `assign_submission`
12. `assign_grades`
13. `grade_items`
14. `grade_grades`
15. `files`
16. `context`
17. `role`
18. `role_assignments`
19. `course_modules_completion`
20. `event`

The files are deliberately metadata-only: the `files` rows describe fictional
PDF files, but no binary content is created.

## Canonical JSON contract

The Flutter development layer should consume the single canonical fixture:

```text
database/fixtures/dlu_lms_fixture.json
```

Its stable top-level shape is:

```json
{
  "metadata": {
    "dataset": "dlu_lms_synthetic_development_fixture",
    "version": "MOODLE_SUBSET_V1",
    "seed": 202608,
    "reference_time_epoch": 1786795200,
    "source_classification": "SYNTHETIC_DATA"
  },
  "tables": {
    "user": [],
    "course": []
  }
}
```

All row keys use the exact snake_case Moodle column names selected in
`schema.sql`. There are no app-only state labels inside table rows; UI states
such as future, overdue, submitted, and graded are derived from Moodle-shaped
fields and the fixed `reference_time_epoch`.

## Local synthetic join conventions

The teacher reference exposes several relationships as implied, polymorphic,
or not as a declared physical FK. The fixture needs deterministic joins, so it
uses these explicitly labeled `LOCAL_SYNTHETIC_CONVENTION` rules:

- `course_modules.section = course_sections.id`
- `course_modules.module -> modules.id`, then `instance` resolves to
  `resource.id` or `assign.id` according to `modules.name`
- `resource.course` and `assign.course` resolve to `course.id`
- `grade_items.itemmodule = 'assign'` and `iteminstance = assign.id`
- a module `context` uses `contextlevel = 70` and
  `instanceid = course_modules.id`
- a course `context` uses `contextlevel = 50` and `instanceid = course.id`
- `files.itemid = resource.id` for the owning resource metadata row
- assignment `event.instance = assign.id`

The numeric meanings of context levels `50` and `70` are fixture conventions
for this project; the inspected `context` table page verified the column but
did not document those numeric semantics. None of the logical rules above is
declared as a verified FK in `schema.sql`.

The reference page for `course_modules_completion` lists the column as
`BIT(1)` while its comment discusses states 0–3. To keep this MySQL projection
internally executable, V1 emits only 0/1 completion values. Pass/fail examples
remain represented by `assign_grades` and `grade_grades`; 2/3 completion
semantics are intentionally not modeled.

## Regenerate and validate

From the repository root:

```powershell
dart run tool/generate_moodle_sample_data.dart
dart run tool/validate_moodle_sample_data.dart
```

The generator always uses seed `202608`, a fixed reference time, stable row
ordering, and no network or environment input. It overwrites only the generated
JSON fixture and `seed.sql`. See `validation.md` for the validation gates and
the recorded reproducibility hashes.

## Optional isolated MySQL check

Only load this projection into a new disposable database that is dedicated to
local development:

```powershell
mysql --default-character-set=utf8mb4 synthetic_moodle_subset `
  '<' database/moodle_subset/schema.sql
mysql --default-character-set=utf8mb4 synthetic_moodle_subset `
  '<' database/moodle_subset/seed.sql
```

Never run these files against DLU, an existing Moodle database, or any database
that contains user data. The mobile production path remains Flutter over HTTPS
to Moodle's application/API layer; it must not connect directly to these
tables.
