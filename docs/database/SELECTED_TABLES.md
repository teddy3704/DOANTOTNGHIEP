# Selected Tables — MOODLE_SUBSET_V1

**Decision:** `LOCKED_FOR_V1`

**Count:** 20 tables

**Schema basis:** `TEACHER_SCHEMA_REFERENCE` only

## Selection rules

A table is included only when it supports the current student demo scope: identity projection, enrolled courses, course structure, resources, assignments, submission status, grades, completion, calendar deadlines or contextual role display. The subset excludes unrelated Moodle subsystems and avoids copying the complete 461-table reference.

The selection does not assert that DLU has the same Moodle version or physical schema. It defines a minimal, deterministic `SYNTHETIC_DATA` model that can later be mapped to verified Moodle API contracts.

## CORE — 13 tables

| Table | Why it is core | V1 use boundary |
|---|---|---|
| `user` | Stable actor key and profile projection for students/teachers | Use only synthetic, non-sensitive display fields. Do not model passwords, auth tokens or private DLU data. |
| `course` | Course identity, display metadata, visibility and date range | Forms the root for enrolled-course and course-detail views. |
| `enrol` | Connects an enrolment method instance to a course | Used with `user_enrolments`; plugin configuration and enrolment secrets are outside scope. |
| `user_enrolments` | Connects a user to an enrolment instance, including status/time window | Drives deterministic "My Courses" membership. |
| `course_sections` | Ordered structural sections inside a course | Section-to-module ordering must respect sequence semantics or an explicit local normalized ordering. |
| `modules` | Registry/discriminator for activity module types | V1 requires only the selected `resource` and `assign` types. |
| `course_modules` | Course-level activity instance and visibility/completion configuration | `instance` is polymorphic; never declare it as a universal FK. |
| `resource` | Metadata for a Moodle resource activity instance | Binary content is not stored here and is not embedded in the mobile fixture. |
| `assign` | Current `mod_assign` activity definition and deadline configuration | Legacy `assignment` is excluded. |
| `assign_submission` | Per-user assignment submission metadata/status/attempt | Actual plugin submission content is outside V1. |
| `assign_grades` | Assignment-specific grader result for a user/attempt | Used for submission-state detail, not as a substitute for the course gradebook. |
| `grade_items` | Gradebook item definition and grade range | Activity linkage through discriminator fields is polymorphic. |
| `grade_grades` | Per-user result for a grade item | Only the authenticated user's permitted projection may reach the production client. |

## SUPPORTING — 7 tables

| Table | Why it is supporting | V1 use boundary |
|---|---|---|
| `course_categories` | Groups courses and supplies category labels | Only the category chain needed by selected courses is generated. |
| `files` | Describes file metadata in a Moodle context/component/file area | No file bytes, storage pool path or direct database/file-store access is exposed to Flutter. |
| `context` | Provides the scope needed for files and role assignments | `instanceid` is polymorphic according to `contextlevel`. |
| `role` | Provides synthetic role labels/archetypes for presentation | Does not authorize client actions. |
| `role_assignments` | Relates user and role within a context | Used to build realistic fixtures and role-aware presentation only. |
| `course_modules_completion` | Stores per-user activity completion state | Enables progress summaries without selecting the broader course-completion subsystem. |
| `event` | Represents user/course/category/activity times | Supports the limited upcoming/deadline surface; not a full calendar subsystem. |

## Relationship ledger

### Declared FKs shown by the teacher reference

The selected source pages show these important physical constraints:

- `course.category -> course_categories.id`
- `enrol.courseid -> course.id`
- `user_enrolments.enrolid -> enrol.id`
- `user_enrolments.userid -> user.id`
- `course_sections.course -> course.id`
- `course_modules.course -> course.id`
- `course_modules.module -> modules.id`
- `assign_submission.assignment -> assign.id`
- `assign_grades.assignment -> assign.id`
- `grade_items.courseid -> course.id`
- `grade_grades.itemid -> grade_items.id`
- `grade_grades.userid -> user.id`
- `files.contextid -> context.id`
- `files.userid -> user.id`
- `role_assignments.roleid -> role.id`
- `role_assignments.contextid -> context.id`
- `role_assignments.userid -> user.id`
- `course_modules_completion.coursemoduleid -> course_modules.id`
- `course_modules_completion.userid -> user.id`
- `event.categoryid -> course_categories.id`

This list is deliberately narrower than every relationship displayed across the 20 pages. It documents the join paths required by V1.

### Weaker, polymorphic or unresolved paths

| Path | Classification | V1 handling |
|---|---|---|
| `assign_submission.userid -> user.id` | SchemaSpy implied constraint | Validate the reference ID in synthetic data as a project rule. |
| `assign_grades.userid -> user.id` | SchemaSpy implied constraint | Validate the reference ID in synthetic data as a project rule. |
| `event.courseid -> course.id` | SchemaSpy implied constraint | Use for synthetic course events; do not claim a physical FK. |
| `event.userid -> user.id` | SchemaSpy implied constraint | Use for synthetic personal events; do not claim a physical FK. |
| `course_modules.section -> course_sections.id` | Unresolved physical constraint | Keep IDs consistent locally and label any local FK as `PROJECT_SUBSET_SCHEMA`. |
| `course_modules.instance -> assign.id` or `resource.id` | Application-polymorphic link | Resolve only after reading `modules.name`. |
| `grade_items.iteminstance -> assign.id` | Application-polymorphic link | Resolve only when grade-item discriminator fields identify `mod_assign`. |
| `files.itemid -> selected domain object` | Application-polymorphic link | Resolve with `contextid`, `component` and `filearea`; never use `itemid` alone. |
| `context.instanceid -> course/course_modules/...` | Application-polymorphic link | Interpret according to `contextlevel`; no universal FK. |
| `event.instance -> assign.id` | Application-polymorphic link | Interpret only with `modulename`/`component` and event type. |
| `assign.course -> course.id` and `resource.course -> course.id` | Reference pages expose course indexes but do not establish a declared FK in the inspected view | Keep synthetic IDs consistent as a project rule; do not upgrade the claim. |

Any constraint added to the reduced local `schema.sql` beyond a declared reference FK must be documented as `PROJECT_SUBSET_SCHEMA`. A useful local validation rule is not evidence of a Moodle or DLU physical constraint.

## Explicitly excluded from V1

| Excluded family | Reason |
|---|---|
| Password, token, session and authentication-secret tables/fields | Not required for fixtures; unsafe and production authentication belongs to the Moodle application layer. |
| `role_capabilities` and the wider capability graph | Client-side role calculation is not authoritative; verified server capability responses are required. |
| `course_completions` and completion criteria families | Activity completion is sufficient for the current UI milestone. |
| `assignsubmission_file`, `assignsubmission_onlinetext`, feedback plugins | V1 shows submission status only; actual submission content/write workflows are deferred. |
| Legacy `assignment` tables | V1 uses current `mod_assign` tables. |
| Quiz, forum, messaging and notification families | No grounded V1 feature requires them. |
| Grade history, scales, outcomes and advanced grading families | Current student grade display needs only grade item/result projections. |
| Event subscription/recurrence expansion tables | V1 needs a deterministic upcoming/deadline projection, not full calendar administration. |

## Change control

Changing this 20-table set requires all of the following:

1. A concrete mobile feature or verified API mapping that cannot be represented by the current subset.
2. A direct teacher-reference page or new approved source recorded in `SCHEMA_SOURCES.md`.
3. Updated join-path, CRUD and feature-traceability documentation.
4. Regenerated deterministic fixtures and passing referential-integrity validation.
5. A clear statement of whether the new evidence is `TEACHER_SCHEMA_REFERENCE`, `DLU_LIVE_EVIDENCE` or `SYNTHETIC_DATA`.
