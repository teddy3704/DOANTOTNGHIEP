-- Least-privilege grants for the backend runtime role lms_group_app.
-- Reviewed against backend/src/main repositories (2026-11-04; V2 tables added 2026-11-08). No secrets.
-- Run as postgres on the target database (lms_mobile_group_dev or lms_mobile_group_demo) via
-- tools/Initialize-GroupRuntimeRole.ps1 or tools/Apply-V2Migration.ps1; the role must already exist.
-- Ceiling: CONNECT; USAGE on lms/derived/app; SELECT on what code reads; INSERT/UPDATE on the app
-- tables the code writes; DELETE only on app.flashcards and app.study_plan_items; USAGE/SELECT on
-- their id sequences. Nothing extra on schema lms.
\set ON_ERROR_STOP on
BEGIN;

-- Database name taken from the connection, so the same file serves the dev and demo copies.
DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO lms_group_app', current_database());
END
$$;
GRANT USAGE ON SCHEMA lms, derived, app TO lms_group_app;

-- lms tables read directly by repositories (Teacher, Notification, StudentDetail, Insights).
GRANT SELECT ON
    lms.assign_submission, lms.attendance, lms.attendance_log, lms.attendance_sessions,
    lms.attendance_statuses, lms.course, lms.course_modules, lms.course_modules_completion,
    lms.logstore_standard_log, lms.modules, lms.quiz, lms.quiz_attempts, lms."user"
TO lms_group_app;

-- derived views read by the code (none use security_invoker, so base-table rights are not needed).
GRANT SELECT ON
    derived.student_academic_profile, derived.student_attendance_summary,
    derived.student_continue_learning, derived.student_course_learning_items,
    derived.student_course_overview, derived.student_course_progress, derived.student_dashboard,
    derived.student_grade_category_summary, derived.student_grade_overview,
    derived.student_learning_analytics, derived.student_risk_indicator, derived.student_task_summary,
    derived.teacher_assignment_monitoring, derived.teacher_course_analytics,
    derived.teacher_course_overview, derived.teacher_quiz_monitoring,
    derived.teacher_student_monitoring, derived.unified_tasks
TO lms_group_app;

-- app tables: read-only reminders; read/write for the tables the code writes.
GRANT SELECT ON app.learning_reminders TO lms_group_app;
GRANT SELECT, INSERT, UPDATE ON
    app.flashcards, app.learning_goals, app.learning_reflections, app.notifications, app.teacher_notes
TO lms_group_app;
GRANT DELETE ON app.flashcards TO lms_group_app;

-- V2 (2026-11-08): grant only when the migration has created the table, so this file also
-- runs unchanged on a database that has not been migrated yet.
DO $$
BEGIN
    IF to_regclass('app.flashcard_reviews') IS NOT NULL THEN
        GRANT SELECT, INSERT, UPDATE ON app.flashcard_reviews TO lms_group_app;
    END IF;
    IF to_regclass('app.study_plan_items') IS NOT NULL THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON app.study_plan_items TO lms_group_app;
    END IF;
    IF to_regclass('app.study_sessions') IS NOT NULL THEN
        GRANT SELECT, INSERT ON app.study_sessions TO lms_group_app;
    END IF;
    -- Table already existed in the dump; code starts using it in V2-N7.
    GRANT SELECT, INSERT, UPDATE ON app.notification_preferences TO lms_group_app;
END
$$;

-- id sequences (serial or identity) of the written tables only.
DO $$
DECLARE
    t text;
    s text;
BEGIN
    FOREACH t IN ARRAY ARRAY['app.flashcards', 'app.learning_goals', 'app.learning_reflections',
                             'app.notifications', 'app.teacher_notes', 'app.flashcard_reviews',
                             'app.study_plan_items', 'app.study_sessions',
                             'app.notification_preferences'] LOOP
        IF to_regclass(t) IS NULL THEN
            CONTINUE;
        END IF;
        s := pg_get_serial_sequence(t, 'id');
        IF s IS NOT NULL THEN
            EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %s TO lms_group_app', s);
        END IF;
    END LOOP;
END
$$;

COMMIT;
