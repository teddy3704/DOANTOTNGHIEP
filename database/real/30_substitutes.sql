-- REAL-DATA-1 stage 3: substitute tables for what the export does not contain.
-- Every row is derived from a real recorded fact; nothing is invented. Rules: docs/REAL_DATA_IMPORT.md.
-- Contains no data. Only touches lms_mobile_group_real.
\set ON_ERROR_STOP on
DO $$
BEGIN
    IF current_database() <> 'lms_mobile_group_real' THEN
        RAISE EXCEPTION 'GUARD: substitutes only run on lms_mobile_group_real, not %', current_database();
    END IF;
END
$$;

BEGIN;

-- Graded activities: a visible course module that has a gradebook item for its module/instance.
-- Ungraded types (resource, url, label, page, folder, videotime, ...) are never counted.
CREATE TABLE stg.graded_cm AS
SELECT DISTINCT ON (cm.id) cm.id AS cmid, cm.course, m.name AS modname, cm.instance, gi.id AS itemid
FROM lms.course_modules cm
JOIN lms.modules m ON m.id = cm.module
JOIN lms.grade_items gi ON gi.itemtype = 'mod' AND gi.itemmodule = m.name AND gi.iteminstance = cm.instance
                       AND gi.courseid = cm.course
WHERE cm.deletioninprogress = 0
ORDER BY cm.id, gi.itemnumber NULLS FIRST, gi.id;
CREATE UNIQUE INDEX ON stg.graded_cm (cmid);

-- course_modules_completion (not exported), derived:
--   assign: a submission with status 'submitted', or a grade
--   quiz: a quiz_grades row or a finished attempt
--   attendance, h5pactivity, lesson and other graded types: a final grade in grade_grades
-- timemodified = earliest such evidence. completionstate 1 = complete.
WITH evidence AS (
    SELECT g.cmid, s.userid, s.timemodified AS t
    FROM stg.graded_cm g JOIN lms.assign_submission s ON g.modname = 'assign' AND s.assignment = g.instance
    WHERE s.status = 'submitted'
    UNION ALL
    SELECT g.cmid, ag.userid, ag.timemodified
    FROM stg.graded_cm g JOIN lms.assign_grades ag ON g.modname = 'assign' AND ag.assignment = g.instance
    WHERE ag.grade IS NOT NULL AND ag.grade >= 0
    UNION ALL
    SELECT g.cmid, qg.userid, qg.timemodified
    FROM stg.graded_cm g JOIN lms.quiz_grades qg ON g.modname = 'quiz' AND qg.quiz = g.instance
    UNION ALL
    SELECT g.cmid, qa.userid, qa.timefinish
    FROM stg.graded_cm g JOIN lms.quiz_attempts qa ON g.modname = 'quiz' AND qa.quiz = g.instance
    WHERE qa.state = 'finished' AND qa.preview = 0
    UNION ALL
    SELECT g.cmid, gg.userid, COALESCE(gg.timemodified, gg.timecreated, 0)
    FROM stg.graded_cm g JOIN lms.grade_grades gg ON gg.itemid = g.itemid
    WHERE gg.finalgrade IS NOT NULL
)
INSERT INTO lms.course_modules_completion (id, coursemoduleid, userid, completionstate, viewed, overrideby, timemodified)
SELECT row_number() OVER (ORDER BY e.cmid, e.userid), e.cmid, e.userid, 1, NULL, NULL, min(e.t)
FROM evidence e
WHERE e.userid IN (SELECT id FROM lms."user")
GROUP BY e.cmid, e.userid;

-- logstore_standard_log (not exported), derived ONLY from hand-in events so that "last activity",
-- the weekly heat map and the inactivity warning all mean "nộp bài hoặc làm bài kiểm tra":
--   assign_submission with status 'submitted' at timemodified
--   finished, non-preview quiz attempt at timefinish
-- Grading time is never used. contextlevel 50 (course): no activity-view events exist, so
-- hasActivityViewLogs() stays false and "not opened" is never claimed. origin = 'derived'.
INSERT INTO lms.logstore_standard_log (id, eventname, component, action, target, objecttable, objectid, crud,
    edulevel, contextid, contextlevel, contextinstanceid, userid, courseid, relateduserid, anonymous, other,
    timecreated, origin, ip, realuserid)
SELECT row_number() OVER (ORDER BY ev.timecreated, ev.objectid), ev.eventname, ev.component, 'submitted', ev.target,
       ev.objecttable, ev.objectid, 'u', 2, ctx.id, 50, ev.courseid, ev.userid, ev.courseid, NULL, 0, NULL,
       ev.timecreated, 'derived', NULL, NULL
FROM (
    SELECT '\mod_assign\event\assessable_submitted' AS eventname, 'mod_assign' AS component, 'assessable' AS target,
           'assign_submission' AS objecttable, s.id AS objectid, a.course AS courseid, s.userid, s.timemodified AS timecreated
    FROM lms.assign_submission s JOIN lms.assign a ON a.id = s.assignment
    WHERE s.status = 'submitted' AND s.userid > 0 AND s.timemodified > 0
    UNION ALL
    SELECT '\mod_quiz\event\attempt_submitted', 'mod_quiz', 'attempt', 'quiz_attempts', qa.id, q.course, qa.userid, qa.timefinish
    FROM lms.quiz_attempts qa JOIN lms.quiz q ON q.id = qa.quiz
    WHERE qa.state = 'finished' AND qa.preview = 0 AND qa.timefinish > 0
) ev
JOIN lms.context ctx ON ctx.contextlevel = 50 AND ctx.instanceid = ev.courseid
WHERE ev.userid IN (SELECT id FROM lms."user");

-- Not derivable, left empty on purpose (the app shows "Không có dữ liệu ..."):
--   attendance, attendance_sessions, attendance_log, attendance_statuses (attendance % comes from
--   the mod/attendance grade item instead, see 40_views.sql), user_lastaccess, course_completions,
--   resource, folder, forum, cohort, groups.

COMMIT;

ANALYZE;
