-- REAL-DATA-1 stage 4: derived views adjusted for the real export. Same column names/types/order as
-- the snapshot (CREATE OR REPLACE VIEW), so the backend code and grants are unchanged.
-- Only lms_mobile_group_real; dev/demo keep the snapshot definitions. Rules: docs/REAL_DATA_IMPORT.md.
\set ON_ERROR_STOP on
DO $$
BEGIN
    IF current_database() <> 'lms_mobile_group_real' THEN
        RAISE EXCEPTION 'GUARD: real views only on lms_mobile_group_real, not %', current_database();
    END IF;
END
$$;

BEGIN;

-- Helpers (real only). A student of a course = active enrolment AND a student role assignment in the course context.
-- (The snapshot used enrol.roleid, the instance's DEFAULT role, which also counts teachers.)
-- Built once at import as indexed tables (the export is static); the views just read them, which
-- keeps every per-student query from recomputing them at each view level.
CREATE TABLE realimport.student_enrolments AS
SELECT DISTINCT ue.userid, e.courseid
FROM lms.user_enrolments ue
JOIN lms.enrol e ON e.id = ue.enrolid
WHERE ue.status = 0 AND e.status = 0
  AND EXISTS (SELECT 1 FROM lms.role_assignments ra
              JOIN lms.context ctx ON ctx.id = ra.contextid AND ctx.contextlevel = 50 AND ctx.instanceid = e.courseid
              JOIN lms.role r ON r.id = ra.roleid
              WHERE ra.userid = ue.userid AND (r.shortname = 'student' OR r.archetype = 'student'));
CREATE UNIQUE INDEX ON realimport.student_enrolments (userid, courseid);
CREATE INDEX ON realimport.student_enrolments (courseid);
CREATE OR REPLACE VIEW derived.real_student_enrolments AS
SELECT userid, courseid FROM realimport.student_enrolments;

-- Graded activities (the progress basis): visible module with a gradebook item.
CREATE TABLE realimport.graded_modules AS
SELECT DISTINCT ON (cm.id) cm.id AS cmid, cm.course AS courseid, m.name AS modname, cm.instance, gi.id AS itemid,
       gi.itemname, COALESCE(cm.availability, '') ~ '"type":"(group|grouping)"' AS group_only
FROM lms.course_modules cm
JOIN lms.modules m ON m.id = cm.module
JOIN lms.grade_items gi ON gi.itemtype = 'mod' AND gi.itemmodule = m.name AND gi.iteminstance = cm.instance
                       AND gi.courseid = cm.course
WHERE cm.deletioninprogress = 0 AND cm.visible = 1
ORDER BY cm.id, gi.itemnumber NULLS FIRST, gi.id;
CREATE UNIQUE INDEX ON realimport.graded_modules (cmid);
CREATE INDEX ON realimport.graded_modules (courseid);
CREATE OR REPLACE VIEW derived.real_graded_modules AS
SELECT cmid, courseid, modname, instance, itemid, itemname, group_only FROM realimport.graded_modules;
ANALYZE realimport.student_enrolments;
ANALYZE realimport.graded_modules;

-- Scope of tasks and warnings: courses of the current term = start date on/after the term start
-- (HK1 2026-2027: 2026-07-15, the first start date of the term in dlu_course_cntt.csv) and end date
-- not passed. Many 2024-2025 courses have no end date, so Moodle's own "in progress" rule would keep
-- year-old assignments "overdue". Courses and grades screens still show every course.
-- The app labels the to-do list "Học kỳ hiện tại".
CREATE TABLE realimport.settings (key text PRIMARY KEY, value text NOT NULL);
INSERT INTO realimport.settings VALUES ('term_start', '2026-07-15 00:00+07');
CREATE OR REPLACE VIEW derived.real_courses_in_progress AS
SELECT c.id AS courseid FROM lms.course c
WHERE c.startdate >= EXTRACT(epoch FROM (SELECT value FROM realimport.settings WHERE key = 'term_start')::timestamptz)::bigint
  AND (c.enddate = 0 OR c.enddate >= EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint);

-- ------------------------------------------------------------------ progress (graded activities)
-- Group-restricted graded activities (groups not exported) count only for students who completed them.
CREATE OR REPLACE VIEW derived.student_course_progress AS
WITH per_student AS (
    SELECT se.userid, se.courseid,
           count(*) FILTER (WHERE NOT g.group_only OR cmc.id IS NOT NULL) AS total_tracked_activities,
           count(cmc.id) FILTER (WHERE cmc.completionstate = ANY (ARRAY[1, 2, 3])) AS completed_activities
    FROM derived.real_student_enrolments se
    JOIN derived.real_graded_modules g ON g.courseid = se.courseid
    LEFT JOIN lms.course_modules_completion cmc ON cmc.coursemoduleid = g.cmid AND cmc.userid = se.userid
    GROUP BY se.userid, se.courseid
), tracked_modules AS (
    SELECT userid, courseid, total_tracked_activities FROM per_student
), completed_modules AS (
    SELECT userid, courseid, completed_activities FROM per_student
)
SELECT se.userid, se.courseid, c.fullname AS course_name, c.shortname AS course_shortname,
       COALESCE(tm.total_tracked_activities, 0::bigint) AS total_tracked_activities,
       COALESCE(cm.completed_activities, 0::bigint) AS completed_activities,
       -- No graded activity in the course: no progress figure at all (the app shows "Chưa có dữ liệu").
       CASE WHEN COALESCE(tm.total_tracked_activities, 0::bigint) = 0 THEN NULL::numeric
            ELSE round(COALESCE(cm.completed_activities, 0::bigint)::numeric / tm.total_tracked_activities::numeric * 100::numeric, 2)
       END AS progress_percentage,
       cc.timecompleted AS course_timecompleted,
       (cc.timecompleted IS NOT NULL) AS course_completed
FROM derived.real_student_enrolments se
JOIN lms.course c ON c.id = se.courseid
LEFT JOIN tracked_modules tm ON tm.userid = se.userid AND tm.courseid = se.courseid
LEFT JOIN completed_modules cm ON cm.userid = se.userid AND cm.courseid = se.courseid
LEFT JOIN lms.course_completions cc ON cc.userid = se.userid AND cc.course = se.courseid;

-- ------------------------------------------------------------------ tasks
-- Like Moodle's Timeline: only visible activities of courses in the current term; group-restricted
-- activities only with evidence of access (a submission row of any status, an attempt or a grade). "completed" = submitted
-- (quiz: finished attempt) OR already graded. Quizzes have no known close time (timeclose = 0),
-- so they are never overdue and never appear among dated deadlines.
CREATE OR REPLACE VIEW derived.unified_tasks AS
WITH student_enrolments AS (
    SELECT se.userid, se.courseid FROM derived.real_student_enrolments se
    WHERE se.courseid IN (SELECT courseid FROM derived.real_courses_in_progress)
), latest_assignment_submission AS (
    SELECT DISTINCT ON (s.assignment, s.userid) s.id, s.assignment, s.userid, s.status, s.attemptnumber, s.latest,
           s.timecreated, s.timemodified
    FROM lms.assign_submission s
    ORDER BY s.assignment, s.userid, s.latest DESC, s.attemptnumber DESC, s.timemodified DESC
), latest_quiz_attempt AS (
    SELECT DISTINCT ON (qa.quiz, qa.userid) qa.id, qa.quiz, qa.userid, qa.attempt, qa.state, qa.timestart,
           qa.timefinish, qa.timemodified, qa.sumgrades
    FROM lms.quiz_attempts qa
    ORDER BY qa.quiz, qa.userid, qa.attempt DESC, qa.timemodified DESC
), visible_instances AS (
    -- group_only: Moodle access restriction by group/grouping. Groups are not in the export, so such an
    -- activity counts for a student only with evidence that they could reach it (see WHERE below).
    SELECT m.name AS modname, cm.instance,
           bool_and(COALESCE(cm.availability, '') ~ '"type":"(group|grouping)"') AS group_only
    FROM lms.course_modules cm JOIN lms.modules m ON m.id = cm.module
    WHERE cm.visible = 1 AND cm.deletioninprogress = 0 AND m.name IN ('assign', 'quiz')
    GROUP BY m.name, cm.instance
), graded AS (
    SELECT gi.itemmodule, gi.iteminstance, gg.userid FROM lms.grade_grades gg JOIN lms.grade_items gi ON gi.id = gg.itemid
    WHERE gi.itemtype = 'mod' AND gi.itemmodule IN ('assign', 'quiz') AND gg.finalgrade IS NOT NULL
)
SELECT se.userid, a.course AS courseid, c.fullname AS course_name, 'assignment'::character varying AS task_type,
       a.id AS source_id, a.name AS title, a.duedate AS due_time,
       CASE WHEN las.status::text = 'submitted'::text THEN 'completed'::text
            WHEN EXISTS (SELECT 1 FROM graded g WHERE g.itemmodule = 'assign' AND g.iteminstance = a.id AND g.userid = se.userid) THEN 'completed'::text
            WHEN a.duedate > 0 AND a.duedate < EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint THEN 'overdue'::text
            ELSE 'pending'::text END AS task_status,
       las.status AS source_status, las.attemptnumber, NULL::integer AS quiz_attempt, NULL::character varying AS quiz_state
FROM student_enrolments se
JOIN lms.assign a ON a.course = se.courseid
JOIN lms.course c ON c.id = a.course
LEFT JOIN latest_assignment_submission las ON las.assignment = a.id AND las.userid = se.userid
WHERE EXISTS (SELECT 1 FROM visible_instances v WHERE v.modname = 'assign' AND v.instance = a.id
              AND (NOT v.group_only
                   OR las.id IS NOT NULL
                   OR EXISTS (SELECT 1 FROM graded g WHERE g.itemmodule = 'assign' AND g.iteminstance = a.id AND g.userid = se.userid)))
UNION ALL
SELECT se.userid, q.course AS courseid, c.fullname AS course_name, 'quiz'::character varying AS task_type,
       q.id AS source_id, q.name AS title, q.timeclose AS due_time,
       CASE WHEN lqa.state::text = 'finished'::text THEN 'completed'::text
            WHEN EXISTS (SELECT 1 FROM graded g WHERE g.itemmodule = 'quiz' AND g.iteminstance = q.id AND g.userid = se.userid) THEN 'completed'::text
            WHEN q.timeclose > 0 AND q.timeclose < EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint THEN 'overdue'::text
            ELSE 'pending'::text END AS task_status,
       lqa.state AS source_status, NULL::bigint AS attemptnumber, lqa.attempt AS quiz_attempt, lqa.state AS quiz_state
FROM student_enrolments se
JOIN lms.quiz q ON q.course = se.courseid
JOIN lms.course c ON c.id = q.course
LEFT JOIN latest_quiz_attempt lqa ON lqa.quiz = q.id AND lqa.userid = se.userid
WHERE EXISTS (SELECT 1 FROM visible_instances v WHERE v.modname = 'quiz' AND v.instance = q.id
              AND (NOT v.group_only
                   OR lqa.id IS NOT NULL
                   OR EXISTS (SELECT 1 FROM lms.quiz_grades qg WHERE qg.quiz = q.id AND qg.userid = se.userid)));

-- ------------------------------------------------------------------ "activity" = hand-ins
-- logstore_standard_log in real only holds hand-in events (30_substitutes.sql), so every value here
-- means "nộp bài hoặc làm bài kiểm tra". user_lastaccess is empty.
CREATE OR REPLACE VIEW derived.student_engagement AS
SELECT se.userid, se.courseid, ula.timeaccess AS last_course_access, max(l.timecreated) AS last_log_activity,
       count(l.id) FILTER (WHERE l.timecreated >= EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint - 604800) AS events_last_7_days,
       count(DISTINCT date(to_timestamp(l.timecreated::double precision))) FILTER (WHERE l.timecreated >= EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint - 604800) AS active_days_last_7_days,
       CASE WHEN max(l.timecreated) IS NOT NULL THEN floor((EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint - max(l.timecreated))::numeric / 86400.0)::integer
            WHEN ula.timeaccess > 0 THEN floor((EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint - ula.timeaccess)::numeric / 86400.0)::integer
            ELSE NULL::integer END AS days_since_last_activity
FROM derived.real_student_enrolments se
LEFT JOIN lms.user_lastaccess ula ON ula.userid = se.userid AND ula.courseid = se.courseid
LEFT JOIN lms.logstore_standard_log l ON l.userid = se.userid AND l.courseid = se.courseid AND l.anonymous = 0
GROUP BY se.userid, se.courseid, ula.timeaccess;

-- ------------------------------------------------------------------ attendance (grade based)
-- No attendance session tables in the export. Attendance % = finalgrade / grademax of the
-- mod/attendance grade item ("Điểm chuyên cần (theo điểm danh trên LMS)"). Session counts are
-- unknown -> NULL (never 0, which would read as "0 buổi").
-- One row per student and course (a course can have several attendance activities: their grades are
-- summed over their maxima), so joins on (userid, courseid) never duplicate a course.
CREATE OR REPLACE VIEW derived.student_attendance_summary AS
SELECT gi.courseid, gg.userid, min(gi.iteminstance) AS attendance_id,
       (min(gi.itemname) || CASE WHEN count(*) > 1 THEN ' (+' || (count(*) - 1) || ')' ELSE '' END)::character varying(255) AS attendance_name,
       NULL::bigint AS total_sessions, NULL::bigint AS marked_sessions, NULL::bigint AS present_count,
       NULL::bigint AS late_count, NULL::bigint AS excused_count, NULL::bigint AS absent_count,
       round(sum(gg.finalgrade) / NULLIF(sum(gi.grademax), 0) * 100, 2) AS attendance_percentage
FROM lms.grade_items gi
JOIN lms.grade_grades gg ON gg.itemid = gi.id
WHERE gi.itemtype = 'mod' AND gi.itemmodule = 'attendance' AND gg.finalgrade IS NOT NULL
GROUP BY gi.courseid, gg.userid;

-- ------------------------------------------------------------------ learning items
-- resource/url/forum/folder/page/videotime names are not in the export: shown by type plus the
-- section name. Graded types use the real gradebook item name. completion_tracking = 1 marks a
-- graded activity (the progress basis); completionstate comes from the derived completion table.
CREATE OR REPLACE VIEW derived.student_course_learning_items AS
SELECT sc.userid, cm.course AS courseid, c.fullname AS course_name, cs.id AS section_id, cs.section AS section_number,
       cs.name AS section_name, cm.id AS coursemoduleid, m.name AS activity_type, cm.instance AS source_id,
       (CASE m.name
            WHEN 'assign' THEN a.name
            WHEN 'quiz' THEN q.name
            ELSE COALESCE(g.itemname,
                 CASE m.name WHEN 'resource' THEN 'Tài liệu' WHEN 'url' THEN 'Liên kết' WHEN 'forum' THEN 'Diễn đàn'
                             WHEN 'folder' THEN 'Thư mục' WHEN 'page' THEN 'Trang' WHEN 'videotime' THEN 'Video'
                             WHEN 'h5pactivity' THEN 'Hoạt động H5P' WHEN 'lesson' THEN 'Bài học'
                             WHEN 'attendance' THEN 'Điểm danh' ELSE m.name END
                 || ' · ' || COALESCE(NULLIF(cs.name, ''), CASE WHEN cs.section = 0 THEN 'Chung' ELSE 'Chủ đề ' || cs.section END))
        END)::character varying AS activity_name,
       CASE WHEN m.name = 'assign' THEN a.duedate WHEN m.name = 'quiz' THEN q.timeclose ELSE NULL::bigint END AS due_time,
       cm.visible, cm.visibleoncoursepage,
       (CASE WHEN g.cmid IS NOT NULL AND (NOT g.group_only OR cmc.id IS NOT NULL) THEN 1 ELSE 0 END)::smallint AS completion_tracking,
       COALESCE(cmc.completionstate::integer, 0) AS completionstate, cmc.viewed, ut.task_status, ut.source_status,
       '/mod/' || m.name || '/view.php?id=' || cm.id AS moodle_path
FROM derived.student_course_progress sc
JOIN lms.course_modules cm ON cm.course = sc.courseid
JOIN lms.course c ON c.id = cm.course
JOIN lms.modules m ON m.id = cm.module
LEFT JOIN lms.course_sections cs ON cs.id = cm.section
LEFT JOIN lms.assign a ON m.name = 'assign' AND a.id = cm.instance
LEFT JOIN lms.quiz q ON m.name = 'quiz' AND q.id = cm.instance
LEFT JOIN derived.real_graded_modules g ON g.cmid = cm.id
LEFT JOIN lms.course_modules_completion cmc ON cmc.coursemoduleid = cm.id AND cmc.userid = sc.userid
LEFT JOIN derived.unified_tasks ut ON ut.userid = sc.userid AND ut.courseid = sc.courseid
       AND ut.task_type::text = (CASE m.name WHEN 'assign' THEN 'assignment' ELSE m.name END) AND ut.source_id = cm.instance
WHERE cm.deletioninprogress = 0 AND cm.visible = 1
  AND m.name IN ('assign', 'quiz', 'resource', 'folder', 'forum', 'attendance', 'url', 'page', 'videotime', 'h5pactivity', 'lesson');

-- ------------------------------------------------------------------ risk: courses in progress only
-- An ended course has no hand-ins by design; it is not "at risk". Same weights as the snapshot; the
-- inactivity parts only apply with overdue work (see RiskScore.breakdown, handInsOnly).
CREATE OR REPLACE VIEW derived.student_risk_indicator AS
WITH risk_base AS (
    SELECT p.userid, p.courseid, p.course_name, p.progress_percentage,
           COALESCE(t.pending_tasks, 0::bigint) AS pending_tasks, COALESCE(t.overdue_tasks, 0::bigint) AS overdue_tasks,
           COALESCE(e.events_last_7_days, 0::bigint) AS events_last_7_days, e.active_days_last_7_days, e.days_since_last_activity,
           LEAST(100,
               -- REAL-DATA-2: "no hand-in" points only when the student owes work (an overdue task);
               -- all done or only future deadlines is never a reason to watch.
               CASE WHEN COALESCE(t.overdue_tasks, 0::bigint) = 0 THEN 0
                    WHEN COALESCE(e.days_since_last_activity, 999) >= 14 THEN 40 WHEN COALESCE(e.days_since_last_activity, 999) >= 7 THEN 25 ELSE 0 END
             + CASE WHEN COALESCE(t.overdue_tasks, 0::bigint) >= 3 THEN 30 WHEN COALESCE(t.overdue_tasks, 0::bigint) >= 1 THEN 15 ELSE 0 END
             + CASE WHEN p.progress_percentage < 30::numeric THEN 25 WHEN p.progress_percentage < 60::numeric THEN 10 ELSE 0 END
             + CASE WHEN COALESCE(e.events_last_7_days, 0::bigint) = 0 AND COALESCE(t.overdue_tasks, 0::bigint) > 0 THEN 10 ELSE 0 END) AS risk_score
    FROM derived.student_course_progress p
    LEFT JOIN derived.student_task_summary t ON t.userid = p.userid AND t.courseid = p.courseid
    LEFT JOIN derived.student_engagement e ON e.userid = p.userid AND e.courseid = p.courseid
    WHERE p.courseid IN (SELECT courseid FROM derived.real_courses_in_progress)
)
SELECT userid, courseid, course_name, progress_percentage, pending_tasks, overdue_tasks, events_last_7_days,
       active_days_last_7_days, days_since_last_activity, risk_score,
       CASE WHEN risk_score >= 60 THEN 'HIGH'::text WHEN risk_score >= 30 THEN 'MEDIUM'::text ELSE 'LOW'::text END AS risk_level
FROM risk_base;

-- ------------------------------------------------------------------ profile: no names, no cohorts
CREATE OR REPLACE VIEW derived.student_academic_profile AS
SELECT u.id AS userid, NULLIF(u.idnumber, '')::character varying(255) AS student_code,
       TRIM(BOTH FROM concat(COALESCE(u.firstname, ''::character varying), ' ', COALESCE(u.lastname, ''::character varying))) AS fullname,
       u.email, NULL::text AS cohort_code, NULL::text AS class_code, NULL::text AS major_name
FROM lms."user" u
WHERE u.idnumber <> '';

COMMIT;
