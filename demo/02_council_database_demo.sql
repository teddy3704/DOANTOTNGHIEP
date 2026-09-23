-- GROUP_39_20 development/staging, synthetic data. NOT DLU production records.
-- Run 01_verify_database_baseline.sql first. No academic or app writes.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '10s';

-- Identity -> role -> course context (separate from enrolment).
SELECT u.id AS synthetic_user_id, r.shortname AS role, ctx.contextlevel,
       c.shortname AS course_code
FROM lms."user" u JOIN lms.role_assignments ra ON ra.userid=u.id
JOIN lms.role r ON r.id=ra.roleid JOIN lms.context ctx ON ctx.id=ra.contextid
LEFT JOIN lms.course c ON ctx.contextlevel=50 AND c.id=ctx.instanceid
WHERE u.id IN (201,101) AND u.deleted=0 AND u.suspended=0
ORDER BY u.id,c.shortname,r.shortname;

SELECT ue.userid AS synthetic_user_id, c.shortname,c.fullname
FROM lms.user_enrolments ue JOIN lms.enrol e ON e.id=ue.enrolid
JOIN lms.course c ON c.id=e.courseid
WHERE ue.userid=201 AND ue.status=0 AND e.status=0 AND c.visible=1
ORDER BY c.shortname;

-- A course module's instance is polymorphic, interpreted via modules.name.
SELECT c.shortname,s.section,s.name,m.name AS module_type,cm.instance
FROM lms.course c JOIN lms.course_sections s ON s.course=c.id
JOIN lms.course_modules cm ON cm.course=c.id AND cm.section=s.id
JOIN lms.modules m ON m.id=cm.module
WHERE c.id=11 AND s.visible=1 AND cm.visible=1 AND cm.deletioninprogress=0
ORDER BY s.section,cm.id;

SELECT course_shortname,course_name,completed_activities,total_tracked_activities,
       progress_percentage,pending_tasks,overdue_tasks
FROM derived.student_course_overview WHERE userid=201 ORDER BY courseid;

SELECT course_name,task_type,title,due_time,task_status
FROM derived.unified_tasks WHERE userid=201 ORDER BY due_time,title LIMIT 12;

-- Rule-based support indicator, NOT AI or an automatic academic decision.
SELECT course_name,student_name,progress_percentage,pending_tasks,overdue_tasks,risk_level
FROM derived.teacher_student_monitoring WHERE teacherid=101 AND courseid=11
ORDER BY studentid;

SELECT course_name,assignment_name,student_count,submitted_count,
       not_submitted_count,needs_grading_count,overdue_missing_count
FROM derived.teacher_assignment_monitoring WHERE teacherid=101
ORDER BY courseid,assignment_id;

-- Mobile-owned support records; no authentication fields or message content.
SELECT 'learning_reminders' AS model,count(*) AS own_rows FROM app.learning_reminders WHERE user_id=201
UNION ALL SELECT 'notifications',count(*) FROM app.notifications WHERE user_id=201
UNION ALL SELECT 'notification_preferences',count(*) FROM app.notification_preferences WHERE user_id=201
UNION ALL SELECT 'learning_goals',count(*) FROM app.learning_goals WHERE user_id=201;
COMMIT;
