# ERD Core — MOODLE_SUBSET_V1

**Status:** `APPROVED_FOR_DEVELOPMENT`
**Tables:** 13 CORE + 7 SUPPORTING
**Evidence:** `TEACHER_SCHEMA_REFERENCE`

The diagram intentionally draws **only relationships displayed as declared foreign keys** by the selected SchemaSpy pages. Every connector below is solid for that reason. Implied, polymorphic, unresolved and local synthetic links are listed after the diagram and are not drawn as physical FKs.

```mermaid
erDiagram
    user {
        BIGINT id PK
        VARCHAR username
        VARCHAR idnumber
        VARCHAR firstname
        VARCHAR lastname
        VARCHAR email
    }

    course_categories {
        BIGINT id PK
        VARCHAR name
        VARCHAR path
    }

    course {
        BIGINT id PK
        BIGINT category FK
        VARCHAR fullname
        VARCHAR shortname
        BIGINT startdate
        BIGINT enddate
    }

    enrol {
        BIGINT id PK
        BIGINT courseid FK
        VARCHAR enrol
        BIGINT status
    }

    user_enrolments {
        BIGINT id PK
        BIGINT enrolid FK
        BIGINT userid FK
        BIGINT status
        BIGINT timestart
        BIGINT timeend
    }

    course_sections {
        BIGINT id PK
        BIGINT course FK
        BIGINT section
        VARCHAR name
        LONGTEXT sequence
    }

    modules {
        BIGINT id PK
        VARCHAR name
        BIT visible
    }

    course_modules {
        BIGINT id PK
        BIGINT course FK
        BIGINT module FK
        BIGINT instance
        BIGINT section
        BIT visible
        BIT completion
    }

    resource {
        BIGINT id PK
        BIGINT course
        VARCHAR name
        BIGINT revision
    }

    assign {
        BIGINT id PK
        BIGINT course
        VARCHAR name
        BIGINT duedate
        BIGINT grade
    }

    assign_submission {
        BIGINT id PK
        BIGINT assignment FK
        BIGINT userid
        VARCHAR status
        BIGINT attemptnumber
        TINYINT latest
    }

    assign_grades {
        BIGINT id PK
        BIGINT assignment FK
        BIGINT userid
        DECIMAL grade
        BIGINT attemptnumber
    }

    grade_items {
        BIGINT id PK
        BIGINT courseid FK
        VARCHAR itemname
        VARCHAR itemtype
        VARCHAR itemmodule
        BIGINT iteminstance
        DECIMAL grademax
    }

    grade_grades {
        BIGINT id PK
        BIGINT itemid FK
        BIGINT userid FK
        DECIMAL finalgrade
        LONGTEXT feedback
    }

    context {
        BIGINT id PK
        BIGINT contextlevel
        BIGINT instanceid
        VARCHAR path
        TINYINT depth
    }

    files {
        BIGINT id PK
        BIGINT contextid FK
        BIGINT userid FK
        VARCHAR component
        VARCHAR filearea
        BIGINT itemid
        VARCHAR filename
    }

    role {
        BIGINT id PK
        VARCHAR name
        VARCHAR shortname
        VARCHAR archetype
    }

    role_assignments {
        BIGINT id PK
        BIGINT roleid FK
        BIGINT contextid FK
        BIGINT userid FK
        VARCHAR component
        BIGINT itemid
    }

    course_modules_completion {
        BIGINT id PK
        BIGINT coursemoduleid FK
        BIGINT userid FK
        BIT completionstate
        BIT viewed
    }

    event {
        BIGINT id PK
        BIGINT categoryid FK
        BIGINT courseid
        BIGINT userid
        VARCHAR modulename
        BIGINT instance
        VARCHAR eventtype
        BIGINT timestart
    }

    course_categories ||--o{ course : "category"
    course_categories ||--o{ event : "categoryid"

    course ||--o{ enrol : "courseid"
    enrol ||--o{ user_enrolments : "enrolid"
    user ||--o{ user_enrolments : "userid"

    course ||--o{ course_sections : "course"
    course ||--o{ course_modules : "course"
    modules ||--o{ course_modules : "module"

    assign ||--o{ assign_submission : "assignment"
    assign ||--o{ assign_grades : "assignment"

    course ||--o{ grade_items : "courseid"
    grade_items ||--o{ grade_grades : "itemid"
    user ||--o{ grade_grades : "userid"

    context ||--o{ files : "contextid"
    user o|--o{ files : "userid"

    role ||--o{ role_assignments : "roleid"
    context ||--o{ role_assignments : "contextid"
    user ||--o{ role_assignments : "userid"

    course_modules ||--o{ course_modules_completion : "coursemoduleid"
    user ||--o{ course_modules_completion : "userid"
```

## Declared-FK interpretation

| Connector group | Constraint evidence |
|---|---|
| Category/course/event | `cour_cat2_fk`, `even_cat2_fk` |
| Enrolment | `enro_cou2_fk`, `userenro_enr2_fk`, `userenro_use2_fk` |
| Course structure | `coursect_cou_fk`, `courmodu_cou2_fk`, `courmodu_mod2_fk` |
| Assignment children | `assisubm_ass3_fk`, `assigrad_ass2_fk` |
| Gradebook | `graditem_cou2_fk`, `gradgrad_ite2_fk`, `gradgrad_use3_fk` |
| Files/context | `file_con3_fk`, `file_use2_fk` |
| Contextual roles | `roleassi_rol2_fk`, `roleassi_con2_fk`, `roleassi_use2_fk` |
| Activity completion | `courmoducomp_cou2_fk`, `courmoducomp_use_fk` |

The reference includes additional audit/user FKs (for example `user_enrolments.modifierid` and `grade_grades.usermodified`) that are not needed to explain the V1 read model and are therefore omitted from the visual. Their source-table specifications remain in the teacher reference.

## Intentionally not drawn as physical FKs

| Relationship | Evidence classification | Reason |
|---|---|---|
| `course_categories.parent -> course_categories.id` | `REFERENCE_ONLY_NOT_SELECTED` | Declared in the full teacher table, but omitted from the flat V1 fixture/project projection. |
| `enrol.roleid -> role.id` | `REFERENCE_ONLY_NOT_SELECTED` | SchemaSpy labels it implied; V1 role presentation uses `role_assignments` instead. |
| `assign_submission.userid -> user.id` | `VERIFIED_SCHEMA_IMPLIED` | SchemaSpy labels it implied. |
| `assign_grades.userid -> user.id` | `VERIFIED_SCHEMA_IMPLIED` | SchemaSpy labels it implied. |
| `event.courseid -> course.id` | `VERIFIED_SCHEMA_IMPLIED` | SchemaSpy labels it implied. |
| `event.userid -> user.id` | `VERIFIED_SCHEMA_IMPLIED` | SchemaSpy labels it implied. |
| `course_modules.section -> course_sections.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | No declared FK appears on the inspected page. |
| `course_modules.instance -> assign.id/resource.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | Target depends on `modules.name`; this is polymorphic. |
| `assign.course -> course.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | The page exposes an index but no declared parent FK. |
| `resource.course -> course.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | The page exposes an index but no declared parent FK. |
| `grade_items.iteminstance -> assign.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | Target depends on item discriminator fields. |
| `context.instanceid -> course.id/course_modules.id/...` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | Target depends on `contextlevel`. |
| `files.itemid -> plugin object` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | Target depends on context, component and file area. |
| `event.instance -> assign.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED` | Target depends on event component/module discriminator. |

The deterministic fixture may enforce these conditional links as `LOCAL_SYNTHETIC_CONVENTION`. That does not convert them into Moodle or DLU physical FKs.

## Reading boundary

The ERD is a thesis/development model for repository and synthetic-data design. Production remains:

```text
Flutter UI -> Provider -> Repository -> approved HTTPS Moodle/backend API
```

It is never `Flutter -> Moodle database`.
