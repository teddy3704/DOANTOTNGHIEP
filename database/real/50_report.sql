-- REAL-DATA-1 stage 5: aggregate-only report (no usernames, emails or grades of anyone).
\set ON_ERROR_STOP on
\pset footer off
DO $$
BEGIN
    IF current_database() <> 'lms_mobile_group_real' THEN
        RAISE EXCEPTION 'GUARD: report only on lms_mobile_group_real';
    END IF;
END
$$;

\echo '== Row counts (lms). kind: export = from the CSV export, substitute = rebuilt, empty = not supplied'
SELECT t.table_name AS table, (xpath('/row/c/text()', query_to_xml(format('SELECT count(*) AS c FROM lms.%I', t.table_name), false, true, '')))[1]::text::bigint AS rows,
       CASE WHEN t.table_name = 'quiz' AND EXISTS (SELECT 1 FROM realimport.import_notes WHERE note LIKE 'quiz source: export%') THEN 'export'
            WHEN t.table_name IN ('quiz', 'grade_categories', 'course_modules_completion', 'logstore_standard_log') THEN 'substitute'
            WHEN t.table_name IN ('course', 'course_categories', 'course_sections', 'course_modules', 'modules', 'assign',
                                  'assign_submission', 'assign_grades', 'grade_items', 'grade_grades', 'quiz_attempts',
                                  'quiz_grades', 'enrol', 'user_enrolments', 'role', 'role_assignments', 'context', 'user')
                 THEN 'export' ELSE 'empty' END AS kind
FROM information_schema.tables t
WHERE t.table_schema = 'lms' AND t.table_type = 'BASE TABLE'
ORDER BY 3, 1;

\echo '== Load log (rows read from each CSV, seconds)'
SELECT name, rows, seconds FROM realimport.load_log ORDER BY name;

\echo '== Import notes'
SELECT note, value FROM realimport.import_notes ORDER BY note;

\echo '== Courses and users'
SELECT (SELECT count(*) FROM lms.course) AS courses,
       (SELECT count(*) FROM lms.course WHERE startdate >= extract(epoch FROM timestamptz '2026-07-15 00:00+07')) AS courses_from_2026_07_15,
       (SELECT count(*) FROM derived.real_courses_in_progress) AS courses_current_term_in_scope,
       (SELECT count(*) FROM lms."user") AS users,
       (SELECT count(*) FROM lms."user" WHERE idnumber <> '') AS users_with_student_code,
       (SELECT count(DISTINCT userid) FROM derived.real_student_enrolments) AS students_enrolled,
       (SELECT count(*) FROM lms."user" WHERE email <> '') AS users_with_email_loaded;

\echo '== Quizzes (timeclose > 0 = real close time)'
SELECT count(*) AS quizzes, count(*) FILTER (WHERE timeclose > 0) AS with_close_time,
       count(*) FILTER (WHERE sumgrades > 0) AS with_sumgrades,
       (SELECT count(*) FROM lms.quiz_attempts qa WHERE qa.quiz NOT IN (SELECT id FROM lms.quiz)) AS attempts_without_quiz
FROM lms.quiz;

\echo '== Time columns outside 0 .. 2^31 (expect 0)'
SELECT 'course' AS t, count(*) FROM lms.course WHERE startdate NOT BETWEEN 0 AND 2147483647 OR enddate NOT BETWEEN 0 AND 2147483647 OR timecreated NOT BETWEEN 0 AND 2147483647
UNION ALL SELECT 'assign.duedate', count(*) FROM lms.assign WHERE duedate NOT BETWEEN 0 AND 2147483647
UNION ALL SELECT 'assign_submission', count(*) FROM lms.assign_submission WHERE timemodified NOT BETWEEN 0 AND 2147483647
UNION ALL SELECT 'quiz_attempts', count(*) FROM lms.quiz_attempts WHERE timefinish NOT BETWEEN 0 AND 2147483647
UNION ALL SELECT 'grade_grades', count(*) FROM lms.grade_grades WHERE COALESCE(timemodified, 0) NOT BETWEEN 0 AND 2147483647
UNION ALL SELECT 'user_enrolments', count(*) FROM lms.user_enrolments WHERE timecreated NOT BETWEEN 0 AND 2147483647;

\echo '== Reference match (percent of rows whose reference exists; expect >= 99)'
SELECT 'assign_submission.userid -> user (userid 0 = group submission, excluded)' AS ref,
       round(100.0 * count(*) FILTER (WHERE EXISTS (SELECT 1 FROM lms."user" u WHERE u.id = s.userid))
             / NULLIF(count(*) FILTER (WHERE s.userid <> 0), 0), 2) AS pct,
       count(*) FILTER (WHERE s.userid = 0) AS group_rows_userid_0
FROM lms.assign_submission s
UNION ALL
SELECT 'course_modules(assign).instance -> assign',
       round(100.0 * count(*) FILTER (WHERE EXISTS (SELECT 1 FROM lms.assign a WHERE a.id = cm.instance)) / NULLIF(count(*), 0), 2), NULL
FROM lms.course_modules cm JOIN lms.modules m ON m.id = cm.module WHERE m.name = 'assign'
UNION ALL
SELECT 'course_modules(quiz).instance -> quiz',
       round(100.0 * count(*) FILTER (WHERE EXISTS (SELECT 1 FROM lms.quiz q WHERE q.id = cm.instance)) / NULLIF(count(*), 0), 2), NULL
FROM lms.course_modules cm JOIN lms.modules m ON m.id = cm.module WHERE m.name = 'quiz'
UNION ALL
SELECT 'grade_items(mod).categoryid -> grade_categories',
       round(100.0 * count(*) FILTER (WHERE categoryid IS NOT NULL) / NULLIF(count(*), 0), 2), NULL
FROM lms.grade_items WHERE itemtype <> 'course'
UNION ALL
SELECT 'quiz_attempts.quiz -> quiz (all exported attempts)',
       round(100.0 * (SELECT count(*) FROM lms.quiz_attempts) / NULLIF((SELECT rows FROM realimport.load_log WHERE name = 'quiz_attempts'), 0), 2), NULL;

\echo '== Natural weights: aggregationcoef2 (normalised over the items a student has graded) vs grade_grades.aggregationweight (status used)'
WITH items AS (
    SELECT gi.id, gi.courseid, gi.categoryid, gi.aggregationcoef2, gi.grademax,
           sum(gi.aggregationcoef2) OVER (PARTITION BY gi.categoryid) AS sum_coef2,
           sum(gi.grademax) OVER (PARTITION BY gi.categoryid) AS sum_max
    FROM lms.grade_items gi WHERE gi.itemtype IN ('mod', 'manual') AND gi.categoryid IS NOT NULL
), w AS (
    SELECT id, categoryid, CASE WHEN sum_coef2 > 0 THEN aggregationcoef2 ELSE grademax / NULLIF(sum_max, 0) END AS weight,
           (sum_coef2 > 0) AS from_coef2
    FROM items
), used AS (
    SELECT gg.userid, w.categoryid, w.id, w.weight, w.from_coef2, gg.aggregationweight,
           sum(w.weight) OVER (PARTITION BY gg.userid, w.categoryid) AS used_sum
    FROM lms.grade_grades gg JOIN w ON w.id = gg.itemid
    WHERE gg.aggregationstatus = 'used' AND gg.aggregationweight IS NOT NULL
)
SELECT count(*) AS used_rows,
       count(*) FILTER (WHERE abs(weight / NULLIF(used_sum, 0) - aggregationweight) <= 0.001) AS matched,
       round(100.0 * count(*) FILTER (WHERE abs(weight / NULLIF(used_sum, 0) - aggregationweight) <= 0.001) / NULLIF(count(*), 0), 2) AS match_pct,
       count(*) FILTER (WHERE from_coef2) AS rows_weight_from_coef2,
       count(*) FILTER (WHERE NOT from_coef2) AS rows_weight_from_grademax
FROM used;
