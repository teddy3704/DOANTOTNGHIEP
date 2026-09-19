-- Verified against the currently configured Neon development database.
-- This is the 22-table lms baseline, NOT the group's 39-table export.
-- Run 01_verify_database_baseline.sql first for catalog counts.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '10s';

-- Role is scoped to a context; enrolment is a separate relationship.
SELECT u.user_code, r.shortname AS role, ctx.context_level, c.course_code
FROM lms.users u
JOIN lms.role_assignments ra ON ra.user_id = u.id
JOIN lms.roles r ON r.id = ra.role_id
JOIN lms.contexts ctx ON ctx.id = ra.context_id
LEFT JOIN lms.courses c ON ctx.context_level = 50 AND c.id = ctx.instance_id
WHERE u.active AND u.user_code IN ('SV001', 'GV001')
ORDER BY u.user_code, c.course_code, r.shortname;

SELECT u.user_code, c.course_code, c.name AS course_name, ue.active
FROM lms.users u
JOIN lms.user_enrolments ue ON ue.user_id = u.id
JOIN lms.enrolments e ON e.id = ue.enrolment_id
JOIN lms.courses c ON c.id = e.course_id
WHERE u.user_code = 'SV001' AND ue.active AND e.active
ORDER BY c.course_code;

-- instance_id is polymorphic: interpret with modules.name, not a universal FK.
SELECT c.course_code, s.section_number, s.name AS section_name,
       m.name AS module_type, cm.instance_id
FROM lms.courses c
JOIN lms.course_sections s ON s.course_id = c.id
JOIN lms.course_modules cm ON cm.section_id = s.id AND cm.course_id = c.id
JOIN lms.modules m ON m.id = cm.module_id
WHERE c.visible AND s.visible AND cm.visible
ORDER BY c.course_code, s.section_number, cm.position LIMIT 12;

SELECT student_code, course_code, course_name, teacher_names
FROM lms.vw_student_courses WHERE student_code = 'SV001'
ORDER BY course_code;

-- These Teacher views exist in SQL; there is currently NO deployed Teacher API.
SELECT teacher_code, course_code, student_code, progress_percent,
       submitted_count, missing_or_draft_count
FROM lms.vw_teacher_roster WHERE teacher_code = 'GV001'
ORDER BY course_code, student_code LIMIT 12;

SELECT teacher_code, course_code, assignment_code, submission_status,
       count(*) AS student_count
FROM lms.vw_teacher_submission_overview WHERE teacher_code = 'GV001'
GROUP BY teacher_code, course_code, assignment_code, submission_status
ORDER BY course_code, assignment_code, submission_status;

-- No unified_tasks view in this baseline. Use its verified progress read model.
SELECT student_code, course_code, completed_activities, total_activities,
       progress_percent
FROM lms.vw_student_progress WHERE student_code = 'SV001'
ORDER BY course_code;
COMMIT;
