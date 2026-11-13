-- REAL-DATA-1 stage 2: typed INSERT ... SELECT from stg into lms, keeping only the 173 CNTT
-- courses (dlu_course_cntt.csv) and the users, enrolments and roles related to them.
-- Column positions: MOODLE_401_STABLE install.xml order, checked against the export.
-- The email column is NEVER loaded (lms."user".email is NOT NULL, so it gets '').
-- Contains no data. Only touches lms_mobile_group_real.
\set ON_ERROR_STOP on
DO $$
BEGIN
    IF current_database() <> 'lms_mobile_group_real' THEN
        RAISE EXCEPTION 'GUARD: load only runs on lms_mobile_group_real, not %', current_database();
    END IF;
    IF EXISTS (SELECT 1 FROM lms.course) OR EXISTS (SELECT 1 FROM lms."user") THEN
        RAISE EXCEPTION 'lms already has rows; use Import-RealData.ps1 -Recreate for a clean database';
    END IF;
END
$$;

BEGIN;

-- ------------------------------------------------------------------ id sets
CREATE TEMP TABLE k_course ON COMMIT DROP AS SELECT DISTINCT stg.b(c0) AS id FROM stg.course;
CREATE TEMP TABLE k_enrol ON COMMIT DROP AS
    SELECT DISTINCT stg.b(c0) AS id FROM stg.enrol WHERE stg.b(c3) IN (SELECT id FROM k_course);
CREATE TEMP TABLE k_assign ON COMMIT DROP AS
    SELECT DISTINCT stg.b(c0) AS id FROM stg.assign WHERE stg.b(c1) IN (SELECT id FROM k_course);
CREATE TEMP TABLE k_item ON COMMIT DROP AS
    SELECT DISTINCT stg.b(c0) AS id FROM stg.grade_items WHERE stg.b(c1) IN (SELECT id FROM k_course);
CREATE TEMP TABLE k_cm ON COMMIT DROP AS
    SELECT DISTINCT stg.b(c0) AS id FROM stg.course_modules WHERE stg.b(c1) IN (SELECT id FROM k_course);
CREATE TEMP TABLE k_context ON COMMIT DROP AS
    SELECT stg.b(c0) AS id FROM stg.context
    WHERE c1 = '10'
       OR (c1 = '40' AND stg.b(c2) IN (SELECT stg.b(c0) FROM stg.course_categories))
       OR (c1 = '50' AND stg.b(c2) IN (SELECT id FROM k_course))
       OR (c1 = '70' AND stg.b(c2) IN (SELECT id FROM k_cm));
CREATE TEMP TABLE all_users ON COMMIT DROP AS SELECT DISTINCT stg.b(c0) AS id FROM stg."user";
CREATE TEMP TABLE k_user ON COMMIT DROP AS
SELECT id FROM all_users WHERE id IN (
    SELECT stg.b(c3) FROM stg.user_enrolments WHERE stg.b(c2) IN (SELECT id FROM k_enrol)
    UNION SELECT stg.b(c3) FROM stg.role_assignments WHERE stg.b(c2) IN (SELECT id FROM k_context)
    UNION SELECT stg.b(c2) FROM stg.assign_submission WHERE stg.b(c1) IN (SELECT id FROM k_assign)
    UNION SELECT stg.b(c2) FROM stg.assign_grades WHERE stg.b(c1) IN (SELECT id FROM k_assign)
    UNION SELECT stg.b(c2) FROM stg.grade_grades WHERE stg.b(c1) IN (SELECT id FROM k_item)
    UNION SELECT stg.b(c2) FROM stg.quiz_attempts
    UNION SELECT stg.b(c2) FROM stg.quiz_grades);
CREATE UNIQUE INDEX ON k_user (id);

-- ------------------------------------------------------------------ reference tables
INSERT INTO lms.role (id, name, shortname, description, sortorder, archetype)
SELECT stg.b(c0), COALESCE(c1, ''), c2, c3, COALESCE(stg.b(c4), 0), COALESCE(c5, '') FROM stg.role;

INSERT INTO lms.modules (id, name, cron, lastcron, search, visible)
SELECT stg.b(c0), c1, COALESCE(stg.b(c2), 0), COALESCE(stg.b(c3), 0), c4, COALESCE(stg.b(c5), 1) FROM stg.modules;

-- Parents outside the CNTT export (top-level faculty/year nodes) become NULL; Moodle's 0 = top level.
INSERT INTO lms.course_categories (id, name, idnumber, description, descriptionformat, parent, sortorder,
    coursecount, visible, visibleold, timemodified, depth, path, theme)
SELECT stg.b(c0), c1, NULLIF(c2, ''), NULLIF(c3, ''), COALESCE(stg.b(c4), 0), NULL, COALESCE(stg.b(c6), 0),
       COALESCE(stg.b(c7), 0), COALESCE(stg.b(c8), 1), COALESCE(stg.b(c9), 1), COALESCE(stg.b(c10), 0),
       COALESCE(stg.b(c11), 0), COALESCE(c12, ''), c13
FROM stg.course_categories;
UPDATE lms.course_categories cc SET parent = stg.b(s.c5)
FROM stg.course_categories s
WHERE stg.b(s.c0) = cc.id AND stg.b(s.c5) IN (SELECT id FROM lms.course_categories);

-- course: 0 id,1 category,2 sortorder,3 fullname,4 shortname,5 idnumber,6 summary,7 summaryformat,
-- 8 format,9 showgrades,10 newsitems,11 startdate,12 enddate,13 relativedatesmode,14 marker,
-- 15 maxbytes,16 legacyfiles,17 showreports,18 visible,19 visibleold,20 downloadcontent,21 groupmode,
-- 22 groupmodeforce,23 defaultgroupingid,24 lang,25 calendartype,26 theme,27 timecreated,
-- 28 timemodified,29 requested,30 enablecompletion,31 completionnotify,32 cacherev,...
INSERT INTO lms.course (id, category, sortorder, fullname, shortname, idnumber, summary, summaryformat, format,
    showgrades, newsitems, startdate, enddate, relativedatesmode, marker, maxbytes, legacyfiles, showreports,
    visible, visibleold, groupmode, groupmodeforce, defaultgroupingid, lang, calendartype, theme,
    timecreated, timemodified, requested, enablecompletion, completionnotify, cacherev)
SELECT stg.b(c0), stg.b(c1), COALESCE(stg.b(c2), 0), c3, c4, COALESCE(c5, ''), c6, COALESCE(stg.b(c7), 0),
       COALESCE(c8, 'topics'), COALESCE(stg.b(c9), 1), COALESCE(stg.b(c10), 1), COALESCE(stg.b(c11), 0),
       COALESCE(stg.b(c12), 0), COALESCE(stg.b(c13), 0), COALESCE(stg.b(c14), 0), COALESCE(stg.b(c15), 0),
       COALESCE(stg.b(c16), 0), COALESCE(stg.b(c17), 0), COALESCE(stg.b(c18), 1), COALESCE(stg.b(c19), 1),
       COALESCE(stg.b(c21), 0), COALESCE(stg.b(c22), 0), COALESCE(stg.b(c23), 0), COALESCE(c24, ''),
       COALESCE(c25, ''), COALESCE(c26, ''), COALESCE(stg.b(c27), 0), COALESCE(stg.b(c28), 0),
       COALESCE(stg.b(c29), 0), COALESCE(stg.b(c30), 0), COALESCE(stg.b(c31), 0), COALESCE(stg.b(c32), 0)
FROM stg.course;

INSERT INTO lms.course_sections (id, course, section, name, summary, summaryformat, sequence, visible, availability, timemodified)
SELECT stg.b(c0), stg.b(c1), COALESCE(stg.b(c2), 0), c3, c4, COALESCE(stg.b(c5), 0), c6, COALESCE(stg.b(c7), 1),
       c8, COALESCE(stg.b(c9), 0)
FROM stg.course_sections WHERE stg.b(c1) IN (SELECT id FROM k_course);

-- course_modules (4.0/4.1 export, 21 columns): 0 id,1 course,2 module,3 instance,4 section,5 idnumber,
-- 6 added,7 score,8 indent,9 visible,10 visibleoncoursepage,11 visibleold,12 groupmode,13 groupingid,
-- 14 completion,15 completiongradeitemnumber,16 completionview,17 completionexpected,18 showdescription,
-- 19 availability,20 deletioninprogress. groupingid 0 -> NULL (FK to lms.groupings, not supplied).
INSERT INTO lms.course_modules (id, course, module, instance, section, idnumber, added, completionexpected,
    showdescription, availability, deletioninprogress, visible, visibleoncoursepage, completion,
    completiongradeitemnumber, completionview, score, indent, visibleold, groupmode, groupingid)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), COALESCE(stg.b(c3), 0), COALESCE(stg.b(c4), 0), NULLIF(c5, ''),
       COALESCE(stg.b(c6), 0), COALESCE(stg.b(c17), 0), COALESCE(stg.b(c18), 0), c19, COALESCE(stg.b(c20), 0),
       COALESCE(stg.b(c9), 1), COALESCE(stg.b(c10), 1), COALESCE(stg.b(c14), 0), stg.b(c15),
       COALESCE(stg.b(c16), 0), COALESCE(stg.b(c7), 0), COALESCE(stg.b(c8), 0), COALESCE(stg.b(c11), 1),
       COALESCE(stg.b(c12), 0), NULLIF(stg.b(c13), 0)
FROM stg.course_modules WHERE stg.b(c1) IN (SELECT id FROM k_course);

-- ------------------------------------------------------------------ users (no email, no names)
-- Display substitute (docs/REAL_DATA_IMPORT.md): firstname = username (student code for students),
-- lastname = ''. idnumber = username when it is a 7-digit student code, so MSSV login works.
INSERT INTO lms."user" (id, auth, confirmed, deleted, suspended, mnethostid, username, password, idnumber,
    firstname, lastname, email)
SELECT stg.b(s.c0), COALESCE(NULLIF(s.c1, ''), 'manual'), 1, COALESCE(stg.b(s.c2), 0), 0, 1, s.c3, NULL,
       CASE WHEN s.c3 ~ '^[0-9]{7}$' THEN s.c3 ELSE '' END,
       left(s.c3, 100), '', ''
FROM stg."user" s JOIN k_user k ON k.id = stg.b(s.c0);

-- ------------------------------------------------------------------ enrolment, roles, contexts
INSERT INTO lms.enrol (id, enrol, status, courseid, sortorder, name, enrolperiod, enrolstartdate, enrolenddate,
    expirynotify, expirythreshold, notifyall, password, cost, currency, roleid, customint1, customint2,
    customint3, customint4, customint5, customint6, customint7, customint8, customchar1, customchar2,
    customchar3, customdec1, customdec2, customtext1, customtext2, customtext3, customtext4, timecreated, timemodified)
SELECT stg.b(c0), c1, COALESCE(stg.b(c2), 0), stg.b(c3), COALESCE(stg.b(c4), 0), c5, stg.b(c6), stg.b(c7),
       stg.b(c8), stg.b(c9), stg.b(c10), stg.b(c11),
       NULL,  -- enrolment key: never copied
       c13, c14, stg.b(c15), stg.b(c16), stg.b(c17), stg.b(c18), stg.b(c19), stg.b(c20), stg.b(c21),
       stg.b(c22), stg.b(c23), c24, c25, c26, stg.n(c27), stg.n(c28), c29, c30, c31, c32,
       COALESCE(stg.b(c33), 0), COALESCE(stg.b(c34), 0)
FROM stg.enrol WHERE stg.b(c0) IN (SELECT id FROM k_enrol);

-- modifierid has an FK to lms."user"; a modifier missing from the export (deleted account) is
-- replaced by the enrolled user's own id (audit column, not shown anywhere). Counted in the report.
INSERT INTO realimport.import_notes
SELECT 'user_enrolments.modifierid missing -> userid', count(*)
FROM stg.user_enrolments WHERE stg.b(c2) IN (SELECT id FROM k_enrol) AND stg.b(c6) NOT IN (SELECT id FROM k_user);
INSERT INTO lms.user_enrolments (id, status, enrolid, userid, timestart, timeend, modifierid, timecreated, timemodified)
SELECT stg.b(c0), COALESCE(stg.b(c1), 0), stg.b(c2), stg.b(c3), COALESCE(stg.b(c4), 0), COALESCE(stg.b(c5), 2147483647),
       CASE WHEN stg.b(c6) IN (SELECT id FROM k_user) THEN stg.b(c6) ELSE stg.b(c3) END,
       COALESCE(stg.b(c7), 0), COALESCE(stg.b(c8), 0)
FROM stg.user_enrolments
WHERE stg.b(c2) IN (SELECT id FROM k_enrol) AND stg.b(c3) IN (SELECT id FROM k_user);

INSERT INTO lms.context (id, contextlevel, instanceid, path, depth, locked)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), c3, COALESCE(stg.b(c4), 0), COALESCE(stg.b(c5), 0)
FROM stg.context WHERE stg.b(c0) IN (SELECT id FROM k_context);

INSERT INTO lms.role_assignments (id, roleid, contextid, userid, timemodified, modifierid, component, itemid, sortorder)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), stg.b(c3), COALESCE(stg.b(c4), 0), COALESCE(stg.b(c5), 0),
       COALESCE(c6, ''), COALESCE(stg.b(c7), 0), COALESCE(stg.b(c8), 0)
FROM stg.role_assignments
WHERE stg.b(c2) IN (SELECT id FROM k_context) AND stg.b(c3) IN (SELECT id FROM k_user)
  AND stg.b(c1) IN (SELECT id FROM lms.role);

-- ------------------------------------------------------------------ assignments
-- assign (30 columns): 0 id,1 course,2 name,3 intro,4 introformat,5 alwaysshowdescription,
-- 6 nosubmissions,7 submissiondrafts,8 sendnotifications,9 sendlatenotifications,10 duedate,
-- 11 allowsubmissionsfromdate,12 grade,13 timemodified,14 requiresubmissionstatement,15 completionsubmit,
-- 16 cutoffdate,17 gradingduedate,18 teamsubmission,19 requireallteammemberssubmit,
-- 20 teamsubmissiongroupingid,21 blindmarking,22 hidegrader,23 revealidentities,24 attemptreopenmethod,
-- 25 maxattempts,...
INSERT INTO lms.assign (id, course, name, intro, introformat, allowsubmissionsfromdate, duedate, grade,
    timemodified, requiresubmissionstatement, completionsubmit, cutoffdate, gradingduedate, teamsubmission,
    requireallteammemberssubmit, attemptreopenmethod, maxattempts)
SELECT stg.b(c0), stg.b(c1), c2, c3, COALESCE(stg.b(c4), 0), COALESCE(stg.b(c11), 0), COALESCE(stg.b(c10), 0),
       COALESCE(stg.b(c12), 0), COALESCE(stg.b(c13), 0), COALESCE(stg.b(c14), 0), COALESCE(stg.b(c15), 0),
       COALESCE(stg.b(c16), 0), COALESCE(stg.b(c17), 0), COALESCE(stg.b(c18), 0), COALESCE(stg.b(c19), 0),
       COALESCE(c24, 'none'), COALESCE(stg.b(c25), -1)::int
FROM stg.assign WHERE stg.b(c0) IN (SELECT id FROM k_assign);

INSERT INTO lms.assign_submission (id, assignment, userid, timecreated, timemodified, status, groupid, attemptnumber, latest)
SELECT stg.b(c0), stg.b(c1), COALESCE(stg.b(c2), 0), COALESCE(stg.b(c3), 0), COALESCE(stg.b(c4), 0), c5,
       COALESCE(stg.b(c6), 0), COALESCE(stg.b(c7), 0), COALESCE(stg.b(c8), 0)
FROM stg.assign_submission WHERE stg.b(c1) IN (SELECT id FROM k_assign);

INSERT INTO lms.assign_grades (id, assignment, userid, timecreated, timemodified, grader, grade, attemptnumber)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), COALESCE(stg.b(c3), 0), COALESCE(stg.b(c4), 0), COALESCE(stg.b(c5), 0),
       stg.n(c6), COALESCE(stg.b(c7), 0)
FROM stg.assign_grades WHERE stg.b(c1) IN (SELECT id FROM k_assign);

-- ------------------------------------------------------------------ gradebook
-- grade_categories is not in the export: one root category per course, rebuilt from the course
-- total item (itemtype='course', iteminstance = category id). Aggregation assumed Natural (13).
INSERT INTO lms.grade_categories (id, courseid, parent, depth, path, fullname, aggregation, keephigh, droplow,
    aggregateonlygraded, aggregateoutcomes, timecreated, timemodified, hidden)
-- fullname: Moodle stores '?' for a root category and displays the course name; store the course name.
SELECT DISTINCT ON (stg.b(gi.c6)) stg.b(gi.c6), stg.b(gi.c1), NULL, 1, '/' || stg.b(gi.c6) || '/',
       left(c.fullname, 255), 13, 0, 0, 1, 0, stg.b(gi.c29), stg.b(gi.c30), 0
FROM stg.grade_items gi JOIN lms.course c ON c.id = stg.b(gi.c1)
WHERE gi.c4 = 'course' AND stg.b(gi.c1) IN (SELECT id FROM k_course)
ORDER BY stg.b(gi.c6), stg.b(gi.c0);

-- grade_items (31 columns) map 1:1 onto lms.grade_items.
INSERT INTO lms.grade_items (id, courseid, categoryid, itemname, itemtype, itemmodule, iteminstance, itemnumber,
    iteminfo, idnumber, calculation, gradetype, grademax, grademin, scaleid, outcomeid, gradepass, multfactor,
    plusfactor, aggregationcoef, aggregationcoef2, sortorder, display, decimals, hidden, locked, locktime,
    needsupdate, weightoverride, timecreated, timemodified)
SELECT stg.b(c0), stg.b(c1),
       CASE WHEN stg.b(c2) IN (SELECT id FROM lms.grade_categories) THEN stg.b(c2) END,
       c3, COALESCE(c4, ''), c5, stg.b(c6), stg.b(c7), c8, c9, c10, COALESCE(stg.b(c11), 1),
       COALESCE(stg.n(c12), 100), COALESCE(stg.n(c13), 0), stg.b(c14), stg.b(c15), COALESCE(stg.n(c16), 0),
       COALESCE(stg.n(c17), 1), COALESCE(stg.n(c18), 0), COALESCE(stg.n(c19), 0), COALESCE(stg.n(c20), 0),
       COALESCE(stg.b(c21), 0), COALESCE(stg.b(c22), 0), stg.b(c23), COALESCE(stg.b(c24), 0),
       COALESCE(stg.b(c25), 0), COALESCE(stg.b(c26), 0), COALESCE(stg.b(c27), 0), COALESCE(stg.b(c28), 0),
       stg.b(c29), stg.b(c30)
FROM stg.grade_items WHERE stg.b(c0) IN (SELECT id FROM k_item);

INSERT INTO realimport.import_notes
SELECT 'grade_grades.usermodified missing -> NULL', count(*)
FROM stg.grade_grades WHERE stg.b(c1) IN (SELECT id FROM k_item) AND stg.b(c7) NOT IN (SELECT id FROM k_user);
INSERT INTO lms.grade_grades (id, itemid, userid, rawgrade, rawgrademax, rawgrademin, rawscaleid, usermodified,
    finalgrade, hidden, locked, locktime, exported, overridden, excluded, feedback, feedbackformat, information,
    informationformat, timecreated, timemodified, aggregationstatus, aggregationweight)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), stg.n(c3), COALESCE(stg.n(c4), 100), COALESCE(stg.n(c5), 0), stg.b(c6),
       CASE WHEN stg.b(c7) IN (SELECT id FROM k_user) THEN stg.b(c7) END,
       stg.n(c8), COALESCE(stg.b(c9), 0), COALESCE(stg.b(c10), 0), COALESCE(stg.b(c11), 0), COALESCE(stg.b(c12), 0),
       COALESCE(stg.b(c13), 0), COALESCE(stg.b(c14), 0), c15, COALESCE(stg.b(c16), 0), c17, COALESCE(stg.b(c18), 0),
       stg.b(c19), stg.b(c20), COALESCE(c21, 'unknown'), stg.n(c22)
FROM stg.grade_grades WHERE stg.b(c1) IN (SELECT id FROM k_item) AND stg.b(c2) IN (SELECT id FROM k_user);

-- ------------------------------------------------------------------ quizzes
-- quiz is not in the export: rebuilt from grade_items (itemmodule='quiz'): id = iteminstance,
-- course = courseid, name = itemname, grade = grademax. No open/close time is known -> 0.
-- If dlu_quiz.csv is ever supplied, stage 1 loads it and it is used instead.
DO $$
BEGIN
    IF to_regclass('stg.quiz') IS NOT NULL AND (SELECT ncols FROM stg.manifest WHERE name = 'quiz') >= 42 THEN
        -- Moodle 4.x quiz (42 columns): 0 id,1 course,2 name,3 intro,4 introformat,5 timeopen,6 timeclose,
        -- 7 timelimit,8 overduehandling,9 graceperiod,...,12 attempts,14 grademethod,...,27 sumgrades,
        -- 28 grade,29 timecreated,30 timemodified,31 password,32 subnet,...,38 completionattemptsexhausted,
        -- 39 completionpass,...,41 allowofflineattempts. password and subnet are NEVER loaded.
        INSERT INTO lms.quiz (id, course, name, intro, introformat, timeopen, timeclose, timelimit, overduehandling,
            graceperiod, attempts, grademethod, sumgrades, grade, timecreated, timemodified,
            completionattemptsexhausted, completionpass, allowofflineattempts)
        SELECT stg.b(q.c0), stg.b(q.c1), q.c2, q.c3, COALESCE(stg.b(q.c4), 0), COALESCE(stg.b(q.c5), 0),
               COALESCE(stg.b(q.c6), 0), COALESCE(stg.b(q.c7), 0), COALESCE(NULLIF(q.c8, ''), 'autoabandon'),
               COALESCE(stg.b(q.c9), 0), COALESCE(stg.b(q.c12), 0)::int, COALESCE(stg.b(q.c14), 1),
               COALESCE(stg.n(q.c27), 0), COALESCE(stg.n(q.c28), 0), COALESCE(stg.b(q.c29), 0), COALESCE(stg.b(q.c30), 0),
               stg.b(q.c38), stg.b(q.c39), stg.b(q.c41)
        FROM stg.quiz q WHERE stg.b(q.c1) IN (SELECT id FROM lms.course);
        INSERT INTO realimport.import_notes VALUES ('quiz source: export (42 columns)', 1);
    ELSIF to_regclass('stg.quiz') IS NOT NULL THEN
        INSERT INTO lms.quiz (id, course, name, timeopen, timeclose, timelimit, grade)
        SELECT stg.b(q.c0), stg.b(q.c1), q.c2, COALESCE(stg.b(q.c5), 0), COALESCE(stg.b(q.c6), 0), COALESCE(stg.b(q.c7), 0),
               COALESCE((SELECT gi.grademax FROM lms.grade_items gi
                         WHERE gi.itemmodule = 'quiz' AND gi.itemtype = 'mod' AND gi.iteminstance = stg.b(q.c0)
                         ORDER BY gi.itemnumber NULLS FIRST LIMIT 1), 0)
        FROM stg.quiz q WHERE stg.b(q.c1) IN (SELECT id FROM lms.course);
        INSERT INTO realimport.import_notes VALUES ('quiz source: dlu_quiz.csv', 1);
    ELSE
        INSERT INTO lms.quiz (id, course, name, timeopen, timeclose, grade, timecreated, timemodified)
        SELECT DISTINCT ON (gi.iteminstance) gi.iteminstance, gi.courseid, gi.itemname, 0, 0, gi.grademax,
               COALESCE(gi.timecreated, 0), COALESCE(gi.timemodified, 0)
        FROM lms.grade_items gi
        WHERE gi.itemtype = 'mod' AND gi.itemmodule = 'quiz' AND gi.iteminstance IS NOT NULL
        ORDER BY gi.iteminstance, gi.itemnumber NULLS FIRST, gi.id;
        INSERT INTO realimport.import_notes VALUES ('quiz source: grade_items reconstruction', 0);
    END IF;
END
$$;

INSERT INTO lms.quiz_attempts (id, quiz, userid, attempt, uniqueid, layout, currentpage, preview, state, timestart,
    timefinish, timemodified, timemodifiedoffline, timecheckstate, sumgrades)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), stg.b(c3)::int, stg.b(c4), c5, COALESCE(stg.b(c6), 0), COALESCE(stg.b(c7), 0),
       COALESCE(c8, 'inprogress'), COALESCE(stg.b(c9), 0), COALESCE(stg.b(c10), 0), COALESCE(stg.b(c11), 0),
       COALESCE(stg.b(c12), 0), stg.b(c13), stg.n(c14)
FROM stg.quiz_attempts
WHERE stg.b(c1) IN (SELECT id FROM lms.quiz) AND stg.b(c2) IN (SELECT id FROM k_user);

INSERT INTO lms.quiz_grades (id, quiz, userid, grade, timemodified)
SELECT stg.b(c0), stg.b(c1), stg.b(c2), COALESCE(stg.n(c3), 0), COALESCE(stg.b(c4), 0)
FROM stg.quiz_grades WHERE stg.b(c1) IN (SELECT id FROM lms.quiz);

COMMIT;
