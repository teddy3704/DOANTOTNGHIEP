# Synthetic Data Policy — MOODLE_SUBSET_V1

## Policy statement

The project dataset is **AI-generated, deterministic and entirely fictional**. It is classified only as `SYNTHETIC_DATA`.

It is not:

- DLU production data;
- a copy or sample of a real student, lecturer, class, course, submission or grade;
- evidence of the live DLU Moodle database or API contract;
- suitable for production fallback.

The structural reference is the thesis-supervisor-provided Moodle LMS 3.9 SchemaSpy snapshot at [moodleschema.zoola.io](https://moodleschema.zoola.io/), classified as `TEACHER_SCHEMA_REFERENCE`. That historical MySQL 5.7.31 reference does not prove the DLU Moodle version, engine, prefixes, plugins, configuration or physical constraints.

## Determinism and canonical source

| Control | Required value |
|---|---|
| Subset version | `MOODLE_SUBSET_V1` |
| Fixed seed | `202608` |
| Fixed reference time | Stored in fixture metadata; generation must not depend on wall-clock time |
| Network access | Forbidden during generation/validation |
| Canonical generator | `tool/generate_moodle_sample_data.dart` |
| Canonical Flutter fixture | `database/fixtures/dlu_lms_fixture.json` |
| SQL projection | `database/moodle_subset/seed.sql` |
| Allowed environments | Development, demo and automated tests only |

The Dart generator is the single canonical authoring path. JSON and SQL are two deterministic projections of the same in-memory dataset. Generated artifacts must not be edited by hand or maintained as separate competing fixture sources.

Any data change must follow this sequence:

1. Change the canonical generator and, if necessary, the versioned subset documentation.
2. Regenerate JSON and SQL from repository root.
3. Run the independent validator.
4. Run Flutter parser/repository/widget tests.
5. Review the diff for non-synthetic identifiers or secrets.

Running the generator twice from the same revision must produce byte-identical outputs. If it does not, the data milestone fails.

## Identity and privacy rules

All person-like records must be unmistakably fictional:

- student codes use `SVTEST...`;
- teacher codes use `GVTEST...`;
- email addresses use the reserved `example.test` domain;
- names, departments, institutions, cities, course titles and descriptions include clear sample/test wording;
- no real DLU student code, staff code, email, phone, address, IP address, avatar, course roster or personal biography may be copied;
- no production submission text/file, feedback or grade may be copied or transformed into the fixture.

Pseudonymizing a real record is not sufficient. The input itself must be generated rather than derived from real DLU data.

## Secret prohibition

The dataset and generator must contain none of the following:

- password or password hash;
- Moodle web-service token;
- Supabase service-role key, private key or JWT secret;
- session ID, cookie, bearer token or refresh token;
- database host credential or connection string;
- signing key or private environment configuration.

The selected fixture projection omits the `user.password` field and the enrolment `password` field. A fake-but-usable credential is still prohibited. Demo authentication state is a development repository behavior, not a credential stored in this dataset.

## Required coverage

The deterministic dataset is designed to exercise the grounded student milestone, not to imitate a complete university installation. Its target coverage is:

- 3 synthetic teachers and 20 synthetic students;
- 4 synthetic course categories and 6 synthetic courses;
- deterministic enrolment/role assignments;
- 3–8 sections per course;
- selected Resource and Assignment activities;
- file **metadata** only, with no Moodle file-pool content;
- assignment scenarios covering future/not-open, due soon, overdue, draft, submitted, not submitted, graded and ungraded states as applicable;
- grade results covering low, medium, high and ungraded cases;
- activity completion rows and a limited upcoming/deadline event projection.

The generator may omit rows to represent a valid absence state. For example, no submission row can mean not submitted and a `NULL` final grade can mean ungraded. Missing state must not be silently converted to success or zero.

## Referential-integrity policy

The validator must fail on:

- duplicate primary keys;
- missing targets for selected declared FKs;
- missing mandatory fields used by the project;
- duplicate `(enrolid, userid)` participation;
- duplicate `(assignment, userid, groupid, attemptnumber)` submission attempts;
- duplicate `(assignment, userid, attemptnumber)` assignment grades;
- duplicate `(userid, itemid)` gradebook results;
- duplicate `(userid, coursemoduleid)` completion rows;
- module instances that do not resolve exactly once according to `modules.name`;
- inconsistent assignment/submission/grade/course identities;
- contextual file/event mappings that do not resolve under the project's explicit discriminator convention;
- any email outside `example.test`, any non-test institutional identifier, or any secret-like field/value.

Some local checks strengthen relationships that the teacher reference marks implied, polymorphic or unresolved. Such checks are `LOCAL_SYNTHETIC_CONVENTION`/`PROJECT_SUBSET_SCHEMA`; they must never be reported as a Moodle or DLU physical FK.

## Environment separation and fail-closed behavior

```text
Development/test entry point
  -> explicitly provided synthetic fixture data source
  -> database/fixtures/dlu_lms_fixture.json

Production entry point
  -> configured HTTPS Moodle/backend data source
  -> fail closed when configuration/credentials/API capability are absent
```

Production repositories must not import, instantiate or silently fall back to the fixture data source. A network error, missing Moodle token or disabled Web Services must remain an explicit production error. The fixture may never make an unverified integration appear live.

Flutter UI also must not read SQL tables or `seed.sql`. The supported layering remains:

```text
Flutter UI -> Provider -> Repository -> Data Source
```

The JSON fixture is loaded only by the development/test data source. Production data must arrive through an approved HTTPS Moodle/backend API projection.

## SQL and file-storage boundary

`database/moodle_subset/schema.sql` and `seed.sql` are local teaching/demo artifacts for the reduced subset. They must not be executed against DLU infrastructure. They must not be described as a full Moodle schema, migration for DLU, or verified production database.

The `files` fixture contains metadata only. It does not contain Moodle SHA-1 file-pool objects, private download URLs or copied course documents. Any production download must be authorized and served by Moodle/backend APIs.

## Source-control rules

Allowed to commit:

- canonical generator and validator source;
- deterministic JSON fixture;
- deterministic SQL seed/schema for the local subset;
- validation report and tests;
- documentation that preserves evidence classifications.

Forbidden to commit:

- `.env` or private configuration;
- real database dumps;
- credentials/tokens/cookies;
- actual student/teacher/course/submission/grade data;
- APK/build/cache/toolchain artifacts;
- manual alternate fixtures that bypass the canonical generator.

Every generated-data milestone must include a secret/PII scan and a clean regeneration/validation result before commit.

## Review checklist

- [ ] Metadata says `SYNTHETIC_DATA`, `MOODLE_SUBSET_V1`, seed `202608`.
- [ ] Output is byte-identical across two clean runs.
- [ ] All emails end in `@example.test`.
- [ ] All institutional IDs use explicit test prefixes such as `SVTEST`, `GVTEST`, `COURSETEST` or `CATTEST`.
- [ ] No password/token/session/cookie/credential field is present.
- [ ] Counts and required state variants pass validation.
- [ ] Every local strengthened relationship is labeled as a project convention.
- [ ] Development uses the canonical JSON through a data-source/repository boundary.
- [ ] Production cannot import or fall back to the fixture.
- [ ] No output is presented as live DLU evidence.

## Defense-ready declaration

> The demo dataset was generated by AI-authored deterministic code using seed `202608`. It contains no real DLU records or credentials and is used only for development, demonstration and testing. Its structure is based on the supervisor-provided Moodle 3.9 reference; production integration remains fail-closed until an approved DLU Moodle API contract and credentials are available.
