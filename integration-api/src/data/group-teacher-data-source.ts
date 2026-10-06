import type { ReadDatabase } from "./database.ts";
import type {
  TeacherProfile,
  TeachingCourse,
  TeachingWork,
  TeachingSection,
  StudentMonitoring,
  TeacherSupportDataSource,
} from "../domain/teacher-support.ts";
import { teacherIds, teacherScope, visibleAssign } from "./group-scope.ts";

export class GroupTeacherDataSource implements TeacherSupportDataSource {
  private readonly database: ReadDatabase;
  constructor(database: ReadDatabase) {
    this.database = database;
  }
  private async read<T>(
    code: string,
    sql: string,
    extra: readonly unknown[] = [],
  ): Promise<T[]> {
    const id = teacherIds[code];
    if (!id) return [];
    const rows = await this.database.read(teacherScope + " " + sql, [
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
  async teacher(code: string): Promise<TeacherProfile | null> {
    const rows = await this.read<{ fullName: string; department: string }>(
      code,
      `SELECT concat(u.firstname,' ',u.lastname) AS "fullName",
      coalesce(u.department,'') AS department FROM actor u WHERE EXISTS(SELECT 1 FROM scoped_courses)`,
    );
    return rows[0]
      ? {
          ...rows[0],
          teacherCode: code,
          email: code.toLowerCase() + "@example.test",
          role: "teacher",
        }
      : null;
  }
  async courses(code: string): Promise<TeachingCourse[]> {
    const [courses, work, sections] = await Promise.all([
      this.read<Omit<TeachingCourse, "work" | "sections">>(
        code,
        `SELECT c.id::text AS id,c.fullname AS name,c.shortname AS code,
        coalesce(c.summary,'') AS summary,v.student_count::int AS "studentCount" FROM scoped_courses c
        JOIN derived.teacher_course_overview v ON v.courseid=c.id AND v.teacherid=$1::bigint ORDER BY c.shortname`,
      ),
      this.read<TeachingWork & { courseId: string }>(
        code,
        `SELECT c.id::text AS "courseId",a.name AS title,coalesce(a.intro,'') AS description,
        to_timestamp(a.duedate) AS "dueAt",v.submitted_count::int AS submitted,v.student_count::int AS "studentCount"
        FROM scoped_courses c JOIN lms.assign a ON a.course=c.id
        JOIN derived.teacher_assignment_monitoring v ON v.assignment_id=a.id AND v.teacherid=$1::bigint
        WHERE ${visibleAssign} ORDER BY a.duedate,a.id`,
      ),
      this.read<TeachingSection & { courseId: string }>(
        code,
        `SELECT c.id::text AS "courseId",coalesce(s.name,'') AS title,
        coalesce(array_agg(r.name ORDER BY cm.id) FILTER(WHERE r.name IS NOT NULL),ARRAY[]::text[]) AS resources
        FROM scoped_courses c JOIN lms.course_sections s ON s.course=c.id AND s.visible=1
        LEFT JOIN lms.course_modules cm ON cm.course=c.id AND cm.section=s.id AND cm.visible=1 AND cm.visibleoncoursepage=1 AND cm.deletioninprogress=0
        LEFT JOIN lms.modules m ON m.id=cm.module AND m.name='resource'
        LEFT JOIN lms.resource r ON r.id=cm.instance AND r.course=c.id AND m.id IS NOT NULL
        GROUP BY c.id,s.id,s.name,s.section ORDER BY c.id,s.section`,
      ),
    ]);
    return courses.map((c) => ({
      ...c,
      work: work
        .filter((w) => w.courseId === c.id)
        .map(({ courseId: _, ...w }) => w),
      sections: sections
        .filter((s) => s.courseId === c.id)
        .map(({ courseId: _, ...s }) => s),
    }));
  }
  async students(
    code: string,
    courseId: string,
  ): Promise<StudentMonitoring[] | null> {
    if (!/^[1-9][0-9]{0,14}$/.test(courseId)) return null;
    if (
      !(
        await this.read(
          code,
          "SELECT id FROM scoped_courses WHERE id=$2::bigint",
          [courseId],
        )
      ).length
    )
      return null;
    return this.read(
      code,
      `SELECT v.courseid::text AS "courseId",v.studentid::text AS "studentId",v.student_name AS "studentName",
      v.progress_percentage::float8 AS "progressPercent",v.pending_tasks::int AS "pendingTasks",v.overdue_tasks::int AS "overdueTasks",
      v.risk_level AS "riskLevel" FROM derived.teacher_student_monitoring v JOIN scoped_courses c ON c.id=v.courseid
      JOIN lms."user" u ON u.id=v.studentid AND u.deleted=0 AND u.suspended=0
      WHERE v.teacherid=$1::bigint AND v.courseid=$2::bigint ORDER BY v.student_name,v.studentid`,
      [courseId],
    );
  }
  async attention(
    code: string,
  ): Promise<(StudentMonitoring & { courseName: string })[]> {
    return this.read(
      code,
      `SELECT v.courseid::text AS "courseId",c.fullname AS "courseName",v.studentid::text AS "studentId",v.student_name AS "studentName",
      v.progress_percentage::float8 AS "progressPercent",v.pending_tasks::int AS "pendingTasks",v.overdue_tasks::int AS "overdueTasks",v.risk_level AS "riskLevel"
      FROM derived.teacher_student_monitoring v JOIN scoped_courses c ON c.id=v.courseid
      JOIN lms."user" u ON u.id=v.studentid AND u.deleted=0 AND u.suspended=0
      WHERE v.teacherid=$1::bigint AND EXISTS(SELECT 1 FROM lms.user_enrolments ue JOIN lms.enrol e ON e.id=ue.enrolid AND e.courseid=c.id AND e.status=0
      JOIN lms.context ctx ON ctx.contextlevel=50 AND ctx.instanceid=c.id
      JOIN lms.role_assignments ra ON ra.userid=u.id AND ra.contextid=ctx.id
      JOIN lms.role r ON r.id=ra.roleid AND (r.shortname='student' OR r.archetype='student')
      WHERE ue.userid=u.id AND ue.status=0 AND (ue.timestart=0 OR ue.timestart<=extract(epoch FROM now())) AND (ue.timeend=0 OR ue.timeend>extract(epoch FROM now())))
      ORDER BY c.id,v.studentid`,
    );
  }
}
