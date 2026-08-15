# Schema Sources

**Subset:** `MOODLE_SUBSET_V1`

**Source status:** `TEACHER_SCHEMA_REFERENCE`

**Reference captured:** 2026-08-15 ICT

## Evidence boundary

This project uses three non-interchangeable evidence labels:

| Label | Meaning in this project | What it can prove |
|---|---|---|
| `TEACHER_SCHEMA_REFERENCE` | A schema page selected by the thesis supervisor and inspected at `moodleschema.zoola.io`. | The tables, columns, indexes and relationship annotations displayed for that reference snapshot. |
| `DLU_LIVE_EVIDENCE` | Sanitized evidence observed from an approved DLU environment. | Only the exact live behavior or contract recorded by that evidence. It does not currently prove a physical database schema. |
| `SYNTHETIC_DATA` | Deterministic, fictional development/test records generated locally. | Fixture behavior and referential consistency inside the project subset only. It does not prove DLU data, users, configuration or behavior. |

No `DLU_LIVE_EVIDENCE` is used to assert a table, column, database engine, table prefix or physical relationship in `MOODLE_SUBSET_V1`. Synthetic records must never be relabeled as live DLU evidence.

## Pinned teacher reference

| Property | Recorded value |
|---|---|
| Site | [Moodle LMS 3.9 Database schema](https://moodleschema.zoola.io/) |
| Generator | SchemaSpy |
| Schema label | Moodle LMS 3.9 |
| Generated | 2020-08-12 15:51 GMT |
| Database type | MySQL 5.7.31 |
| Inventory shown | 461 tables, 0 views, 4,147 columns, 521 constraints |
| Project classification | `TEACHER_SCHEMA_REFERENCE` |

The reference is a historical Moodle 3.9 snapshot. It is not evidence that `https://lms.dlu.edu.vn` runs Moodle 3.9, MySQL 5.7.31, the same plugins, the same constraints, or any particular table prefix.

## Selected-table source register

These are the only physical-schema pages used for the 20-table subset. `Inspected` records a direct inspection of the linked table page; `Used` means the table is included in `MOODLE_SUBSET_V1`, not that a corresponding DLU production table or API has been verified.

| Table | Source URL | Inspected | Used | Tier |
|---|---|---|---|---|
| `user` | [user](https://moodleschema.zoola.io/tables/user.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `course` | [course](https://moodleschema.zoola.io/tables/course.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `enrol` | [enrol](https://moodleschema.zoola.io/tables/enrol.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `user_enrolments` | [user_enrolments](https://moodleschema.zoola.io/tables/user_enrolments.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `course_sections` | [course_sections](https://moodleschema.zoola.io/tables/course_sections.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `modules` | [modules](https://moodleschema.zoola.io/tables/modules.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `course_modules` | [course_modules](https://moodleschema.zoola.io/tables/course_modules.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `resource` | [resource](https://moodleschema.zoola.io/tables/resource.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `assign` | [assign](https://moodleschema.zoola.io/tables/assign.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `assign_submission` | [assign_submission](https://moodleschema.zoola.io/tables/assign_submission.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `assign_grades` | [assign_grades](https://moodleschema.zoola.io/tables/assign_grades.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `grade_items` | [grade_items](https://moodleschema.zoola.io/tables/grade_items.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `grade_grades` | [grade_grades](https://moodleschema.zoola.io/tables/grade_grades.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | CORE |
| `course_categories` | [course_categories](https://moodleschema.zoola.io/tables/course_categories.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |
| `files` | [files](https://moodleschema.zoola.io/tables/files.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |
| `context` | [context](https://moodleschema.zoola.io/tables/context.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |
| `role` | [role](https://moodleschema.zoola.io/tables/role.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |
| `role_assignments` | [role_assignments](https://moodleschema.zoola.io/tables/role_assignments.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |
| `course_modules_completion` | [course_modules_completion](https://moodleschema.zoola.io/tables/course_modules_completion.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |
| `event` | [event](https://moodleschema.zoola.io/tables/event.html) | Yes — 2026-08-15 | Yes — `MOODLE_SUBSET_V1` | SUPPORTING |

The table names above are the names shown by the reference. They do not establish a DLU production prefix. In particular, this project must not assume `mdl_` for DLU.

## Relationship evidence vocabulary

Every relationship in the subset documentation must use one of these labels:

1. **Declared FK** — the table page names a parent/child constraint.
2. **SchemaSpy implied constraint** — the page explicitly displays `Implied Constraint`; this is weaker than a declared FK.
3. **Application-polymorphic link** — Moodle resolves the target using a discriminator plus an ID; no single physical FK can express the link.
4. **Project subset constraint** — a local integrity rule used by `SYNTHETIC_DATA`; it must not be described as a reference or DLU constraint.
5. **Unresolved** — the selected source pages do not establish the relationship strongly enough.

Important non-FK or unresolved paths include:

- `course_modules.module -> modules.id` is a declared FK, but `course_modules.instance` points to a module-specific table only after interpreting `modules.name`; the links to `assign.id` and `resource.id` are application-polymorphic.
- `course_modules.section -> course_sections.id` is useful to the feature model, but the inspected reference page does not declare it as a physical FK.
- `grade_items.iteminstance -> assign.id` is conditional on grade-item discriminator fields such as `itemmodule`; it is application-polymorphic, not a declared FK.
- `files` associates metadata through `contextid`, `component`, `filearea` and `itemid`; `itemid` is not a universal FK to `resource`, `assign` or `assign_submission`.
- `context.instanceid` is interpreted according to `context.contextlevel`; it is not a universal FK to a single entity table.
- `event.courseid` and `event.userid` are displayed by the reference as implied constraints, while `event.modulename` plus `event.instance` is a logical activity link.

## Use restrictions

- This source set supports analysis, a reduced local schema and synthetic fixtures; it does not authorize access to a DLU database.
- The mobile application must access production data through HTTPS and an approved Moodle application/API layer, never by querying these tables.
- Password hashes, auth secrets, tokens and private configuration are outside the subset even when the reference schema documents them.
- A future DLU schema artifact must be recorded separately as `DLU_LIVE_EVIDENCE` and compared explicitly. It must not silently replace or retroactively validate this reference.
- If the reference site changes, retain this version pin in documentation and review diffs before changing `MOODLE_SUBSET_V1`.
