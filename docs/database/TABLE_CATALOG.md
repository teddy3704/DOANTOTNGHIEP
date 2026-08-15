# Table Catalog — MOODLE_SUBSET_V1

**Status:** `APPROVED_FOR_DEVELOPMENT`
**Schema evidence:** `TEACHER_SCHEMA_REFERENCE`
**Reference:** Moodle LMS 3.9 SchemaSpy snapshot, generated 2020-08-12, MySQL 5.7.31
**Data boundary:** `SYNTHETIC_DATA` only

This catalog documents only the columns used by the project from the 20 selected tables. It is not a copy of the full Moodle schema and is not evidence of the DLU production schema. `Null` and `Default` reproduce the selected table pages; `—` means that the reference displays no explicit default. Parent and child lists are limited to `MOODLE_SUBSET_V1`.

Relationship labels used below:

- `VERIFIED_SCHEMA_FK`: the reference page names a physical constraint.
- `VERIFIED_SCHEMA_IMPLIED`: SchemaSpy explicitly labels the relationship `Implied Constraint`.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected reference pages do not establish a physical FK.
- `LOCAL_SYNTHETIC_CONVENTION`: an integrity rule of the generated project dataset, not a Moodle/DLU constraint.

## Audit field conventions

- Each table's `Purpose` is its project-scoped **Description**; it does not replace the full description on the linked source page.
- In every selected-column table, `Type` is written as `BASE_TYPE(size)` or `BASE_TYPE(precision,scale)`, so that cell records both the required **Type** and **Size**. Types for which the reference page shows no numeric size, such as `LONGTEXT`, are kept without an invented size.
- `Null` is the selected column's **Nullable** value. `Default` preserves what the reference renderer displays; `—` means it displays no explicit default.
- Each table's `Foreign Keys`, `Parent Tables`, `Child Tables`, and `Relationships` sections form the relationship audit. Only evidence labels defined above may upgrade or qualify a link.
- Source column comments used by the project are summarized in `Meaning`; the per-table `Comments` section records important schema caveats and application boundaries.

## CORE tables

## TABLE: user

### Purpose

One row per person. The project uses a minimal, synthetic profile projection for the signed-in actor and enrolled participants. Password/authentication fields are intentionally excluded.

### Source

`TEACHER_SCHEMA_REFERENCE`: [user](https://moodleschema.zoola.io/tables/user.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Person key | Repository joins and fixture identity |
| `auth` | `VARCHAR(20)` | No | `manual` | Authentication plugin name | Synthetic metadata only; not a credential |
| `username` | `VARCHAR(100)` | No | — | Login/display identifier | Synthetic account selector only; never a stored password |
| `idnumber` | `VARCHAR(255)` | No | — | Institution-controlled identifier | Synthetic `SVTEST...`/teacher code |
| `firstname` | `VARCHAR(100)` | No | — | Given name | Profile display |
| `lastname` | `VARCHAR(100)` | No | — | Family name | Profile display |
| `email` | `VARCHAR(100)` | No | — | Email address | Synthetic `example.test` contact |
| `institution` | `VARCHAR(255)` | No | — | Institution label | Explicitly fictional profile metadata |
| `department` | `VARCHAR(255)` | No | — | Department label | Explicitly fictional profile metadata |
| `city` | `VARCHAR(120)` | No | — | City label | Explicitly fictional profile metadata |
| `country` | `VARCHAR(2)` | No | — | Country code | Locale metadata |
| `lang` | `VARCHAR(30)` | No | `en` | Preferred language | Fixture locale |
| `timezone` | `VARCHAR(100)` | No | `99` | Time-zone setting | Fixture date presentation |
| `confirmed` | `BIT(1)` | No | `0` | Account confirmed flag | Fixture account state |
| `deleted` | `BIT(1)` | No | `0` | Soft-deleted flag | Exclude deleted fixture users |
| `suspended` | `BIT(1)` | No | `0` | Login suspension flag | Exclude suspended fixture users |
| `picture` | `BIGINT(19)` | No | `0` | Profile image revision/absence | Avatar fallback decision |
| `timecreated` | `BIGINT(19)` | No | `0` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- No selected `user` column has a parent FK.

### Relevant Indexes

- `user_mneuse_uix` unique on `(mnethostid, username)` in the full reference table.
- Performance indexes `user_ema_ix (email)`, `user_idn_ix (idnumber)`, `user_fir_ix (firstname)`, and `user_las_ix (lastname)`.

### Parent Tables

- None in the selected projection.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `user_enrolments.userid`, `user_enrolments.modifierid`, `grade_grades.userid`, `grade_grades.usermodified`, `files.userid`, `role_assignments.userid`, and `course_modules_completion.userid` reference `user.id`.
- `VERIFIED_SCHEMA_IMPLIED`: `assign_submission.userid`, `assign_grades.userid`, and `event.userid` point to `user.id` as implied constraints.

### Relationships

- `user` has no selected outbound FK. Its selected inbound links are declared for enrolment, gradebook, file, role and completion rows; submission, assignment-grade and event user links remain `VERIFIED_SCHEMA_IMPLIED`.

### Comments

- Credential-bearing fields are intentionally outside the project projection. `auth` and `username` are fixture metadata only and must not be interpreted as authenticated DLU identity evidence.

### Why this table is required

Identity is required to scope courses, submissions, grades, completion, roles and the Profile screen. The fixture never contains real users, password hashes, tokens or DLU personal data.

## TABLE: course

### Purpose

Central course record used by course lists, dashboard summaries and course detail.

### Source

`TEACHER_SCHEMA_REFERENCE`: [course](https://moodleschema.zoola.io/tables/course.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Course key | All course joins |
| `category` | `BIGINT(19)` | No | `0` | Owning category | Category label/filter |
| `sortorder` | `BIGINT(19)` | No | `0` | Course ordering value | Stable fixture ordering |
| `fullname` | `VARCHAR(254)` | No | — | Full course title | Main display title |
| `shortname` | `VARCHAR(255)` | No | — | Short course title/code | Compact cards and navigation |
| `idnumber` | `VARCHAR(100)` | No | — | External course identifier | Synthetic traceability |
| `summary` | `LONGTEXT` | Yes | `NULL` | Course summary | Course detail description |
| `summaryformat` | `TINYINT(3)` | No | `0` | Summary text format | Fixture metadata |
| `format` | `VARCHAR(21)` | No | `topics` | Course layout format | Fixture metadata |
| `startdate` | `BIGINT(19)` | No | `0` | Unix start time | Term/date display |
| `enddate` | `BIGINT(19)` | No | `0` | Unix end time | Term/date display |
| `visible` | `BIT(1)` | No | `1` | Course visibility | Filter hidden courses |
| `timecreated` | `BIGINT(19)` | No | `0` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |
| `enablecompletion` | `BIT(1)` | No | `0` | Enables completion tracking | Progress capability hint |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `course.category -> course_categories.id` (`cour_cat2_fk`).

### Relevant Indexes

- `cour_cat_ix (category)`, `cour_idn_ix (idnumber)`, `cour_sho_ix (shortname)`, and `cour_sor_ix (sortorder)`.

### Parent Tables

- `course_categories` through declared FK `category`.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `enrol.courseid`, `course_sections.course`, `course_modules.course`, and `grade_items.courseid`.
- `VERIFIED_SCHEMA_IMPLIED`: `event.courseid`.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `assign.course` and `resource.course` are indexed on their pages but not shown there as declared FKs.

### Relationships

- The category parent and the enrolment, section, module and grade-item children are declared relations. The event link is implied, while assignment/resource ownership remains unresolved in this reference snapshot.

### Comments

- This table is the project aggregate root, but its reference definition is not evidence that the DLU production table, version or custom fields match it.

### Why this table is required

It is the root aggregate for My Courses, Dashboard, Course Detail, activity, grade and deadline projections.

## TABLE: enrol

### Purpose

Represents an enrolment-plugin instance attached to a course; it is the required bridge between a course and `user_enrolments`.

### Source

`TEACHER_SCHEMA_REFERENCE`: [enrol](https://moodleschema.zoola.io/tables/enrol.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Enrolment-instance key | Membership join |
| `enrol` | `VARCHAR(20)` | No | — | Enrolment plugin name | Synthetic method discriminator |
| `status` | `BIGINT(19)` | No | `0` | Instance status; reference notes `0` is active | Active-membership filtering |
| `courseid` | `BIGINT(19)` | No | `NULL` | Owning course | Course membership join |
| `sortorder` | `BIGINT(19)` | No | `0` | Plugin order in course | Stable fixture ordering |
| `name` | `VARCHAR(255)` | Yes | `NULL` | Optional instance name | Optional diagnostics |
| `timecreated` | `BIGINT(19)` | No | `0` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `enrol.courseid -> course.id` (`enro_cou2_fk`).

### Relevant Indexes

- `enro_cou_ix (courseid)` and `enro_enr_ix (enrol)`.

### Parent Tables

- `course` (declared).

### Child Tables

- `VERIFIED_SCHEMA_FK`: `user_enrolments.enrolid -> enrol.id`.

### Relationships

- The declared membership path is `user_enrolments.enrolid -> enrol.id -> course.id`.

### Comments

- The full source table's enrolment password field is intentionally excluded. The selected `status` meaning follows the reference comment and is not a locally invented production rule. `REFERENCE_ONLY_NOT_SELECTED`: the teacher page also displays `roleid -> role.id` as an implied link; V1 does not seed or consume that column because contextual role presentation uses `role_assignments`.

### Why this table is required

Moodle membership is not a direct `user`–`course` relation; this record supplies the course-scoped enrolment instance. The `password` column in the full source is deliberately not selected or seeded.

## TABLE: user_enrolments

### Purpose

Relates students or teachers to an enrolment instance and records participation status/time window.

### Source

`TEACHER_SCHEMA_REFERENCE`: [user_enrolments](https://moodleschema.zoola.io/tables/user_enrolments.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Participation key | Fixture row identity |
| `status` | `BIGINT(19)` | No | `0` | Participation status; reference notes `0` is active | My Courses filter |
| `enrolid` | `BIGINT(19)` | No | `NULL` | Enrolment instance | Course bridge |
| `userid` | `BIGINT(19)` | No | `NULL` | Participant | User bridge |
| `timestart` | `BIGINT(19)` | No | `0` | Participation start | Active-window check |
| `timeend` | `BIGINT(19)` | No | `2147483647` | Participation end | Active-window check |
| `modifierid` | `BIGINT(19)` | No | `0` | User that modified enrolment | Synthetic audit reference |
| `timecreated` | `BIGINT(19)` | No | `0` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `enrolid -> enrol.id` (`userenro_enr2_fk`).
- `VERIFIED_SCHEMA_FK`: `userid -> user.id` (`userenro_use2_fk`).
- `VERIFIED_SCHEMA_FK`: `modifierid -> user.id` (`userenro_mod2_fk`).

### Relevant Indexes

- Unique `userenro_enruse_uix (enrolid, userid)` prevents duplicate participation in one enrolment instance.
- `userenro_enr_ix (enrolid)`, `userenro_use_ix (userid)`, and `userenro_mod_ix (modifierid)`.

### Parent Tables

- `enrol` and `user` (declared).

### Child Tables

- None in `MOODLE_SUBSET_V1`.

### Relationships

- All three selected joins are declared: `enrolid` reaches the course through `enrol`, while `userid` and `modifierid` reach `user` directly.

### Comments

- The `(enrolid, userid)` unique index is the duplicate-enrolment control for this schema snapshot; time-window logic still requires the selected status/start/end fields.

### Why this table is required

It is the authoritative membership bridge used by the synthetic repository to compute a user's enrolled courses without hard-coded course arrays.

## TABLE: course_sections

### Purpose

Defines numbered/ordered sections inside each course.

### Source

`TEACHER_SCHEMA_REFERENCE`: [course_sections](https://moodleschema.zoola.io/tables/course_sections.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Section key | Course-content grouping |
| `course` | `BIGINT(19)` | No | `0` | Owning course | Section lookup |
| `section` | `BIGINT(19)` | No | `0` | Section number | Stable display ordering |
| `name` | `VARCHAR(255)` | Yes | `NULL` | Optional section name | Section header |
| `summary` | `LONGTEXT` | Yes | `NULL` | Optional section summary | Section description |
| `summaryformat` | `TINYINT(3)` | No | `0` | Summary text format | Fixture metadata |
| `sequence` | `LONGTEXT` | Yes | `NULL` | Module sequence representation | Ordering evidence; not parsed as a universal FK list |
| `visible` | `BIT(1)` | No | `1` | Visibility flag | Hide unavailable sections |
| `availability` | `LONGTEXT` | Yes | `NULL` | JSON availability restrictions | Fixture metadata only |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `course_sections.course -> course.id` (`coursect_cou_fk`).

### Relevant Indexes

- Unique `coursect_cousec_uix (course, section)`.

### Parent Tables

- `course` (declared).

### Child Tables

- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected `course_modules` page does not declare `course_modules.section -> course_sections.id`.

### Relationships

- `course_sections.course -> course.id` is declared. The reverse grouping from `course_modules.section` is retained as unresolved rather than promoted to a physical FK.

### Comments

- `sequence` is ordering evidence only in this project; it is not parsed or documented as a universal foreign-key list.

### Why this table is required

It gives Course Detail a real section hierarchy instead of a flat placeholder list.

## TABLE: modules

### Purpose

Registry of activity module types available in the site.

### Source

`TEACHER_SCHEMA_REFERENCE`: [modules](https://moodleschema.zoola.io/tables/modules.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Module type key | `course_modules.module` target |
| `name` | `VARCHAR(20)` | No | — | Module plugin name | Discriminator (`assign`, `resource`) |
| `cron` | `BIGINT(19)` | No | `0` | Legacy/periodic task setting | Deterministic module metadata |
| `lastcron` | `BIGINT(19)` | No | `0` | Last cron time | Deterministic module metadata |
| `search` | `VARCHAR(255)` | No | — | Search callback metadata | Empty in the fixture |
| `visible` | `BIT(1)` | No | `1` | Module enabled/visible flag | Fixture filtering |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- No parent FK among selected columns.

### Relevant Indexes

- `modu_nam_ix (name)`.

### Parent Tables

- None in `MOODLE_SUBSET_V1`.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `course_modules.module -> modules.id`.

### Relationships

- The declared child link identifies the module type of each `course_modules` row. Resolution from `course_modules.instance` to a module-specific table is separate and polymorphic.

### Comments

- This registry identifies plugin types; it does not itself contain assignment/resource instances or authorize plugin access.

### Why this table is required

The module name is needed to resolve the polymorphic `course_modules.instance` safely; an instance ID alone is ambiguous.

## TABLE: course_modules

### Purpose

Places a module instance in a course and carries visibility and completion configuration.

### Source

`TEACHER_SCHEMA_REFERENCE`: [course_modules](https://moodleschema.zoola.io/tables/course_modules.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Course-module key | Activity navigation/completion |
| `course` | `BIGINT(19)` | No | `0` | Owning course | Activity lookup |
| `module` | `BIGINT(19)` | No | `0` | Module registry key | Activity discriminator join |
| `instance` | `BIGINT(19)` | No | `0` | Module-specific instance ID | Conditional `assign`/`resource` lookup |
| `section` | `BIGINT(19)` | No | `0` | Section identifier | Local section grouping |
| `idnumber` | `VARCHAR(100)` | Yes | `NULL` | Custom activity identifier | Synthetic traceability |
| `added` | `BIGINT(19)` | No | `0` | Unix added time | Fixture metadata |
| `visible` | `BIT(1)` | No | `1` | Activity visibility | Content filtering |
| `visibleoncoursepage` | `BIT(1)` | No | `1` | Course-page visibility | Content filtering |
| `completion` | `BIT(1)` | No | `0` | Completion tracking mode | Progress behavior |
| `completionview` | `BIT(1)` | No | `0` | View required for completion | Progress behavior |
| `completionexpected` | `BIGINT(19)` | No | `0` | Expected completion time | Upcoming/progress hint |
| `availability` | `LONGTEXT` | Yes | `NULL` | JSON availability restrictions | Fixture metadata only |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `course -> course.id` (`courmodu_cou2_fk`).
- `VERIFIED_SCHEMA_FK`: `module -> modules.id` (`courmodu_mod2_fk`).
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `section -> course_sections.id` is not declared on the inspected page.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `instance` is polymorphic; it has no universal FK to `assign` or `resource`.

### Relevant Indexes

- `courmodu_cou_ix (course)`, `courmodu_mod_ix (module)`, `courmodu_ins_ix (instance)`, `courmodu_vis_ix (visible)`, and `courmodu_idncou_ix (idnumber, course)`.

### Parent Tables

- `course` and `modules` (declared); `course_sections` and module-specific instance tables are unresolved/polymorphic.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `course_modules_completion.coursemoduleid -> course_modules.id`.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: module contexts may use `context.instanceid`, but `context.instanceid` is polymorphic and has no declared FK.

### Relationships

- Course and module parents plus the completion child are declared. Section grouping, module-instance lookup and context lookup remain unresolved/polymorphic and require their discriminator fields.

### Comments

- `instance` must be interpreted only after resolving `module -> modules.name`; matching an ID alone is not relationship evidence.

### Why this table is required

It is the common course activity envelope used to render assignments/resources and to attach per-user completion.

## TABLE: resource

### Purpose

Stores the configuration/metadata of a Resource activity instance; it does not store file bytes.

### Source

`TEACHER_SCHEMA_REFERENCE`: [resource](https://moodleschema.zoola.io/tables/resource.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Resource instance key | Polymorphic activity target |
| `course` | `BIGINT(19)` | No | `0` | Owning course ID | Synthetic integrity check |
| `name` | `VARCHAR(255)` | No | — | Resource title | Activity card title |
| `intro` | `LONGTEXT` | Yes | `NULL` | Optional introduction | Resource description |
| `introformat` | `SMALLINT(5)` | No | `0` | Intro format | Fixture metadata |
| `display` | `SMALLINT(5)` | No | `0` | Display mode | UI behavior metadata |
| `displayoptions` | `LONGTEXT` | Yes | `NULL` | Display options | Fixture metadata only |
| `revision` | `BIGINT(19)` | No | `0` | Content revision | Cache/version hint |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected page indexes `course` but does not show `resource.course -> course.id` as a declared FK.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `course_modules.instance -> resource.id` is conditional on `modules.name = 'resource'` and is not a universal physical FK.

### Relevant Indexes

- `reso_cou_ix (course)`.

### Parent Tables

- No declared parent among the selected tables; the course/activity associations are unresolved application links.

### Child Tables

- No selected table declares a FK to `resource.id`. File association is contextual/polymorphic rather than a direct `files.itemid` FK.

### Relationships

- Course ownership, `course_modules.instance`, and file association are application-resolved links in this subset; none is upgraded beyond `SCHEMA_RELATIONSHIP_UNRESOLVED`.

### Comments

- This record describes a Resource activity but stores no file bytes. Production download metadata/content must come through an authorized Moodle/backend API.

### Why this table is required

It supplies resource titles/configuration for Course Detail while keeping binary content and file-store access outside the mobile fixture.

## TABLE: assign

### Purpose

Stores a current `mod_assign` instance, including availability and due dates.

### Source

`TEACHER_SCHEMA_REFERENCE`: [assign](https://moodleschema.zoola.io/tables/assign.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Assignment instance key | Activity, submission and grade joins |
| `course` | `BIGINT(19)` | No | `0` | Owning course ID | Synthetic integrity check |
| `name` | `VARCHAR(255)` | No | — | Assignment title | List/detail title |
| `intro` | `LONGTEXT` | No | `NULL` (as displayed) | Assignment description | Detail content |
| `introformat` | `SMALLINT(5)` | No | `0` | Intro format | Fixture metadata |
| `alwaysshowdescription` | `TINYINT(3)` | No | `0` | Show intro before open date | Detail visibility metadata |
| `submissiondrafts` | `TINYINT(3)` | No | `0` | Draft/submit workflow flag | Status interpretation |
| `allowsubmissionsfromdate` | `BIGINT(19)` | No | `0` | Submission-open time | Availability label |
| `duedate` | `BIGINT(19)` | No | `0` | Student due time | Upcoming/overdue state |
| `cutoffdate` | `BIGINT(19)` | No | `0` | Final acceptance time | Submission-state detail |
| `gradingduedate` | `BIGINT(19)` | No | `0` | Expected grading time | Grading-state metadata |
| `grade` | `BIGINT(19)` | No | `0` | Maximum grade or scale indicator | Assignment grade scale |
| `completionsubmit` | `TINYINT(3)` | No | `0` | Submission can complete activity | Progress semantics |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected page indexes `course` but does not show `assign.course -> course.id` as a declared FK.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `course_modules.instance -> assign.id` is conditional on `modules.name = 'assign'`.

### Relevant Indexes

- `assi_cou_ix (course)` and `assi_tea_ix (teamsubmissiongroupingid)`.

### Parent Tables

- No declared parent among selected columns; the course/module links are unresolved/polymorphic.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `assign_submission.assignment` and `assign_grades.assignment` reference `assign.id`.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `grade_items.iteminstance` can identify an assignment only when its discriminator fields indicate `mod_assign`.

### Relationships

- Submission and assignment-grade children are declared. Course ownership, the course-module instance link and grade-item mapping remain unresolved/polymorphic in the inspected pages.

### Comments

- This is the current `mod_assign` table selected for V1; the legacy `assignment` table is deliberately rejected and must not be silently substituted.

### Why this table is required

It grounds assignment names, dates and limits for assignment list/detail and deadline states. The legacy `assignment` table is not selected.

## TABLE: assign_submission

### Purpose

Stores metadata for a student's interaction/submission attempt; plugin-specific submitted content is outside V1.

### Source

`TEACHER_SCHEMA_REFERENCE`: [assign_submission](https://moodleschema.zoola.io/tables/assign_submission.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Submission key | Fixture row identity |
| `assignment` | `BIGINT(19)` | No | `0` | Assignment key | Submission detail join |
| `userid` | `BIGINT(19)` | No | `0` | Student key | Current-user filtering |
| `timecreated` | `BIGINT(19)` | No | `0` | First interaction time | Status timeline |
| `timemodified` | `BIGINT(19)` | No | `0` | Last student update | Status timeline |
| `status` | `VARCHAR(10)` | Yes | `NULL` | Reference lists `DRAFT`/`SUBMITTED` | Submission-state badge |
| `groupid` | `BIGINT(19)` | No | `0` | Team group key | Unused default for individual fixtures |
| `attemptnumber` | `BIGINT(19)` | No | `0` | Attempt number | Latest-attempt selection |
| `latest` | `TINYINT(3)` | No | `0` | Latest attempt flag | Current status selection |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `assignment -> assign.id` (`assisubm_ass3_fk`).
- `VERIFIED_SCHEMA_IMPLIED`: `userid -> user.id`.

### Relevant Indexes

- Unique `assisubm_assusegroatt_uix (assignment, userid, groupid, attemptnumber)`.
- `assisubm_assusegrolat_ix (assignment, userid, groupid, latest)`, `assisubm_ass_ix (assignment)`, `assisubm_use_ix (userid)`, and `assisubm_att_ix (attemptnumber)`.

### Parent Tables

- `assign` (declared); `user` (implied).

### Child Tables

- None selected. The source declares plugin children such as `assignsubmission_file`, but they are intentionally outside V1.

### Relationships

- `assignment -> assign.id` is declared; `userid -> user.id` is an implied constraint. No plugin-content child is selected for the current project subset.

### Comments

- The row models submission state/attempt metadata only. It neither invents submitted content nor enables a write workflow.

### Why this table is required

It enables submitted/not-submitted/draft/attempt status without inventing submission content or a write workflow.

## TABLE: assign_grades

### Purpose

Stores assignment-specific grading information for one user and attempt.

### Source

`TEACHER_SCHEMA_REFERENCE`: [assign_grades](https://moodleschema.zoola.io/tables/assign_grades.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Assignment-grade key | Fixture row identity |
| `assignment` | `BIGINT(19)` | No | `0` | Assignment key | Submission-detail grade join |
| `userid` | `BIGINT(19)` | No | `0` | Graded user | Current-user filtering |
| `timecreated` | `BIGINT(19)` | No | `0` | First grader update | Grade timeline |
| `timemodified` | `BIGINT(19)` | No | `0` | Latest grader update | Grade timeline |
| `grader` | `BIGINT(19)` | No | `0` | Grader identifier | Synthetic metadata; not authorization |
| `grade` | `DECIMAL(10,5)` | Yes | `0.00000` | Numeric assignment grade | Graded/ungraded state and value |
| `attemptnumber` | `BIGINT(19)` | No | `0` | Related attempt | Align grade with attempt |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `assignment -> assign.id` (`assigrad_ass2_fk`).
- `VERIFIED_SCHEMA_IMPLIED`: `userid -> user.id`.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected page does not declare `grader -> user.id`.

### Relevant Indexes

- Unique `assigrad_assuseatt_uix (assignment, userid, attemptnumber)`.
- `assigrad_ass_ix (assignment)`, `assigrad_use_ix (userid)`, and `assigrad_att_ix (attemptnumber)`.

### Parent Tables

- `assign` (declared); `user` (implied for `userid`).

### Child Tables

- None selected; feedback plugin tables are outside V1.

### Relationships

- `assignment -> assign.id` is declared, `userid -> user.id` is implied, and the grader-to-user link remains unresolved because the inspected page declares no such FK.

### Comments

- Assignment grading is kept distinct from normalized gradebook results; the project does not infer feedback-plugin records from this row.

### Why this table is required

It grounds assignment-detail grading state separately from the normalized course gradebook.

## TABLE: grade_items

### Purpose

Defines gradebook columns/items and their numeric bounds.

### Source

`TEACHER_SCHEMA_REFERENCE`: [grade_items](https://moodleschema.zoola.io/tables/grade_items.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Grade-item key | Grade join |
| `courseid` | `BIGINT(19)` | Yes | `NULL` | Owning course | Course grade filtering |
| `itemname` | `VARCHAR(255)` | Yes | `NULL` | Item display name | Grade row title |
| `itemtype` | `VARCHAR(30)` | No | — | Item source type | Grade-item discriminator |
| `itemmodule` | `VARCHAR(30)` | Yes | `NULL` | Module type | Conditional assignment mapping |
| `iteminstance` | `BIGINT(19)` | Yes | `NULL` | Module-specific instance ID | Conditional assignment mapping |
| `itemnumber` | `BIGINT(19)` | Yes | `NULL` | Distinguishes multiple activity grades | Fixture uniqueness/context |
| `idnumber` | `VARCHAR(255)` | Yes | `NULL` | Module-provided grade item identifier | Synthetic traceability |
| `gradetype` | `SMALLINT(5)` | No | `1` | None/value/scale/text kind | Numeric display eligibility |
| `grademax` | `DECIMAL(10,5)` | No | `100.00000` | Maximum grade | Percentage calculation |
| `grademin` | `DECIMAL(10,5)` | No | `0.00000` | Minimum grade | Percentage calculation |
| `gradepass` | `DECIMAL(10,5)` | No | `0.00000` | Passing threshold | Pass indicator when meaningful |
| `sortorder` | `BIGINT(19)` | No | `0` | Gradebook order | Stable UI ordering |
| `hidden` | `BIGINT(19)` | No | `0` | Hidden flag/date | Do not expose hidden fixture items |
| `locked` | `BIGINT(19)` | No | `0` | Lock flag/date | Read-only grade metadata |
| `timecreated` | `BIGINT(19)` | Yes | `NULL` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | Yes | `NULL` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `courseid -> course.id` (`graditem_cou2_fk`).
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `iteminstance -> assign.id` is conditional on `itemtype`/`itemmodule` and is not a universal FK.

### Relevant Indexes

- `graditem_cou_ix (courseid)`, `graditem_gra_ix (gradetype)`, `graditem_idncou_ix (idnumber, courseid)`, and `graditem_itenee_ix (itemtype, needsupdate)`.

### Parent Tables

- `course` (declared). Module-specific activity table is a polymorphic application link.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `grade_grades.itemid -> grade_items.id`.

### Relationships

- Course ownership and grade-result children are declared. Activity resolution through `iteminstance` is conditional on `itemtype`/`itemmodule` and remains unresolved as a universal FK.

### Comments

- The item discriminator and numeric bounds must accompany a grade value; an `iteminstance` match alone is insufficient to identify an assignment.

### Why this table is required

It provides the metadata needed to interpret an individual numeric result; `grade_grades` alone has no title or grade range.

## TABLE: grade_grades

### Purpose

Stores an individual user's raw/final grade for one grade item.

### Source

`TEACHER_SCHEMA_REFERENCE`: [grade_grades](https://moodleschema.zoola.io/tables/grade_grades.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Grade-result key | Fixture row identity |
| `itemid` | `BIGINT(19)` | No | `NULL` | Grade-item key | Item metadata join |
| `userid` | `BIGINT(19)` | No | `NULL` | Graded user | Current-user filter |
| `rawgrade` | `DECIMAL(10,5)` | Yes | `NULL` | Source numeric grade | Optional diagnostic value |
| `rawgrademax` | `DECIMAL(10,5)` | No | `100.00000` | Maximum at capture time | Result context |
| `rawgrademin` | `DECIMAL(10,5)` | No | `0.00000` | Minimum at capture time | Result context |
| `usermodified` | `BIGINT(19)` | Yes | `NULL` | Last modifying user | Synthetic grader metadata |
| `finalgrade` | `DECIMAL(10,5)` | Yes | `NULL` | Normalized/cached final grade | Student-visible result |
| `hidden` | `BIGINT(19)` | No | `0` | Hidden flag/date | Visibility filtering |
| `locked` | `BIGINT(19)` | No | `0` | Lock flag/date | Read-only metadata |
| `feedback` | `LONGTEXT` | Yes | `NULL` | Grading feedback | Optional grade detail |
| `feedbackformat` | `BIGINT(19)` | No | `0` | Feedback text format | Fixture metadata |
| `timecreated` | `BIGINT(19)` | Yes | `NULL` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | Yes | `NULL` | Unix modification time | Fixture metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `itemid -> grade_items.id` (`gradgrad_ite2_fk`).
- `VERIFIED_SCHEMA_FK`: `userid -> user.id` (`gradgrad_use3_fk`).
- `VERIFIED_SCHEMA_FK`: `usermodified -> user.id` (`gradgrad_use4_fk`).

### Relevant Indexes

- Unique `gradgrad_useite_uix (userid, itemid)`.
- `gradgrad_ite_ix (itemid)`, `gradgrad_use_ix (userid)`, `gradgrad_use2_ix (usermodified)`, and `gradgrad_locloc_ix (locked, locktime)`.

### Parent Tables

- `grade_items` and `user` (declared).

### Child Tables

- None in `MOODLE_SUBSET_V1`.

### Relationships

- Item, graded-user and modifying-user parents are all declared physical FKs in the reference; this table has no selected children.

### Comments

- A nullable `finalgrade` supports an ungraded state. Fixture interpretation does not assert how DLU exposes hidden, locked or unpublished grades through its APIs.

### Why this table is required

It provides the per-student grade record, including a deliberate `NULL` final grade for ungraded scenarios.

## SUPPORTING tables

## TABLE: course_categories

### Purpose

Groups courses into a navigable hierarchy and supplies the category label shown by the app.

### Source

`TEACHER_SCHEMA_REFERENCE`: [course_categories](https://moodleschema.zoola.io/tables/course_categories.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Category key | Course/category join |
| `name` | `VARCHAR(255)` | No | — | Category name | Course label/filter |
| `idnumber` | `VARCHAR(100)` | Yes | `NULL` | Optional external ID | Synthetic traceability |
| `description` | `LONGTEXT` | Yes | `NULL` | Category description | Optional fixture metadata |
| `sortorder` | `BIGINT(19)` | No | `0` | Display order | Stable fixture ordering |
| `coursecount` | `BIGINT(19)` | No | `0` | Cached course count | Validation hint |
| `visible` | `BIT(1)` | No | `1` | Visibility | Category filtering |
| `depth` | `BIGINT(19)` | No | `0` | Hierarchy depth | Validation/display metadata |
| `path` | `VARCHAR(255)` | No | — | Hierarchy path | Validation metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- No parent FK among selected V1 columns.
- `REFERENCE_ONLY_NOT_SELECTED`: the full teacher table declares `parent -> course_categories.id` (`courcate_par2_fk`), but the flat V1 fixture does not seed or consume `parent`.

### Relevant Indexes

- No additional index is required by the selected flat-category projection. The full teacher table has `courcate_par_ix (parent)` outside V1.

### Parent Tables

- None in the selected V1 projection.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `course.category` and `event.categoryid` reference `course_categories.id`.
- `REFERENCE_ONLY_NOT_SELECTED`: the full teacher table also has the self-child `course_categories.parent`.

### Relationships

- The selected course/event children are declared physical relations in the reference snapshot. The self-parent hierarchy is reference evidence outside the flat V1 fixture projection.

### Comments

- The source also uses `parent = 0`, but V1 intentionally models flat categories and does not invent a physical root-category row.

### Why this table is required

It normalizes category names instead of duplicating a hard-coded category string in every course fixture.

## TABLE: files

### Purpose

Describes file metadata; the reference states that content is stored separately in the SHA-1 file pool.

### Source

`TEACHER_SCHEMA_REFERENCE`: [files](https://moodleschema.zoola.io/tables/files.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | File metadata key | Fixture row identity |
| `contenthash` | `VARCHAR(40)` | No | — | SHA-1 content hash | Synthetic metadata only |
| `pathnamehash` | `VARCHAR(40)` | No | — | Unique full-path hash | Fixture uniqueness |
| `contextid` | `BIGINT(19)` | No | `NULL` | Owning context | Context join |
| `component` | `VARCHAR(100)` | No | — | Owning component | File association discriminator |
| `filearea` | `VARCHAR(50)` | No | — | Component file area | File association discriminator |
| `itemid` | `BIGINT(19)` | No | `NULL` | Plugin-specific item ID | Contextual association only |
| `filepath` | `VARCHAR(255)` | No | — | Relative file path | Resource metadata display |
| `filename` | `VARCHAR(255)` | No | — | File name | Resource metadata display |
| `userid` | `BIGINT(19)` | Yes | `NULL` | Optional related user | Synthetic ownership metadata |
| `filesize` | `BIGINT(19)` | No | `NULL` | Size in bytes | File metadata display |
| `mimetype` | `VARCHAR(100)` | Yes | `NULL` | Media type | Icon/type display |
| `status` | `BIGINT(19)` | No | `0` | Nonzero indicates a problem | Exclude invalid fixture files |
| `timecreated` | `BIGINT(19)` | No | `NULL` | Unix creation time | Fixture metadata |
| `timemodified` | `BIGINT(19)` | No | `NULL` | Unix modification time | Fixture metadata |
| `sortorder` | `BIGINT(19)` | No | `0` | File ordering value | Stable resource metadata ordering |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `contextid -> context.id` (`file_con3_fk`).
- `VERIFIED_SCHEMA_FK`: `userid -> user.id` (`file_use2_fk`).
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `itemid` is plugin-specific and is not a universal FK to `resource`, `assign`, or `assign_submission`.

### Relevant Indexes

- Unique `file_pat_uix (pathnamehash)`.
- `file_comfilconite_ix (component, filearea, contextid, itemid)`, `file_con2_ix (contextid)`, `file_con_ix (contenthash)`, and `file_use_ix (userid)`.

### Parent Tables

- `context` and optionally `user` (declared).

### Child Tables

- None in `MOODLE_SUBSET_V1`.

### Relationships

- Context and optional user parents are declared. `itemid` remains plugin-specific, so resource/assignment association is contextual and not a universal physical FK.

### Comments

- Only metadata is modeled. The SHA-1 file pool, actual bytes and authorized production download URLs remain outside the mobile fixture/database subset.

### Why this table is required

It supports safe file metadata rendering. Flutter never reads Moodle SQL or the file pool directly; production file URLs/content must come from an authorized application/API layer.

## TABLE: context

### Purpose

Represents the scope in which files and roles apply. `instanceid` is polymorphic according to `contextlevel`.

### Source

`TEACHER_SCHEMA_REFERENCE`: [context](https://moodleschema.zoola.io/tables/context.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Context key | File/role joins |
| `contextlevel` | `BIGINT(19)` | No | `0` | Scope type discriminator | Resolve synthetic scope kind |
| `instanceid` | `BIGINT(19)` | No | `0` | ID in the table selected by context level | Conditional course/module scope |
| `path` | `VARCHAR(255)` | Yes | `NULL` | Context hierarchy path | Fixture validation metadata |
| `depth` | `TINYINT(3)` | No | `0` | Context hierarchy depth | Fixture validation metadata |
| `locked` | `TINYINT(3)` | No | `0` | Context lock flag | Read-only metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `instanceid` has no universal FK because its target depends on `contextlevel`.

### Relevant Indexes

- Unique `cont_conins_uix (contextlevel, instanceid)`.
- `cont_ins_ix (instanceid)` and `cont_pat_ix (path)`.

### Parent Tables

- No universal parent table.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `files.contextid` and `role_assignments.contextid` reference `context.id`.

### Relationships

- File and role-assignment children are declared. No universal parent is named because `instanceid` changes target with `contextlevel`.

### Comments

- Project fixture mappings for particular context levels are `LOCAL_SYNTHETIC_CONVENTION`; they are not promoted to DLU schema or authorization evidence.

### Why this table is required

It prevents treating `files.itemid` or a role assignment as globally scoped. Synthetic context mappings are explicit project conventions and never production authorization evidence.

## TABLE: role

### Purpose

Defines Moodle role labels/archetypes used for synthetic course-role presentation.

### Source

`TEACHER_SCHEMA_REFERENCE`: [role](https://moodleschema.zoola.io/tables/role.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Role key | Role-assignment join |
| `name` | `VARCHAR(255)` | No | — | Role display name | Synthetic label |
| `shortname` | `VARCHAR(100)` | No | — | Stable role short name | Role presentation discriminator |
| `description` | `LONGTEXT` | No | `NULL` (as displayed) | Role description | Fixture documentation |
| `sortorder` | `BIGINT(19)` | No | `0` | Role order | Stable fixture ordering |
| `archetype` | `VARCHAR(30)` | No | — | Role archetype | Synthetic student/teacher hint |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- No parent FK among selected columns.

### Relevant Indexes

- Unique `role_sho_uix (shortname)` and `role_sor_uix (sortorder)`.

### Parent Tables

- None in `MOODLE_SUBSET_V1`.

### Child Tables

- `VERIFIED_SCHEMA_FK`: `role_assignments.roleid -> role.id`.

### Relationships

- Role assignments are declared children in the V1 projection.

### Comments

- Role/archetype rows support fixture presentation only. Production capability enforcement must remain server-side and cannot be inferred from this table in the client. The teacher page's implied default enrolment-role link is `REFERENCE_ONLY_NOT_SELECTED` in V1.

### Why this table is required

It provides realistic role labels for the fixture. It does not grant authority: production permissions must be returned and enforced by Moodle/backend capabilities.

## TABLE: role_assignments

### Purpose

Assigns a role to a user inside a context.

### Source

`TEACHER_SCHEMA_REFERENCE`: [role_assignments](https://moodleschema.zoola.io/tables/role_assignments.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Assignment key | Fixture row identity |
| `roleid` | `BIGINT(19)` | No | `0` | Assigned role | Role join |
| `contextid` | `BIGINT(19)` | No | `0` | Scope | Context join |
| `userid` | `BIGINT(19)` | No | `0` | Assigned user | User join |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |
| `modifierid` | `BIGINT(19)` | No | `0` | User that modified the assignment | Synthetic audit metadata |
| `component` | `VARCHAR(100)` | No | — | Responsible plugin; blank for manual assignment | Fixture provenance |
| `itemid` | `BIGINT(19)` | No | `0` | Responsible plugin instance | Contextual metadata |
| `sortorder` | `BIGINT(19)` | No | `0` | Assignment order | Stable fixture ordering |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `roleid -> role.id` (`roleassi_rol2_fk`).
- `VERIFIED_SCHEMA_FK`: `contextid -> context.id` (`roleassi_con2_fk`).
- `VERIFIED_SCHEMA_FK`: `userid -> user.id` (`roleassi_use2_fk`).
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected page does not declare `modifierid -> user.id`.

### Relevant Indexes

- `roleassi_useconrol_ix (userid, contextid, roleid)`, `roleassi_rolcon_ix (roleid, contextid)`, `roleassi_comiteuse_ix (component, itemid, userid)`, plus individual `contextid`, `roleid`, and `userid` indexes.

### Parent Tables

- `role`, `context`, and `user` (declared).

### Child Tables

- None in `MOODLE_SUBSET_V1`.

### Relationships

- Role, context and assigned-user parents are declared. `modifierid` and plugin-specific `(component, itemid)` associations remain unresolved in the inspected page.

### Comments

- A role assignment is scope-dependent and is not sufficient client-side proof of a Moodle capability or permission.

### Why this table is required

It enables a realistic user-role-in-context fixture join. Client display of a role is not an authorization decision.

## TABLE: course_modules_completion

### Purpose

Stores a user's completion state for one course activity.

### Source

`TEACHER_SCHEMA_REFERENCE`: [course_modules_completion](https://moodleschema.zoola.io/tables/course_modules_completion.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Completion row key | Fixture row identity |
| `coursemoduleid` | `BIGINT(19)` | No | `NULL` | Activity key | Course-module join |
| `userid` | `BIGINT(19)` | No | `NULL` | User key | Current-user filtering |
| `completionstate` | `BIT(1)` | No | `NULL` | Completion state; source describes 0–3 states | Progress computation |
| `viewed` | `BIT(1)` | Yes | `NULL` | Whether viewed; `NULL` means not tracked | Activity state |
| `overrideby` | `BIGINT(19)` | Yes | `NULL` | Manual override actor | Fixture metadata only |
| `timemodified` | `BIGINT(19)` | No | `NULL` | Last state-change time | Progress metadata |

The reference renderer shows `completionstate` as `BIT(1)`, while its own column comment enumerates values `0`, `1`, `2`, and `3`. The catalog preserves the displayed type. If the reduced local SQL uses a wider integer to represent all four documented states, that is an explicit `PROJECT_SUBSET_SCHEMA` adaptation, not a correction asserted against the teacher reference.

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `coursemoduleid -> course_modules.id` (`courmoducomp_cou2_fk`).
- `VERIFIED_SCHEMA_FK`: `userid -> user.id` (`courmoducomp_use_fk`).
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: the inspected page does not declare `overrideby -> user.id`.

### Relevant Indexes

- Unique `courmoducomp_usecou_uix (userid, coursemoduleid)`.
- `courmoducomp_cou_ix (coursemoduleid)`.

### Parent Tables

- `course_modules` and `user` (declared).

### Child Tables

- None in `MOODLE_SUBSET_V1`.

### Relationships

- Course-module and user parents are declared. The optional manual-override actor remains unresolved because no `overrideby -> user.id` FK is declared on the inspected page.

### Comments

- The reference displays `completionstate` as `BIT(1)` while its comment mentions four states. The canonical V1 fixture therefore uses only `0`/`1` and does not claim a wider production type.

### Why this table is required

It supports deterministic activity progress without selecting the broader course-completion criteria subsystem.

## TABLE: event

### Purpose

Stores records for things with an associated time. V1 uses a limited upcoming/deadline projection, not full calendar administration.

### Source

`TEACHER_SCHEMA_REFERENCE`: [event](https://moodleschema.zoola.io/tables/event.html)

### Columns used by project

| Column | Type | Null | Default | Meaning | App usage |
|---|---|---:|---|---|---|
| `id` | `BIGINT(19)` | No | `NULL` (`AUTO_INCREMENT`) | Event key | Fixture row identity |
| `name` | `LONGTEXT` | No | `NULL` (as displayed) | Event title | Upcoming item title |
| `description` | `LONGTEXT` | No | `NULL` (as displayed) | Event description | Optional detail |
| `format` | `SMALLINT(5)` | No | `0` | Description format | Fixture metadata |
| `categoryid` | `BIGINT(19)` | No | `0` | Category scope | Category event join |
| `courseid` | `BIGINT(19)` | No | `0` | Course scope | Course event filter |
| `groupid` | `BIGINT(19)` | No | `0` | Group scope | Zero for V1 course events |
| `userid` | `BIGINT(19)` | No | `0` | User scope | Personal event filter |
| `component` | `VARCHAR(100)` | Yes | `NULL` | Creating component | Activity discriminator |
| `modulename` | `VARCHAR(20)` | No | — | Module name | Conditional activity mapping |
| `instance` | `BIGINT(19)` | No | `0` | Component/module instance | Conditional assignment mapping |
| `type` | `SMALLINT(5)` | No | `0` | Event type code | Fixture metadata |
| `eventtype` | `VARCHAR(20)` | No | — | Event type | Deadline/event classification |
| `timestart` | `BIGINT(19)` | No | `0` | Unix start time | Upcoming ordering |
| `timeduration` | `BIGINT(19)` | No | `0` | Duration in seconds | Calendar display |
| `timesort` | `BIGINT(19)` | Yes | `NULL` | Sort time | Stable upcoming ordering |
| `visible` | `SMALLINT(5)` | No | `1` | Visibility | Event filtering |
| `uuid` | `VARCHAR(255)` | No | — | External/deduplication identifier | Synthetic traceability |
| `sequence` | `BIGINT(19)` | No | `1` | Event sequence | Fixture metadata |
| `timemodified` | `BIGINT(19)` | No | `0` | Unix modification time | Fixture metadata |
| `priority` | `BIGINT(19)` | Yes | `NULL` | Display priority | Optional event metadata |
| `location` | `LONGTEXT` | Yes | `NULL` | Event location | Optional event metadata |

### Primary Key

- `PRIMARY (id)`.

### Foreign Keys

- `VERIFIED_SCHEMA_FK`: `categoryid -> course_categories.id` (`even_cat2_fk`).
- `VERIFIED_SCHEMA_IMPLIED`: `courseid -> course.id`.
- `VERIFIED_SCHEMA_IMPLIED`: `userid -> user.id`.
- `SCHEMA_RELATIONSHIP_UNRESOLVED`: `instance` is conditional on `component`/`modulename`; it is not a universal FK to `assign`.

### Relevant Indexes

- `even_cou_ix (courseid)`, `even_use_ix (userid)`, `even_cat_ix (categoryid)`, `even_tim_ix (timestart)`, `even_modins_ix (modulename, instance)`, `even_comeveins_ix (component, eventtype, instance)`, and composite `even_grocoucatvisuse_ix`.

### Parent Tables

- `course_categories` (declared); `course` and `user` (implied); module-specific instance target unresolved.

### Child Tables

- None in `MOODLE_SUBSET_V1`.

### Relationships

- Category scope is declared; course and user scopes are implied; module-instance resolution is conditional and unresolved as a universal FK.

### Comments

- V1 selects only a read-only upcoming/deadline projection. Recurrence, subscriptions, groups and calendar administration remain outside scope.

### Why this table is required

It provides a schema-grounded source for a small upcoming/deadline surface while keeping recurrence, subscriptions and calendar administration outside V1.

## Catalog boundary

- Full column lists, constraints and relationships remain at the linked teacher-reference pages.
- The reduced local SQL may add checks or referential rules for deterministic fixtures. Every such addition is `LOCAL_SYNTHETIC_CONVENTION`/`PROJECT_SUBSET_SCHEMA`, not a claim about Moodle 3.9 generally or DLU specifically.
- Flutter production code must consume approved Moodle/backend API projections over HTTPS. It must never query these tables directly.
