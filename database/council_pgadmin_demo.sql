-- DLU LMS Support | Council read-only workspace
-- Dataset: isolated, synthetic GROUP_39_20 + application-owned innovation state.
-- This is NOT a connection to DLU production and SQL is NOT user authorization.
-- SV001=201, SV002=202, GV001=101, GV002=102 are reviewed synthetic aliases.
-- Run all safely, or copy one numbered SELECT into its named Query Tool tab.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '10s';
SET LOCAL TIME ZONE 'Asia/Ho_Chi_Minh';

-- A / 01_database_overview: source, app workflow and derived read models.
SELECT n.nspname AS schema_name,
       count(*) FILTER (WHERE c.relkind = 'r') AS physical_tables,
       count(*) FILTER (WHERE c.relkind = 'v') AS read_model_views
FROM pg_namespace n
LEFT JOIN pg_class c ON c.relnamespace = n.oid AND c.relkind IN ('r', 'v')
WHERE n.nspname IN ('lms', 'app', 'derived')
GROUP BY n.nspname
ORDER BY n.nspname;

SELECT count(*) FILTER (WHERE k.contype = 'p') AS primary_keys,
       count(*) FILTER (WHERE k.contype = 'f') AS foreign_keys,
       count(*) FILTER (WHERE k.contype = 'u') AS unique_constraints,
       count(*) FILTER (WHERE k.contype = 'c') AS check_constraints
FROM pg_constraint k
JOIN pg_class c ON c.oid = k.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('lms', 'app');

-- B / 02_student_tasks: source state, not app plan completion.
SELECT 'SV001' AS student_alias,
       concat(u.firstname, ' ', u.lastname) AS student_name,
       t.course_name,
       t.title AS activity_name,
       t.task_type,
       to_timestamp(nullif(t.due_time, 0)) AS due_at,
       t.source_status AS lms_source_state,
       t.task_status AS derived_task_state
FROM derived.unified_tasks t
JOIN lms."user" u ON u.id = t.userid
WHERE t.userid = 201
ORDER BY t.due_time, t.courseid, t.task_type, t.source_id
LIMIT 30;

-- B / 03_student_recommendation_inputs: signals; ranking is typed API service.
-- pending_tasks and overdue_tasks are separate buckets, not subset counts.
SELECT 'SV001' AS student_alias,
       p.course_name,
       p.completed_activities,
       p.total_tracked_activities,
       CASE WHEN p.total_tracked_activities > 0 THEN p.progress_percentage END AS known_progress_percent,
       t.pending_tasks,
       t.overdue_tasks,
       e.days_since_last_activity AS recorded_inactivity_days,
       e.events_last_7_days AS recorded_events_last_7_days
FROM derived.student_course_progress p
LEFT JOIN derived.student_task_summary t ON t.userid = p.userid AND t.courseid = p.courseid
LEFT JOIN derived.student_engagement e ON e.userid = p.userid AND e.courseid = p.courseid
WHERE p.userid = 201
ORDER BY p.course_name
LIMIT 10;

-- B / 04_student_study_plan: handled means personal work, NOT LMS submission.
-- Empty results are valid; create a plan in the app and rerun this SELECT.
SELECT 'SV001' AS owner_alias,
       course_name,
       title AS personal_study_task,
       scheduled_start_at AS planned_start,
       estimated_minutes,
       priority,
       status AS personal_plan_state,
       notes,
       updated_at
FROM app.study_plan_items
WHERE owner_user_id = 201
ORDER BY scheduled_start_at, id
LIMIT 20;

-- C / 05_teacher_student_monitoring: only GV001's visible course context.
-- API additionally verifies role + active enrolment and rejects wrong identity.
SELECT 'GV001' AS teacher_alias,
       v.student_name,
       v.course_name,
       CASE WHEN v.total_tracked_activities > 0 THEN v.progress_percentage END AS known_progress_percent,
       v.pending_tasks,
       v.overdue_tasks,
       CASE WHEN v.overdue_tasks > 0 THEN 'Có việc quá hạn'
            WHEN v.pending_tasks > 0 THEN 'Có việc đang chờ'
            WHEN v.total_tracked_activities > 0 AND v.progress_percentage < 50 THEN 'Tiến độ hoạt động dưới 50%'
            ELSE 'Chưa có dấu hiệu ưu tiên' END AS support_reason
FROM derived.teacher_student_monitoring v
JOIN lms.course c ON c.id = v.courseid AND c.visible = 1
JOIN lms."user" u ON u.id = v.studentid AND u.deleted = 0 AND u.suspended = 0
WHERE v.teacherid = 101
  AND EXISTS (
    SELECT 1 FROM lms.user_enrolments ue
    JOIN lms.enrol e ON e.id = ue.enrolid AND e.status = 0 AND e.courseid = v.courseid
    JOIN lms.context ctx ON ctx.contextlevel = 50 AND ctx.instanceid = e.courseid
    JOIN lms.role_assignments ra ON ra.userid = ue.userid AND ra.contextid = ctx.id
    JOIN lms.role r ON r.id = ra.roleid AND (r.shortname = 'student' OR r.archetype = 'student')
    WHERE ue.userid = v.studentid AND ue.status = 0
      AND (ue.timestart = 0 OR ue.timestart <= extract(epoch FROM now()))
      AND (ue.timeend = 0 OR ue.timeend > extract(epoch FROM now()))
  )
ORDER BY v.overdue_tasks DESC, v.pending_tasks DESC, v.course_name, v.student_name
LIMIT 20;

-- D / 06_teacher_intervention_history: teacher action + immutable observations.
-- Stored snapshot is descriptive. It does not prove a causal improvement.
SELECT 'GV001' AS teacher_alias,
       i.student_name,
       i.course_name,
       i.title AS support_action,
       i.action_type,
       i.status,
       i.note AS initial_note,
       i.follow_up_at,
       i.created_at,
       f.created_at AS reviewed_at,
       f.note AS review_note,
       f.outcome_status,
       f.progress_percent AS observed_progress_percent,
       f.pending_tasks AS observed_pending_tasks,
       f.overdue_tasks AS observed_overdue_tasks
FROM app.teacher_interventions i
LEFT JOIN app.intervention_followups f ON f.intervention_id = i.id
WHERE i.owner_teacher_id = 101
ORDER BY i.created_at DESC, i.id, f.created_at, f.id
LIMIT 20;

-- E. DATA QUALITY: true zero is not a missing grade; no divide-by-zero.
SELECT count(*) FILTER (WHERE finalgrade IS NULL) AS not_graded,
       count(*) FILTER (WHERE finalgrade = 0) AS recorded_zero_grade,
       count(*) FILTER (WHERE finalgrade IS NULL AND grade_percentage IS NOT NULL) AS invalid_null_conversion
FROM derived.student_grade_overview;

SELECT task_type,
       count(*) FILTER (WHERE source_status IS NULL) AS no_source_submission_or_attempt,
       count(*) FILTER (WHERE task_status = 'completed') AS source_completed,
       count(*) FILTER (WHERE task_status = 'overdue') AS source_overdue,
       count(*) FILTER (WHERE task_status = 'pending') AS source_pending
FROM derived.unified_tasks
WHERE userid = 201
GROUP BY task_type
ORDER BY task_type;

SELECT course_name,
       attendance_sessions,
       attendance_percentage,
       days_since_last_activity
FROM derived.student_course_overview
WHERE userid = 201
ORDER BY course_name;

-- F. SECURITY/SCOPE: separate identities, counts, no private connection details.
SELECT CASE p.userid WHEN 201 THEN 'SV001' WHEN 202 THEN 'SV002' END AS student_alias,
       count(DISTINCT p.courseid) AS course_count,
       (SELECT count(*) FROM app.study_plan_items s WHERE s.owner_user_id = p.userid) AS owned_plan_count
FROM derived.student_course_progress p
WHERE p.userid IN (201, 202)
GROUP BY p.userid
ORDER BY p.userid;

SELECT CASE v.teacherid WHEN 101 THEN 'GV001' WHEN 102 THEN 'GV002' END AS teacher_alias,
       count(DISTINCT v.courseid) AS course_context_count,
       (SELECT count(*) FROM app.teacher_interventions i WHERE i.owner_teacher_id = v.teacherid) AS owned_support_records
FROM derived.teacher_course_overview v
WHERE v.teacherid IN (101, 102)
GROUP BY v.teacherid
ORDER BY v.teacherid;
ROLLBACK;
