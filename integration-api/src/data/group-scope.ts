// Explicit aliases for reviewed synthetic GROUP_39_20 identities, not DLU login.
export const studentIds: Readonly<Record<string, string>> = Object.freeze({
  SV001: "201",
  SV002: "202",
});
export const teacherIds: Readonly<Record<string, string>> = Object.freeze({
  GV001: "101",
  GV002: "102",
});
export const studentScope = `WITH actor AS (
 SELECT u.* FROM lms."user" u WHERE u.id=$1::bigint AND u.deleted=0 AND u.suspended=0
), scoped_courses AS (
 SELECT DISTINCT c.* FROM actor u
 JOIN lms.user_enrolments ue ON ue.userid=u.id AND ue.status=0
 JOIN lms.enrol e ON e.id=ue.enrolid AND e.status=0
 JOIN lms.course c ON c.id=e.courseid AND c.visible=1
 JOIN lms.context ctx ON ctx.contextlevel=50 AND ctx.instanceid=c.id
 JOIN lms.role_assignments ra ON ra.userid=u.id AND ra.contextid=ctx.id
 JOIN lms.role r ON r.id=ra.roleid AND (r.shortname='student' OR r.archetype='student')
 WHERE (ue.timestart=0 OR ue.timestart<=extract(epoch FROM now()))
 AND (ue.timeend=0 OR ue.timeend>extract(epoch FROM now()))
)`;
export const teacherScope = `WITH actor AS (
 SELECT u.* FROM lms."user" u WHERE u.id=$1::bigint AND u.deleted=0 AND u.suspended=0
), scoped_courses AS (
 SELECT DISTINCT c.* FROM actor u
 JOIN lms.role_assignments ra ON ra.userid=u.id
 JOIN lms.role r ON r.id=ra.roleid AND (r.shortname IN ('teacher','editingteacher') OR r.archetype IN ('teacher','editingteacher'))
 JOIN lms.context ctx ON ctx.id=ra.contextid AND ctx.contextlevel=50
 JOIN lms.course c ON c.id=ctx.instanceid AND c.visible=1
)`;
// Aliases u/c are the active learner and the teacher-scoped course. Reused by
// roster and attention so an expired enrolment cannot remain visible in either.
export const activeStudentInCourse = `EXISTS(SELECT 1 FROM lms.user_enrolments ue
 JOIN lms.enrol e ON e.id=ue.enrolid AND e.courseid=c.id AND e.status=0
 JOIN lms.context ctx ON ctx.contextlevel=50 AND ctx.instanceid=c.id
 JOIN lms.role_assignments ra ON ra.userid=u.id AND ra.contextid=ctx.id
 JOIN lms.role r ON r.id=ra.roleid AND (r.shortname='student' OR r.archetype='student')
 WHERE ue.userid=u.id AND ue.status=0
 AND (ue.timestart=0 OR ue.timestart<=extract(epoch FROM now()))
 AND (ue.timeend=0 OR ue.timeend>extract(epoch FROM now())))`;
export const visibleAssign = `EXISTS (SELECT 1 FROM lms.course_modules cm
 JOIN lms.modules m ON m.id=cm.module AND m.name='assign'
 JOIN lms.course_sections sec ON sec.id=cm.section AND sec.course=cm.course AND sec.visible=1
 WHERE cm.course=a.course AND cm.instance=a.id AND cm.visible=1
 AND cm.visibleoncoursepage=1 AND cm.deletioninprogress=0)`;
