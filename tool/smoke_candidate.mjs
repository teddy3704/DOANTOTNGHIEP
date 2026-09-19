import { connectCandidate, safeFailure } from './candidate_database.mjs';
let db;
try {
  db = await connectCandidate();
  await db.query('BEGIN READ ONLY');
  const checks = {
    student_course_scope: `SELECT count(*)::int AS violations FROM derived.student_course_overview v WHERE NOT EXISTS (
      SELECT 1 FROM lms.user_enrolments ue JOIN lms.enrol e ON e.id=ue.enrolid JOIN lms.role r ON r.id=e.roleid
      WHERE ue.userid=v.userid AND e.courseid=v.courseid AND ue.status=0 AND e.status=0 AND (r.shortname='student' OR r.archetype='student'))`,
    teacher_course_scope: `SELECT count(*)::int AS violations FROM derived.teacher_course_overview v WHERE NOT EXISTS (
      SELECT 1 FROM lms.role_assignments ra JOIN lms.role r ON r.id=ra.roleid JOIN lms.context ctx ON ctx.id=ra.contextid
      WHERE ra.userid=v.teacherid AND ctx.contextlevel=50 AND ctx.instanceid=v.courseid
      AND (r.shortname IN ('teacher','editingteacher') OR r.archetype IN ('teacher','editingteacher')))`,
    teacher_student_scope: `SELECT count(*)::int AS violations FROM derived.teacher_student_monitoring v
      WHERE NOT EXISTS (SELECT 1 FROM derived.teacher_course_overview t WHERE t.teacherid=v.teacherid AND t.courseid=v.courseid)
      OR NOT EXISTS (SELECT 1 FROM derived.student_course_overview s WHERE s.userid=v.studentid AND s.courseid=v.courseid)`,
    teacher_assignment_scope: `SELECT count(*)::int AS violations FROM derived.teacher_assignment_monitoring v
      WHERE NOT EXISTS (SELECT 1 FROM derived.teacher_course_overview t WHERE t.teacherid=v.teacherid AND t.courseid=v.courseid)
      OR NOT EXISTS (SELECT 1 FROM lms.assign a WHERE a.id=v.assignment_id AND a.course=v.courseid)`,
    student_task_scope: `SELECT count(*)::int AS violations FROM derived.unified_tasks v
      WHERE NOT EXISTS (SELECT 1 FROM derived.student_course_overview s WHERE s.userid=v.userid AND s.courseid=v.courseid)`,
    student_grade_scope: `SELECT count(*)::int AS violations FROM derived.student_grade_overview v
      WHERE NOT EXISTS (SELECT 1 FROM derived.student_course_overview s WHERE s.userid=v.userid AND s.courseid=v.courseid)`,
    progress_bounds: `SELECT count(*)::int AS violations FROM derived.student_course_progress WHERE progress_percentage NOT BETWEEN 0 AND 100 OR completed_activities>total_tracked_activities`,
    assignment_bounds: `SELECT count(*)::int AS violations FROM derived.teacher_assignment_monitoring WHERE submitted_count+not_submitted_count<>student_count OR needs_grading_count>submitted_count`,
    duplicate_student_course: `SELECT count(*)::int AS violations FROM (SELECT userid,courseid FROM derived.student_course_overview GROUP BY 1,2 HAVING count(*)>1) x`,
    duplicate_teacher_student: `SELECT count(*)::int AS violations FROM (SELECT teacherid,courseid,studentid FROM derived.teacher_student_monitoring GROUP BY 1,2,3 HAVING count(*)>1) x`,
    duplicate_tasks: `SELECT count(*)::int AS violations FROM (SELECT userid,courseid,task_type,source_id FROM derived.unified_tasks GROUP BY 1,2,3,4 HAVING count(*)>1) x`,
  };
  let pass=true;
  for(const [name,sql] of Object.entries(checks)) {
    const result=(await db.query(sql)).rows[0];
    console.log(JSON.stringify({check:name,...result}));
    pass &&= result.violations===0;
  }
  console.log(JSON.stringify({identities:(await db.query(`SELECT u.id::text,u.username,u.idnumber,
    bool_or(r.shortname='student') AS student, bool_or(r.shortname IN ('teacher','editingteacher')) AS teacher,
    u.email LIKE '%@example.test' AS reserved_email
    FROM lms."user" u JOIN lms.role_assignments ra ON ra.userid=u.id JOIN lms.role r ON r.id=ra.roleid
    JOIN lms.context ctx ON ctx.id=ra.contextid AND ctx.contextlevel=50
    GROUP BY u.id ORDER BY u.id`)).rows}));
  console.log(JSON.stringify({taskStates:(await db.query('SELECT task_status,count(*)::int AS rows FROM derived.unified_tasks GROUP BY task_status ORDER BY task_status')).rows}));
  console.log(JSON.stringify({teacherScopes:(await db.query('SELECT teacherid::text,array_agg(courseid::text ORDER BY courseid) AS courses FROM derived.teacher_course_overview GROUP BY teacherid ORDER BY teacherid')).rows}));
  console.log(JSON.stringify({smoke:pass?'PASS':'FAIL',scope:'READ_ONLY_CANDIDATE'}));
  await db.query('COMMIT');
  if(!pass) process.exitCode=1;
} catch(error) { console.log(JSON.stringify(safeFailure(error))); process.exitCode=1;
} finally { await db?.end().catch(()=>{}); }
