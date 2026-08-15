# Synthetic subset validation

Status: **PASS**
Dataset: `SYNTHETIC_DATA`
Version: `MOODLE_SUBSET_V1`
Seed: `202608`

## Automated gates

`tool/validate_moodle_sample_data.dart` exits nonzero when any gate fails. It
currently checks:

- the exact 20-table allowlist and exact selected columns for every row;
- positive and unique primary keys;
- declared FK integrity for the relationships preserved in `schema.sql`;
- reference-declared unique keys used by the projection;
- local polymorphic/module, section, context, file, event, submission, and
  grade join conventions without mislabeling them as physical FKs;
- enrollment uniqueness and enrollment membership for student-owned records;
- exactly 3 synthetic teachers, 20 synthetic students, 4 categories, and 6
  courses;
- 3–8 sections per course and assignment/resource presence in every course;
- future, soon, overdue, draft, submitted, not-submitted, graded, ungraded,
  low-grade, medium-grade, and high-grade coverage;
- `example.test` email domains, `GVTEST`/`SVTEST` identifiers, and absence of
  credential-bearing JSON keys;
- natural presentation copy for identities, courses, sections, resources,
  assignments, feedback and events, with development markers rejected from
  display-facing columns;
- 40-character lowercase hexadecimal file hashes and metadata-only resource
  file relationships.

## Commands

```powershell
dart format tool/generate_moodle_sample_data.dart `
  tool/validate_moodle_sample_data.dart
dart analyze tool/generate_moodle_sample_data.dart `
  tool/validate_moodle_sample_data.dart
dart run tool/generate_moodle_sample_data.dart
dart run tool/validate_moodle_sample_data.dart
```

Observed result on 2026-08-15:

```text
dart analyze: No issues found
SYNTHETIC FIXTURE VALIDATION: PASS
```

## Generated row counts

| Table | Rows |
|---|---:|
| `user` | 23 |
| `course_categories` | 4 |
| `course` | 6 |
| `enrol` | 6 |
| `user_enrolments` | 72 |
| `course_sections` | 33 |
| `modules` | 2 |
| `course_modules` | 30 |
| `resource` | 12 |
| `assign` | 18 |
| `assign_submission` | 103 |
| `assign_grades` | 49 |
| `grade_items` | 18 |
| `grade_grades` | 198 |
| `files` | 12 |
| `context` | 36 |
| `role` | 2 |
| `role_assignments` | 72 |
| `course_modules_completion` | 165 |
| `event` | 18 |

## Reproducibility check

The generator is run twice without changing its inputs. SHA-256 hashes of both
generated outputs must remain byte-for-byte identical. The checked hashes are
recorded below after the final verification run:

```text
dlu_lms_fixture.json: 4F6FF5992E45B6ACAEE1C28180F0D50166D62CA3B419BD29E0188416EC673C37
seed.sql:             5A3EFA1500F2B626A1BEAFB96D6FC172D941DF6D7FE63FAD8080DE7CBD022DC5
```

## MySQL execution scope

The Dart validator establishes data consistency without requiring MySQL. A
MySQL 5.7-compatible parse/load check is optional when that CLI/runtime is
available and must use a new disposable local database. No production or DLU
database is necessary for this validation milestone. The MySQL CLI was not
available on the verification host, so no live SQL load was claimed.
