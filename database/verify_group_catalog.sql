-- READ-ONLY POST-RESTORE VERIFICATION, not a restore/migration/seed script.
-- Requires psql and an explicitly approved isolated database. See README.md.
-- No application row values, identifiers, credentials, or view bodies are output.
-- Snapshot baseline is the 27 Oct 2026 static review, NOT a live result.
\set ON_ERROR_STOP on
\pset pager off
\if :{?expected_database}
\else
  \echo 'BLOCKED: provide expected_database for the approved isolated target.'
  -- Deliberate read-only error: ON_ERROR_STOP stops a batch with exit code 3.
  SELECT 1 / 0 AS verification_guard_failed;
\endif

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
SET LOCAL statement_timeout = '30s';
SET LOCAL lock_timeout = '5s';
SET LOCAL search_path = pg_catalog;
-- Fail if row policies would hide rows; this does NOT grant bypass privileges.
SET LOCAL row_security = off;

SELECT current_database() = :'expected_database' AS target_matches \gset
\if :target_matches
\else
  \echo 'BLOCKED: connected database does not match expected_database.'
  ROLLBACK;
  SELECT 1 / 0 AS verification_guard_failed;
\endif

SELECT current_setting('server_version') AS server_version,
       current_setting('transaction_read_only') AS transaction_read_only,
       current_setting('transaction_isolation') AS transaction_isolation;

-- Only these application schemas are in scope. Internal tables are excluded.
SELECT count(*) FILTER (WHERE n.nspname = 'lms' AND c.relkind IN ('r', 'p')) AS lms_tables,
       count(*) FILTER (WHERE n.nspname = 'app' AND c.relkind IN ('r', 'p')) AS app_tables,
       count(*) FILTER (WHERE c.relkind IN ('r', 'p')) AS physical_tables,
       count(*) FILTER (WHERE n.nspname = 'derived' AND c.relkind = 'v') AS derived_views
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('lms', 'app', 'derived') \gset actual_

SELECT count(*) AS physical_columns
FROM pg_catalog.pg_attribute AS a
JOIN pg_catalog.pg_class AS c ON c.oid = a.attrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('lms', 'app', 'derived')
  AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped \gset actual_

SELECT count(*) FILTER (WHERE k.contype = 'p') AS primary_keys,
       count(*) FILTER (WHERE k.contype = 'f') AS foreign_keys,
       count(*) FILTER (WHERE k.contype = 'u') AS unique_constraints,
       count(*) FILTER (WHERE k.contype = 'f' AND n.nspname = 'app') AS app_foreign_keys
FROM pg_catalog.pg_constraint AS k
JOIN pg_catalog.pg_class AS c ON c.oid = k.conrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('lms', 'app', 'derived') AND c.relkind IN ('r', 'p') \gset actual_

SELECT x.metric, x.expected, x.actual,
       CASE WHEN x.expected = x.actual THEN 'MATCHES_SNAPSHOT' ELSE 'DRIFT' END AS result
FROM (VALUES
  ('lms_tables', 37, :actual_lms_tables),
  ('app_tables', 7, :actual_app_tables),
  ('physical_tables', 44, :actual_physical_tables),
  ('derived_views', 21, :actual_derived_views),
  ('physical_columns', 583, :actual_physical_columns),
  ('primary_keys', 44, :actual_primary_keys),
  ('foreign_keys', 41, :actual_foreign_keys),
  ('unique_constraints', 15, :actual_unique_constraints),
  ('app_foreign_keys_known_gap', 0, :actual_app_foreign_keys)
) AS x(metric, expected, actual)
ORDER BY x.metric;

-- Names below come from the present group DDL plus the captured dump review.
-- Table presence does not establish complete DDL equivalence.
WITH expected(schema_name, relation_name, relation_kind) AS (VALUES
  ('app', 'flashcards', 'r'), ('app', 'learning_goals', 'r'),
  ('app', 'learning_reflections', 'r'), ('app', 'learning_reminders', 'r'),
  ('app', 'notification_preferences', 'r'), ('app', 'notifications', 'r'),
  ('app', 'teacher_notes', 'r'),
  ('lms', 'assign', 'r'), ('lms', 'assign_grades', 'r'), ('lms', 'assign_submission', 'r'),
  ('lms', 'attendance', 'r'), ('lms', 'attendance_log', 'r'),
  ('lms', 'attendance_sessions', 'r'), ('lms', 'attendance_statuses', 'r'),
  ('lms', 'cohort', 'r'), ('lms', 'cohort_members', 'r'), ('lms', 'context', 'r'),
  ('lms', 'course', 'r'), ('lms', 'course_categories', 'r'),
  ('lms', 'course_completions', 'r'), ('lms', 'course_modules', 'r'),
  ('lms', 'course_modules_completion', 'r'), ('lms', 'course_sections', 'r'),
  ('lms', 'enrol', 'r'), ('lms', 'folder', 'r'), ('lms', 'forum', 'r'),
  ('lms', 'grade_categories', 'r'), ('lms', 'grade_grades', 'r'),
  ('lms', 'grade_items', 'r'), ('lms', 'groupings', 'r'),
  ('lms', 'groupings_groups', 'r'), ('lms', 'groups', 'r'),
  ('lms', 'groups_members', 'r'), ('lms', 'logstore_standard_log', 'r'),
  ('lms', 'modules', 'r'), ('lms', 'quiz', 'r'), ('lms', 'quiz_attempts', 'r'),
  ('lms', 'quiz_grades', 'r'), ('lms', 'resource', 'r'), ('lms', 'role', 'r'),
  ('lms', 'role_assignments', 'r'), ('lms', 'user', 'r'),
  ('lms', 'user_enrolments', 'r'), ('lms', 'user_lastaccess', 'r'),
  ('derived', 'student_academic_profile', 'v'), ('derived', 'student_attendance_summary', 'v'),
  ('derived', 'student_continue_learning', 'v'), ('derived', 'student_course_learning_items', 'v'),
  ('derived', 'student_course_overview', 'v'), ('derived', 'student_course_progress', 'v'),
  ('derived', 'student_dashboard', 'v'), ('derived', 'student_engagement', 'v'),
  ('derived', 'student_grade_category_summary', 'v'), ('derived', 'student_grade_overview', 'v'),
  ('derived', 'student_learning_analytics', 'v'), ('derived', 'student_risk_indicator', 'v'),
  ('derived', 'student_task_summary', 'v'), ('derived', 'teacher_assignment_monitoring', 'v'),
  ('derived', 'teacher_course_analytics', 'v'), ('derived', 'teacher_course_overview', 'v'),
  ('derived', 'teacher_dashboard', 'v'), ('derived', 'teacher_grade_overview', 'v'),
  ('derived', 'teacher_quiz_monitoring', 'v'), ('derived', 'teacher_student_monitoring', 'v'),
  ('derived', 'unified_tasks', 'v')
), mismatches AS (
  SELECT e.schema_name, e.relation_name, e.relation_kind
  FROM expected AS e
  WHERE NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = e.schema_name AND c.relname = e.relation_name
      AND c.relkind::text = e.relation_kind
  )
)
SELECT count(*) AS relation_mismatches FROM mismatches \gset actual_

SELECT :actual_relation_mismatches AS missing_or_wrong_kind_relations,
       pg_catalog.to_regclass('app.auth_account') IS NOT NULL AS auth_account_present,
       'auth_account absent in snapshot; authentication remains a separate gate' AS auth_note;

-- Metadata-only ownership and privilege report. Intended owner mapping is not
-- known yet: this report cannot approve it. Runtime role must not own source data.
SELECT n.nspname AS schema_name,
       count(*) AS relation_count,
       count(DISTINCT c.relowner) AS distinct_owner_count,
       count(*) FILTER (WHERE r.rolsuper) AS superuser_owned_relation_count,
       count(*) FILTER (WHERE r.rolname = current_user) AS current_role_owned_relation_count,
       count(*) FILTER (WHERE c.relrowsecurity) AS row_security_enabled_relation_count
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
JOIN pg_catalog.pg_roles AS r ON r.oid = c.relowner
WHERE n.nspname IN ('app', 'lms', 'derived') AND c.relkind IN ('r', 'p', 'v', 'S')
GROUP BY n.nspname ORDER BY n.nspname;

SELECT n.nspname AS schema_name,
       count(*) FILTER (WHERE pg_catalog.has_table_privilege(c.oid, 'SELECT')) AS readable_tables,
       count(*) FILTER (WHERE pg_catalog.has_table_privilege(c.oid, 'INSERT,UPDATE,DELETE,TRUNCATE')) AS writable_tables
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('app', 'lms') AND c.relkind IN ('r', 'p')
GROUP BY n.nspname ORDER BY n.nspname;

SELECT n.nspname AS schema_name, k.contype AS constraint_type,
       count(*) FILTER (WHERE NOT k.convalidated) AS not_validated_constraints
FROM pg_catalog.pg_constraint AS k
JOIN pg_catalog.pg_class AS c ON c.oid = k.conrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('app', 'lms') AND k.contype IN ('f', 'c')
GROUP BY n.nspname, k.contype ORDER BY n.nspname, k.contype;

-- Do not print default expressions: report only presence/nullable metadata.
SELECT a.attnotnull AS flashcards_userid_not_null,
       a.atthasdef AS flashcards_userid_has_default,
       'nullable/default owner is a known risk; zero orphans does not prove ownership' AS ownership_note
FROM pg_catalog.pg_attribute AS a
WHERE a.attrelid = pg_catalog.to_regclass('app.flashcards')
  AND a.attname = 'userid' AND a.attnum > 0 AND NOT a.attisdropped;

-- All data-query columns are verified against currently available source DDL
-- or startup definitions. No cohort columns or academic-profile aliases guessed.
WITH required(schema_name, relation_name, column_name) AS (VALUES
  ('lms', 'user', 'id'), ('lms', 'course', 'id'),
  ('app', 'learning_goals', 'user_id'), ('app', 'learning_goals', 'course_id'),
  ('app', 'learning_reminders', 'user_id'), ('app', 'learning_reminders', 'course_id'),
  ('app', 'notification_preferences', 'user_id'),
  ('app', 'notifications', 'user_id'), ('app', 'notifications', 'course_id'),
  ('app', 'learning_reflections', 'user_id'), ('app', 'learning_reflections', 'course_id'),
  ('app', 'teacher_notes', 'teacher_id'), ('app', 'teacher_notes', 'student_id'),
  ('app', 'teacher_notes', 'course_id'),
  ('app', 'flashcards', 'userid'), ('app', 'flashcards', 'course_id'),
  ('lms', 'course_modules', 'id'), ('lms', 'course_modules', 'course'),
  ('lms', 'course_modules', 'module'), ('lms', 'course_modules', 'instance'),
  ('lms', 'modules', 'id'), ('lms', 'modules', 'name'),
  ('lms', 'assign', 'id'), ('lms', 'assign', 'course'),
  ('lms', 'quiz', 'id'), ('lms', 'quiz', 'course')
)
SELECT count(*) = 0 AS columns_ready
FROM required AS e
WHERE NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_attribute AS a
  JOIN pg_catalog.pg_class AS c ON c.oid = a.attrelid
  JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
  WHERE n.nspname = e.schema_name AND c.relname = e.relation_name
    AND a.attname = e.column_name AND a.attnum > 0 AND NOT a.attisdropped
) \gset

SELECT :actual_lms_tables = 37 AND :actual_app_tables = 7
   AND :actual_physical_tables = 44 AND :actual_derived_views = 21
   AND :actual_physical_columns = 583 AND :actual_primary_keys = 44
   AND :actual_foreign_keys = 41 AND :actual_unique_constraints = 15
   AND :actual_app_foreign_keys = 0 AND :actual_relation_mismatches = 0
   AND :'columns_ready'::boolean AS snapshot_shape_ready \gset

\if :snapshot_shape_ready
\else
  \echo 'BLOCKED: snapshot/column mismatch; do not seed or mutate to force a match.'
  ROLLBACK;
  SELECT 1 / 0 AS verification_guard_failed;
\endif

-- Count-only integrity diagnostics for app relationships lacking FK coverage.
-- A zero count verifies existence only, not ownership/permission or correct role.
WITH app_links(relation_name, owner_id, related_user_id, course_id) AS (
  SELECT 'learning_goals', user_id, NULL::bigint, course_id FROM app.learning_goals
  UNION ALL SELECT 'learning_reminders', user_id, NULL::bigint, course_id FROM app.learning_reminders
  UNION ALL SELECT 'notification_preferences', user_id, NULL::bigint, NULL::bigint FROM app.notification_preferences
  UNION ALL SELECT 'notifications', user_id, NULL::bigint, course_id FROM app.notifications
  UNION ALL SELECT 'learning_reflections', user_id, NULL::bigint, course_id FROM app.learning_reflections
  UNION ALL SELECT 'teacher_notes', teacher_id, student_id, course_id FROM app.teacher_notes
  UNION ALL SELECT 'flashcards', userid, NULL::bigint, course_id FROM app.flashcards
), app_names(relation_name) AS (VALUES
  ('learning_goals'), ('learning_reminders'), ('notification_preferences'),
  ('notifications'), ('learning_reflections'), ('teacher_notes'), ('flashcards')
), counts AS (
  SELECT x.relation_name, count(*) AS row_count,
    count(*) FILTER (WHERE x.owner_id IS NULL) AS null_owner_count,
    count(*) FILTER (WHERE x.owner_id IS NOT NULL AND NOT EXISTS
      (SELECT 1 FROM lms."user" AS u WHERE u.id = x.owner_id)) AS missing_owner_count,
    count(*) FILTER (WHERE x.related_user_id IS NOT NULL AND NOT EXISTS
      (SELECT 1 FROM lms."user" AS u WHERE u.id = x.related_user_id)) AS missing_related_user_count,
    count(*) FILTER (WHERE x.course_id IS NOT NULL AND NOT EXISTS
      (SELECT 1 FROM lms.course AS c WHERE c.id = x.course_id)) AS missing_course_count
  FROM app_links AS x GROUP BY x.relation_name
)
SELECT n.relation_name, coalesce(c.row_count, 0) AS row_count,
       coalesce(c.null_owner_count, 0) AS null_owner_count,
       coalesce(c.missing_owner_count, 0) AS missing_owner_count,
       coalesce(c.missing_related_user_count, 0) AS missing_related_user_count,
       coalesce(c.missing_course_count, 0) AS missing_course_count
FROM app_names AS n LEFT JOIN counts AS c ON c.relation_name = n.relation_name
ORDER BY n.relation_name;

-- Polymorphic module references are not protected by an ordinary FK to every
-- activity table. Moodle deep links must use course_modules.id, not instance.
SELECT count(*) FILTER (WHERE m.id IS NULL) AS missing_module_type_count,
       count(*) FILTER (WHERE NOT EXISTS
         (SELECT 1 FROM lms.course AS c WHERE c.id = cm.course)) AS missing_module_course_count,
       count(*) FILTER (WHERE m.name = 'assign' AND NOT EXISTS
         (SELECT 1 FROM lms.assign AS a WHERE a.id = cm.instance)) AS missing_assign_instance_count,
       count(*) FILTER (WHERE m.name = 'quiz' AND NOT EXISTS
         (SELECT 1 FROM lms.quiz AS q WHERE q.id = cm.instance)) AS missing_quiz_instance_count,
       count(*) FILTER (WHERE m.name = 'assign' AND EXISTS
         (SELECT 1 FROM lms.assign AS a WHERE a.id = cm.instance AND a.course <> cm.course)) AS assign_course_mismatch_count,
       count(*) FILTER (WHERE m.name = 'quiz' AND EXISTS
         (SELECT 1 FROM lms.quiz AS q WHERE q.id = cm.instance AND q.course <> cm.course)) AS quiz_course_mismatch_count
FROM lms.course_modules AS cm LEFT JOIN lms.modules AS m ON m.id = cm.module;

ROLLBACK;
\echo 'READ-ONLY DIAGNOSTICS COMPLETE; review all counts. This is not an application/auth/API PASS.'
