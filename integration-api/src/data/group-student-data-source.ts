import type { ReadDatabase } from "./database.ts";
import type {
  Student,
  Course,
  Content,
  Resource,
  Assignment,
  AssignmentStatus,
  Grade,
  Progress,
  Deadline,
  StudentLearningDataSource,
  DeepLink,
} from "../domain/student-learning.ts";
import { studentIds, studentScope, visibleAssign } from "./group-scope.ts";

const statusJoins = `FROM scoped_courses c JOIN lms.assign a ON a.course=c.id
 CROSS JOIN actor u
 LEFT JOIN LATERAL (SELECT * FROM lms.assign_submission ss WHERE ss.assignment=a.id AND ss.userid=u.id
 ORDER BY ss.latest DESC,ss.attemptnumber DESC,ss.timemodified DESC,ss.id DESC LIMIT 1) sub ON true
 LEFT JOIN LATERAL (SELECT gg.finalgrade FROM lms.grade_items gi JOIN lms.grade_grades gg ON gg.itemid=gi.id
 WHERE gi.courseid=c.id AND gi.itemmodule='assign' AND gi.iteminstance=a.id AND gg.userid=u.id
 AND gi.hidden=0 AND gg.hidden=0 AND gg.finalgrade IS NOT NULL LIMIT 1) gr ON c.showgrades=1
 WHERE ${visibleAssign}`;
const statusValue = `CASE WHEN gr.finalgrade IS NOT NULL THEN 'graded'
 WHEN sub.status='submitted' AND a.duedate>0 AND sub.timemodified>a.duedate THEN 'late'
 WHEN sub.status='submitted' THEN 'submitted' WHEN sub.status='draft' THEN 'draft'
 WHEN a.duedate>0 AND a.duedate<extract(epoch FROM now()) THEN 'missing' ELSE 'not_submitted' END`;

export class GroupStudentDataSource implements StudentLearningDataSource {
  private readonly database: ReadDatabase;
  constructor(database: ReadDatabase) {
    this.database = database;
  }
  async select<T>(
    code: string,
    sql: string,
    extra: readonly unknown[] = [],
  ): Promise<T[]> {
    const id = studentIds[code];
    if (!id) return [];
    const rows = await this.database.read(studentScope + " " + sql, [
      id,
      ...extra,
    ]);
    return rows.map((row) =>
      Object.fromEntries(
        Object.entries(row).map(([k, v]) => [
          k,
          v instanceof Date ? v.toISOString() : v,
        ]),
      ),
    ) as T[];
  }
  async linked<T extends DeepLink>(
    code: string,
    sql: string,
    extra: readonly unknown[] = [],
  ): Promise<T[]> {
    return (await this.select<Omit<T, keyof DeepLink>>(code, sql, extra)).map(
      (row) => ({ ...row, deepLink: null, deepLinkStatus: "TO_VERIFY_DLU" }),
    ) as T[];
  }
  async health() {
    // Parses the essential query surfaces without exposing rows. A reachable
    // server with a missing source/app migration is not ready for this build.
    await this.database.read(`SELECT
      (SELECT id FROM lms.assign LIMIT 0),
      (SELECT userid FROM derived.student_course_learning_items LIMIT 0),
      (SELECT studentid FROM derived.teacher_student_monitoring LIMIT 0),
      (SELECT scheduled_start_at FROM app.study_plan_items LIMIT 0),
      (SELECT baseline FROM app.teacher_interventions LIMIT 0),
      (SELECT outcome_status FROM app.intervention_followups LIMIT 0)`);
  }
  async student(code: string): Promise<Student | null> {
    const rows = await this.select<
      Omit<Student, "studentCode" | "email" | "role">
    >(
      code,
      `SELECT concat(u.firstname,' ',u.lastname) AS "fullName",
      coalesce(u.department,'') AS department FROM actor u WHERE EXISTS(SELECT 1 FROM scoped_courses)`,
    );
    return rows[0]
      ? {
          ...rows[0],
          studentCode: code,
          email: code.toLowerCase() + "@example.test",
          role: "student",
        }
      : null;
  }
  courses(code: string): Promise<Course[]> {
    return this.select(
      code,
      `SELECT c.id::text AS "courseId",c.shortname AS "courseCode",c.fullname AS "courseName",
    coalesce(cat.name,'') AS "categoryName",coalesce(c.summary,'') AS summary,to_timestamp(c.startdate) AS "startsAt",
    to_timestamp(nullif(c.enddate,0)) AS "endsAt",
    (SELECT string_agg(DISTINCT concat(t.firstname,' ',t.lastname),', ') FROM lms.context ctx
      JOIN lms.role_assignments ra ON ra.contextid=ctx.id JOIN lms.role r ON r.id=ra.roleid
      JOIN lms."user" t ON t.id=ra.userid AND t.deleted=0 AND t.suspended=0
      WHERE ctx.contextlevel=50 AND ctx.instanceid=c.id AND r.shortname IN ('teacher','editingteacher')) AS "teacherNames"
    FROM scoped_courses c LEFT JOIN lms.course_categories cat ON cat.id=c.category ORDER BY c.shortname`,
    );
  }
  async content(code: string, courseId: string): Promise<Content[] | null> {
    if (!/^[1-9][0-9]{0,14}$/.test(courseId)) return null;
    if (
      !(
        await this.select(
          code,
          "SELECT id FROM scoped_courses WHERE id=$2::bigint",
          [courseId],
        )
      ).length
    )
      return null;
    return this.linked(
      code,
      `SELECT c.shortname AS "courseCode",s.section::int AS "sectionNumber",coalesce(s.name,'') AS "sectionName",
      cm.id::text AS "courseModuleId",coalesce(array_position(string_to_array(s.sequence,','),cm.id::text),0)::int AS position,
      v.activity_type AS "activityType",v.activity_name AS "activityName",''::text AS description,
      CASE WHEN v.activity_type='assign' THEN 'A-'||v.source_id ELSE NULL END AS "assignmentCode",
      to_timestamp(nullif(v.due_time,0)) AS "dueAt",NULL::text AS filenames,NULL::float8 AS "totalSizeBytes"
      FROM derived.student_course_learning_items v JOIN actor u ON u.id=v.userid
      JOIN scoped_courses c ON c.id=v.courseid JOIN lms.course_modules cm ON cm.id=v.coursemoduleid
      JOIN lms.course_sections s ON s.id=cm.section AND s.course=c.id
      WHERE c.id=$2::bigint AND cm.visible=1 AND cm.visibleoncoursepage=1 AND cm.deletioninprogress=0 AND s.visible=1
      ORDER BY s.section,position,cm.id`,
      [courseId],
    );
  }
  resources(code: string): Promise<Resource[]> {
    return this.linked(
      code,
      `SELECT c.id::text AS "courseId",c.shortname AS "courseCode",c.fullname AS "courseName",
    coalesce(s.name,'') AS "sectionName",r.id::text AS "resourceId",r.name AS "resourceName",coalesce(r.intro,'') AS description,
    NULL::text AS filename,NULL::float8 AS "fileSizeBytes",NULL::text AS "mimeType"
    FROM scoped_courses c JOIN lms.resource r ON r.course=c.id
    JOIN lms.course_modules cm ON cm.course=c.id AND cm.instance=r.id JOIN lms.modules m ON m.id=cm.module AND m.name='resource'
    JOIN lms.course_sections s ON s.id=cm.section AND s.course=c.id
    WHERE cm.visible=1 AND cm.visibleoncoursepage=1 AND cm.deletioninprogress=0 AND s.visible=1 ORDER BY c.shortname,s.section,r.id`,
    );
  }
  assignments(code: string): Promise<Assignment[]> {
    return this.linked(
      code,
      `SELECT c.id::text AS "courseId",c.shortname AS "courseCode",c.fullname AS "courseName",
    a.id::text AS "assignmentId",'A-'||a.id AS "assignmentCode",a.name AS "assignmentName",coalesce(a.intro,'') AS description,
    to_timestamp(a.allowsubmissionsfromdate) AS "opensAt",to_timestamp(nullif(a.duedate,0)) AS "dueAt",a.grade::float8 AS "maxGrade"
    FROM scoped_courses c JOIN lms.assign a ON a.course=c.id WHERE ${visibleAssign} ORDER BY a.duedate,c.shortname,a.id`,
    );
  }
  assignmentStatus(code: string): Promise<AssignmentStatus[]> {
    return this.linked(
      code,
      `SELECT c.shortname AS "courseCode",c.fullname AS "courseName",
    'A-'||a.id AS "assignmentCode",a.name AS "assignmentName",${statusValue} AS "submissionStatus",
    CASE WHEN sub.status='submitted' THEN to_timestamp(sub.timemodified) ELSE NULL END AS "submittedAt",
    coalesce(sub.status='submitted' AND a.duedate>0 AND sub.timemodified>a.duedate,false) AS "isLate",
    sub.attemptnumber::int AS "attemptNumber" ${statusJoins} ORDER BY c.shortname,a.id`,
    );
  }
  grades(code: string): Promise<Grade[]> {
    return this.select(
      code,
      `SELECT c.shortname AS "courseCode",c.fullname AS "courseName",'A-'||a.id AS "assignmentCode",
    coalesce(gi.itemname,a.name) AS "gradeItem",gg.finalgrade::float8 AS score,gi.grademax::float8 AS "maxGrade",
    (100*gg.finalgrade/nullif(gi.grademax,0))::float8 AS percentage,
    CASE WHEN gg.finalgrade>=gi.gradepass THEN 'pass' ELSE 'fail' END AS "gradeResult",gg.feedback,
    to_timestamp(gg.timemodified) AS "gradedAt",coalesce(concat(t.firstname,' ',t.lastname),'') AS "teacherName"
    FROM scoped_courses c JOIN lms.assign a ON a.course=c.id CROSS JOIN actor u
    JOIN lms.grade_items gi ON gi.courseid=c.id AND gi.itemmodule='assign' AND gi.iteminstance=a.id AND gi.hidden=0
    JOIN lms.grade_grades gg ON gg.itemid=gi.id AND gg.userid=u.id AND gg.hidden=0
    LEFT JOIN lms."user" t ON t.id=gg.usermodified
    WHERE c.showgrades=1 AND gg.finalgrade IS NOT NULL AND gg.timemodified IS NOT NULL AND ${visibleAssign} ORDER BY c.shortname,a.id`,
    );
  }
  progress(code: string): Promise<Progress[]> {
    return this.select(
      code,
      `SELECT c.id::text AS "courseId",c.shortname AS "courseCode",c.fullname AS "courseName",
    count(cm.id)::int AS "totalActivities",count(cmc.id) FILTER(WHERE cmc.completionstate IN(1,2,3))::int AS "completedActivities",
    coalesce(100.0*count(cmc.id) FILTER(WHERE cmc.completionstate IN(1,2,3))/nullif(count(cm.id),0),0)::float8 AS "progressPercent"
    FROM scoped_courses c CROSS JOIN actor u LEFT JOIN (lms.course_modules cm
    JOIN lms.course_sections s ON s.id=cm.section AND s.course=cm.course AND s.visible=1)
    ON cm.course=c.id AND cm.visible=1 AND cm.visibleoncoursepage=1 AND cm.deletioninprogress=0 AND cm.completion<>0
    LEFT JOIN lms.course_modules_completion cmc ON cmc.coursemoduleid=cm.id AND cmc.userid=u.id
    GROUP BY c.id,c.shortname,c.fullname ORDER BY c.shortname`,
    );
  }
  deadlines(code: string): Promise<Deadline[]> {
    return this.linked(
      code,
      `SELECT c.shortname AS "courseCode",c.fullname AS "courseName",
    'A-'||a.id AS "assignmentCode",a.name AS "assignmentName",to_timestamp(a.duedate) AS "dueAt",${statusValue} AS "submissionStatus",
    ceil((a.duedate-extract(epoch FROM now()))/86400)::int AS "daysRemaining" ${statusJoins}
    AND a.duedate>=extract(epoch FROM now()) AND gr.finalgrade IS NULL AND coalesce(sub.status,'')<>'submitted'
    ORDER BY a.duedate,c.shortname,a.id`,
    );
  }
}
