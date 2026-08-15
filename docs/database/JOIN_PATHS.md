# Join Paths — MOODLE_SUBSET_V1

**Evidence basis:** `TEACHER_SCHEMA_REFERENCE`
**Scope:** the 20-table selected subset only
**Production boundary:** these paths inform repository/API projection design; Flutter must not execute SQL against Moodle.

## Evidence labels

| ID | Meaning | Allowed claim |
|---|---|---|
| `VERIFIED_SCHEMA_FK` | The selected SchemaSpy page names a FK constraint. | A physical relationship exists in the teacher-reference snapshot. |
| `VERIFIED_SCHEMA_IMPLIED` | SchemaSpy explicitly prints `Implied Constraint`. | A likely relationship is reported, but not as a declared FK. |
| `SCHEMA_RELATIONSHIP_UNRESOLVED` | The inspected pages do not establish a physical FK, or the target is discriminator-dependent. | No physical FK claim is allowed. |
| `LOCAL_SYNTHETIC_CONVENTION` | The generator enforces an explicit local rule. | The fixture is internally consistent; this proves nothing about Moodle/DLU production. |

Notation: `child.column -> parent.column` follows the reference FK direction. `<-` is used only to make a read path easier to follow. `~>` denotes a non-physical conditional/unresolved edge.

## User → Courses

```text
user.id
  <- user_enrolments.userid                       [VERIFIED_SCHEMA_FK]
user_enrolments.enrolid
  -> enrol.id                                     [VERIFIED_SCHEMA_FK]
enrol.courseid
  -> course.id                                    [VERIFIED_SCHEMA_FK]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-UC-01` | `user_enrolments.userid = user.id` | `VERIFIED_SCHEMA_FK` (`userenro_use2_fk`) |
| `J-UC-02` | `user_enrolments.enrolid = enrol.id` | `VERIFIED_SCHEMA_FK` (`userenro_enr2_fk`) |
| `J-UC-03` | `enrol.courseid = course.id` | `VERIFIED_SCHEMA_FK` (`enro_cou2_fk`) |

**Path result:** fully supported by declared FKs. The V1 repository additionally filters synthetic active state/time windows. Those filters are business rules, not relationship evidence.

## Course → Sections

```text
course.id
  <- course_sections.course                       [VERIFIED_SCHEMA_FK]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-CS-01` | `course_sections.course = course.id` | `VERIFIED_SCHEMA_FK` (`coursect_cou_fk`) |

**Ordering:** `(course_sections.course, course_sections.section)` is unique in the teacher reference. `section` is used as the stable display order.

## Course → Activities

The common activity envelope is physically grounded:

```text
course.id
  <- course_modules.course                        [VERIFIED_SCHEMA_FK]
course_modules.module
  -> modules.id                                   [VERIFIED_SCHEMA_FK]
```

Resolving its structural section and concrete activity is conditional:

```text
course_modules.section
  ~> course_sections.id                           [SCHEMA_RELATIONSHIP_UNRESOLVED]

course_modules.instance
  ~> assign.id       when modules.name = 'assign' [SCHEMA_RELATIONSHIP_UNRESOLVED]
  ~> resource.id     when modules.name = 'resource'
                                                  [SCHEMA_RELATIONSHIP_UNRESOLVED]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-CA-01` | `course_modules.course = course.id` | `VERIFIED_SCHEMA_FK` (`courmodu_cou2_fk`) |
| `J-CA-02` | `course_modules.module = modules.id` | `VERIFIED_SCHEMA_FK` (`courmodu_mod2_fk`) |
| `J-CA-03` | `course_modules.section = course_sections.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; the inspected page does not declare it |
| `J-CA-04` | `modules.name = 'assign' AND course_modules.instance = assign.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; application-polymorphic link |
| `J-CA-05` | `modules.name = 'resource' AND course_modules.instance = resource.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; application-polymorphic link |
| `J-CA-06` | The generated IDs for `J-CA-03..05` must resolve exactly once | `LOCAL_SYNTHETIC_CONVENTION` |

**Path result:** course-to-envelope and module discriminator are declared; section/concrete-instance resolution is not a physical FK claim. The validator must reject a fixture whose selected discriminator has no matching instance.

## User → Assignment Submission

```text
user.id
  <- assign_submission.userid                     [VERIFIED_SCHEMA_IMPLIED]
assign_submission.assignment
  -> assign.id                                    [VERIFIED_SCHEMA_FK]
assign.course
  ~> course.id                                    [SCHEMA_RELATIONSHIP_UNRESOLVED]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-US-01` | `assign_submission.userid = user.id` | `VERIFIED_SCHEMA_IMPLIED` on the reference page |
| `J-US-02` | `assign_submission.assignment = assign.id` | `VERIFIED_SCHEMA_FK` (`assisubm_ass3_fk`) |
| `J-US-03` | `assign.course = course.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; the page shows an index, not a declared parent FK |
| `J-US-04` | Every synthetic submission user/assignment/course identifier resolves | `LOCAL_SYNTHETIC_CONVENTION` |

**Access path:** membership is checked separately through the fully declared User → Courses path. A submission row never proves authorization on its own.

**Latest attempt:** use the reference uniqueness `(assignment, userid, groupid, attemptnumber)` and filter `latest`; do not treat status alone as an attempt identity.

## User → Grades

### Course gradebook path

```text
user.id
  <- grade_grades.userid                           [VERIFIED_SCHEMA_FK]
grade_grades.itemid
  -> grade_items.id                                [VERIFIED_SCHEMA_FK]
grade_items.courseid
  -> course.id                                     [VERIFIED_SCHEMA_FK]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-UG-01` | `grade_grades.userid = user.id` | `VERIFIED_SCHEMA_FK` (`gradgrad_use3_fk`) |
| `J-UG-02` | `grade_grades.itemid = grade_items.id` | `VERIFIED_SCHEMA_FK` (`gradgrad_ite2_fk`) |
| `J-UG-03` | `grade_items.courseid = course.id` | `VERIFIED_SCHEMA_FK` (`graditem_cou2_fk`) |

**Path result:** the course gradebook path is fully declared. `grade_grades.finalgrade IS NULL` is retained as an ungraded state, not converted to zero.

### Assignment-specific grade path

```text
user.id
  <- assign_grades.userid                          [VERIFIED_SCHEMA_IMPLIED]
assign_grades.assignment
  -> assign.id                                     [VERIFIED_SCHEMA_FK]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-UAG-01` | `assign_grades.userid = user.id` | `VERIFIED_SCHEMA_IMPLIED` |
| `J-UAG-02` | `assign_grades.assignment = assign.id` | `VERIFIED_SCHEMA_FK` (`assigrad_ass2_fk`) |
| `J-UAG-03` | `grade_items.itemmodule = 'assign' AND grade_items.iteminstance = assign.id` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; discriminator-dependent |
| `J-UAG-04` | Synthetic assignment grades and gradebook results use consistent user/activity identities | `LOCAL_SYNTHETIC_CONVENTION` |

The two grade tables serve different views: `assign_grades` describes the assignment attempt result; `grade_items` + `grade_grades` describe the normalized gradebook projection. They must not be joined by numeric IDs without a documented discriminator.

## Course → Files

The only selected physical file ownership edge is:

```text
files.contextid
  -> context.id                                    [VERIFIED_SCHEMA_FK]
```

An end-to-end course-resource-file lookup requires contextual interpretation:

```text
course.id
  <- course_modules.course                         [VERIFIED_SCHEMA_FK]
course_modules.id
  <~ context.instanceid                            [SCHEMA_RELATIONSHIP_UNRESOLVED]
context.id
  <- files.contextid                               [VERIFIED_SCHEMA_FK]

modules.name + course_modules.instance
  ~> resource.id                                   [SCHEMA_RELATIONSHIP_UNRESOLVED]
files.component + files.filearea + files.itemid
  ~> plugin-specific owner                         [SCHEMA_RELATIONSHIP_UNRESOLVED]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-CF-01` | `course_modules.course = course.id` | `VERIFIED_SCHEMA_FK` |
| `J-CF-02` | `files.contextid = context.id` | `VERIFIED_SCHEMA_FK` (`file_con3_fk`) |
| `J-CF-03` | Interpret `context.instanceid` using `context.contextlevel` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; polymorphic target |
| `J-CF-04` | Interpret `files.itemid` together with `contextid`, `component`, and `filearea` | `SCHEMA_RELATIONSHIP_UNRESOLVED`; plugin-specific target |
| `J-CF-05` | Generator emits explicit context/component/file-area records and validator checks the selected mapping | `LOCAL_SYNTHETIC_CONVENTION` |

**Path result:** no fully declared Course → Files FK chain exists in the selected pages. `files.itemid = resource.id` must never be assumed globally. Production repositories receive authorized file metadata/download URLs from Moodle/backend APIs, not from SQL/file-pool paths.

## User → Role in Course

The user/role/context junction is declared:

```text
user.id
  <- role_assignments.userid                       [VERIFIED_SCHEMA_FK]
role_assignments.roleid
  -> role.id                                       [VERIFIED_SCHEMA_FK]
role_assignments.contextid
  -> context.id                                    [VERIFIED_SCHEMA_FK]
```

Course scoping remains polymorphic:

```text
context.instanceid
  ~> course.id when contextlevel denotes course    [SCHEMA_RELATIONSHIP_UNRESOLVED]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-UR-01` | `role_assignments.userid = user.id` | `VERIFIED_SCHEMA_FK` (`roleassi_use2_fk`) |
| `J-UR-02` | `role_assignments.roleid = role.id` | `VERIFIED_SCHEMA_FK` (`roleassi_rol2_fk`) |
| `J-UR-03` | `role_assignments.contextid = context.id` | `VERIFIED_SCHEMA_FK` (`roleassi_con2_fk`) |
| `J-UR-04` | Interpret `context.instanceid` according to `contextlevel` | `SCHEMA_RELATIONSHIP_UNRESOLVED` |
| `J-UR-05` | Synthetic course contexts map one selected context to one selected course | `LOCAL_SYNTHETIC_CONVENTION` |

**Security boundary:** this path may drive a role label in DEV, but it never authorizes an operation. Production authorization remains server/Moodle capability-based.

## User → Activity Completion

```text
user.id
  <- course_modules_completion.userid              [VERIFIED_SCHEMA_FK]
course_modules_completion.coursemoduleid
  -> course_modules.id                             [VERIFIED_SCHEMA_FK]
course_modules.course
  -> course.id                                     [VERIFIED_SCHEMA_FK]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-UCP-01` | `course_modules_completion.userid = user.id` | `VERIFIED_SCHEMA_FK` (`courmoducomp_use_fk`) |
| `J-UCP-02` | `course_modules_completion.coursemoduleid = course_modules.id` | `VERIFIED_SCHEMA_FK` (`courmoducomp_cou2_fk`) |
| `J-UCP-03` | `course_modules.course = course.id` | `VERIFIED_SCHEMA_FK` (`courmodu_cou2_fk`) |

**Path result:** fully declared. Absence of a completion row may represent not completed according to the source comment; fixture/repository behavior must handle both absence and explicit state without inventing completion.

## Course/User → Calendar Event

```text
event.categoryid -> course_categories.id            [VERIFIED_SCHEMA_FK]
event.courseid   -> course.id                       [VERIFIED_SCHEMA_IMPLIED]
event.userid     -> user.id                         [VERIFIED_SCHEMA_IMPLIED]
event.instance   ~> module-specific instance        [SCHEMA_RELATIONSHIP_UNRESOLVED]
```

| Edge | Predicate | Evidence |
|---|---|---|
| `J-EV-01` | `event.categoryid = course_categories.id` | `VERIFIED_SCHEMA_FK` (`even_cat2_fk`) |
| `J-EV-02` | `event.courseid = course.id` | `VERIFIED_SCHEMA_IMPLIED` |
| `J-EV-03` | `event.userid = user.id` | `VERIFIED_SCHEMA_IMPLIED` |
| `J-EV-04` | Use `component`/`modulename` before interpreting `instance` | `SCHEMA_RELATIONSHIP_UNRESOLVED` |
| `J-EV-05` | Generated nonzero course/user/activity event IDs must resolve in the selected fixture; V1 uses `userid = 0` for a non-personal course event | `LOCAL_SYNTHETIC_CONVENTION` |

V1 uses events only for a read-only upcoming projection. It does not claim full recurrence, subscriptions, reminders or notification delivery.

## Validation consequences

The deterministic validator must:

1. Enforce every `VERIFIED_SCHEMA_FK` used by the local subset.
2. Check every selected implied/polymorphic ID used by the fixture, while reporting it as a local validation rule.
3. Reject duplicate user enrolments, duplicate user/item grades, duplicate completion rows and duplicate assignment attempts according to the documented unique indexes.
4. Resolve `course_modules.instance` only through `modules.name`.
5. Resolve context/file/event targets only through their discriminator fields; never by ID coincidence.
6. Keep production repositories fail-closed and independent of these joins/fixtures.
