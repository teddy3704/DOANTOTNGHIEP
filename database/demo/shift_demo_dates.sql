-- DOI_NGAY_DEMO (docs/V2_FEATURES_PROMPT.md §5). Runs ONLY on the separate demo copy
-- lms_mobile_group_demo, never on lms_mobile_group_dev. Shifts every Moodle epoch column of schema
-- lms by one whole-day offset so that the latest assignment/quiz deadline lands at
-- (:'target_date' + 5 days, 23:59 Asia/Ho_Chi_Minh). Deadlines in the last few days before it become
-- "due in 1–7 days" on the target date. Values 0 (Moodle "not set") are left alone.
-- Durations (attendance_sessions.duration, quiz.timelimit, studentsearlyopentime,
-- preventsharediptime) and flags (grade_items.needsupdate) are deliberately NOT in the list.
-- Usage: psql -d lms_mobile_group_demo -v target_date=2026-12-15 --single-transaction -f shift_demo_dates.sql
\set ON_ERROR_STOP on

SELECT current_database() = 'lms_mobile_group_demo' AS is_demo \gset
\if :is_demo
\else
  \echo 'BLOCKED: shift_demo_dates.sql may only run on lms_mobile_group_demo.'
  SELECT 1 / 0 AS demo_guard_failed;
\endif

CREATE TEMP TABLE demo_shift AS
SELECT (round((extract(epoch FROM ((:'target_date')::date + 5 + time '23:59') AT TIME ZONE 'Asia/Ho_Chi_Minh')
              - anchor) / 86400.0) * 86400)::bigint AS seconds,
       anchor
FROM (SELECT greatest((SELECT max(duedate) FROM lms.assign WHERE duedate > 0),
                      (SELECT max(timeclose) FROM lms.quiz WHERE timeclose > 0)) AS anchor) a;

SELECT seconds / 86400 AS shift_days, to_timestamp(anchor) AT TIME ZONE 'Asia/Ho_Chi_Minh' AS old_latest_deadline,
       to_timestamp(anchor + seconds) AT TIME ZONE 'Asia/Ho_Chi_Minh' AS new_latest_deadline
FROM demo_shift;

DO $$
DECLARE
    cols text[] := ARRAY[
        'cohort.timecreated', 'cohort.timemodified', 'cohort_members.timeadded',
        'user.firstaccess', 'user.lastaccess', 'user.lastlogin', 'user.currentlogin',
        'attendance.timemodified', 'attendance_log.timetaken',
        'attendance_sessions.sessdate', 'attendance_sessions.lasttaken', 'attendance_sessions.timemodified',
        'course.startdate', 'course.enddate', 'course.timecreated', 'course.timemodified',
        'course_completions.timeenrolled', 'course_completions.timestarted', 'course_completions.timecompleted',
        'course_modules_completion.timemodified',
        'enrol.enrolstartdate', 'enrol.enrolenddate', 'enrol.timecreated', 'enrol.timemodified',
        'user_enrolments.timestart', 'user_enrolments.timeend', 'user_enrolments.timecreated',
        'user_enrolments.timemodified',
        'assign.allowsubmissionsfromdate', 'assign.duedate', 'assign.timemodified', 'assign.cutoffdate',
        'assign.gradingduedate', 'assign_submission.timecreated', 'assign_submission.timemodified',
        'quiz.timeopen', 'quiz.timeclose', 'quiz.timecreated', 'quiz.timemodified',
        'quiz_attempts.timestart', 'quiz_attempts.timefinish', 'quiz_attempts.timemodified',
        'quiz_attempts.timemodifiedoffline', 'quiz_attempts.timecheckstate',
        'course_sections.timemodified', 'folder.timemodified',
        'forum.duedate', 'forum.cutoffdate', 'forum.timemodified', 'resource.timemodified',
        'logstore_standard_log.timecreated', 'user_lastaccess.timeaccess',
        'grade_categories.timecreated', 'grade_categories.timemodified',
        'grade_grades.locktime', 'grade_grades.timecreated', 'grade_grades.timemodified',
        'grade_items.locktime', 'grade_items.timecreated', 'grade_items.timemodified',
        'assign_grades.timecreated', 'assign_grades.timemodified', 'role_assignments.timemodified',
        'quiz_grades.timemodified', 'course_categories.timemodified',
        'groupings.timecreated', 'groupings.timemodified', 'groupings_groups.timeadded',
        'groups.timecreated', 'groups.timemodified', 'groups_members.timeadded'];
    c text;
    shift bigint;
    n bigint;
    total bigint := 0;
BEGIN
    SELECT seconds INTO shift FROM demo_shift;
    FOREACH c IN ARRAY cols LOOP
        EXECUTE format('UPDATE lms.%I SET %I = %I + $1 WHERE %I > 0',
                       split_part(c, '.', 1), split_part(c, '.', 2), split_part(c, '.', 2), split_part(c, '.', 2))
            USING shift;
        GET DIAGNOSTICS n = ROW_COUNT;
        total := total + n;
    END LOOP;
    RAISE NOTICE 'shifted % columns, % column-rows by % days', array_length(cols, 1), total, shift / 86400;
END
$$;

-- Aggregate check only: deadlines relative to the target date after the shift.
SELECT count(*) FILTER (WHERE d < t) AS deadlines_before_target,
       count(*) FILTER (WHERE d >= t AND d < t + 7 * 86400) AS deadlines_within_7_days,
       count(*) FILTER (WHERE d >= t + 7 * 86400) AS deadlines_later
FROM (SELECT duedate AS d FROM lms.assign WHERE duedate > 0
      UNION ALL SELECT timeclose FROM lms.quiz WHERE timeclose > 0) x,
     (SELECT extract(epoch FROM (:'target_date')::date AT TIME ZONE 'Asia/Ho_Chi_Minh')::bigint AS t) tt;
