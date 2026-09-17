import type {
  Assignment,
  AssignmentStatus,
  Content,
  Course,
  Deadline,
  DeepLink,
  Grade,
  Progress,
  Resource,
  Student,
  StudentLearningDataSource,
} from "../domain/student-learning.ts";
import type { ReadDatabase } from "./database.ts";

// Legacy status/grade/deadline views preserve course membership, but do not
// themselves suppress assignments in hidden modules/sections.
const visibleAssignment = `EXISTS (
  SELECT 1 FROM lms.vw_student_assignments visible_assignment
  WHERE visible_assignment.student_code = v.student_code
    AND visible_assignment.course_code = v.course_code
    AND visible_assignment.assignment_code = v.assignment_code
)`;

export class PostgresDevelopmentDataSource implements StudentLearningDataSource {
  private readonly database: ReadDatabase;

  constructor(database: ReadDatabase) {
    this.database = database;
  }

  private async select<T extends object>(
    sql: string,
    values: readonly unknown[] = [],
  ): Promise<T[]> {
    const rows = await this.database.read(sql, values);
    // Projection aliases below are the explicit DTO boundary. PostgreSQL int8
    // identities are selected as text; aggregate/decimal values as float8.
    return rows.map((row) =>
      Object.fromEntries(
        Object.entries(row).map(([key, value]) => [
          key,
          value instanceof Date ? value.toISOString() : value,
        ]),
      ),
    ) as T[];
  }

  private async linked<T extends DeepLink>(
    sql: string,
    values: readonly unknown[],
  ): Promise<T[]> {
    const rows = await this.select<Omit<T, keyof DeepLink>>(sql, values);
    return rows.map((row) => ({
      ...row,
      deepLink: null,
      deepLinkStatus: "TO_VERIFY_DLU",
    })) as T[];
  }

  async health(): Promise<void> {
    await this.database.read("SELECT 1 AS healthy");
  }

  async student(code: string): Promise<Student | null> {
    if (code.length !== 5 || !/^SV[0-9]{3}$/.test(code)) return null;
    const rows = await this.select<Student>(
      `
      SELECT u.user_code AS "studentCode", u.full_name AS "fullName",
        u.email, u.department, 'student'::text AS role
      FROM lms.users u
      WHERE u.user_code = $1 AND u.active
        AND u.email LIKE '%@example.test'
        AND EXISTS (
          SELECT 1 FROM lms.role_assignments ra
          JOIN lms.roles r ON r.id = ra.role_id AND r.shortname = 'student'
          JOIN lms.contexts ctx ON ctx.id = ra.context_id AND ctx.context_level = 50
          JOIN lms.courses c ON c.id = ctx.instance_id
          WHERE ra.user_id = u.id
        )
      LIMIT 1`,
      [code],
    );
    return rows[0] ?? null;
  }

  courses(code: string): Promise<Course[]> {
    return this.select<Course>(
      `
      SELECT v.course_id::text AS "courseId", v.course_code AS "courseCode",
        v.course_name AS "courseName", v.category_name AS "categoryName",
        v.summary, v.starts_at AS "startsAt", v.ends_at AS "endsAt",
        v.teacher_names AS "teacherNames"
      FROM lms.vw_student_courses v WHERE v.student_code = $1
      ORDER BY v.course_code`,
      [code],
    );
  }

  async content(code: string, courseId: string): Promise<Content[] | null> {
    if (
      courseId.trim() !== courseId ||
      !/^[1-9][0-9]{0,18}$/.test(courseId) ||
      BigInt(courseId) > 9223372036854775807n
    )
      return null;
    const membership = await this.database.read(
      `
      SELECT 1 AS authorized FROM lms.vw_student_courses sc
      WHERE sc.student_code = $1 AND sc.course_id = $2::bigint
      LIMIT 1`,
      [code, courseId],
    );
    if (membership.length === 0) return null;
    return this.linked<Content>(
      `
      SELECT v.course_code AS "courseCode", v.section_number AS "sectionNumber",
        v.section_name AS "sectionName", v.course_module_id::text AS "courseModuleId",
        v.position, v.activity_type AS "activityType", v.activity_name AS "activityName",
        v.description, v.assignment_code AS "assignmentCode", v.due_at AS "dueAt",
        v.filenames, v.total_size_bytes::double precision AS "totalSizeBytes"
      FROM lms.vw_course_content v
      WHERE EXISTS (
        SELECT 1 FROM lms.vw_student_courses sc
        WHERE sc.student_code = $1 AND sc.course_id = $2::bigint
          AND sc.course_code = v.course_code
      )
      ORDER BY v.section_number, v.position, v.course_module_id`,
      [code, courseId],
    );
  }

  resources(code: string): Promise<Resource[]> {
    return this.linked<Resource>(
      `
      SELECT v.course_id::text AS "courseId", v.course_code AS "courseCode",
        v.course_name AS "courseName", v.section_name AS "sectionName",
        v.resource_id::text AS "resourceId", v.resource_name AS "resourceName",
        v.description, v.filename, v.file_size_bytes::double precision AS "fileSizeBytes",
        v.mime_type AS "mimeType"
      FROM lms.vw_student_resources v WHERE v.student_code = $1
      ORDER BY v.course_code, v.section_number, v.resource_id, v.filename, v.file_id`,
      [code],
    );
  }

  assignments(code: string): Promise<Assignment[]> {
    return this.linked<Assignment>(
      `
      SELECT v.course_id::text AS "courseId", v.course_code AS "courseCode",
        v.course_name AS "courseName", v.assignment_id::text AS "assignmentId",
        v.assignment_code AS "assignmentCode", v.assignment_name AS "assignmentName",
        v.description, v.opens_at AS "opensAt", v.due_at AS "dueAt",
        v.max_grade::double precision AS "maxGrade"
      FROM lms.vw_student_assignments v WHERE v.student_code = $1
      ORDER BY v.due_at, v.course_code, v.assignment_code`,
      [code],
    );
  }

  assignmentStatus(code: string): Promise<AssignmentStatus[]> {
    return this.linked<AssignmentStatus>(
      `
      SELECT v.course_code AS "courseCode", v.course_name AS "courseName",
        v.assignment_code AS "assignmentCode", v.assignment_name AS "assignmentName",
        v.submission_status AS "submissionStatus", v.submitted_at AS "submittedAt",
        v.is_late AS "isLate", v.attempt_number AS "attemptNumber"
      FROM lms.vw_assignment_status v
      WHERE v.student_code = $1 AND ${visibleAssignment}
      ORDER BY v.course_code, v.assignment_code`,
      [code],
    );
  }

  grades(code: string): Promise<Grade[]> {
    return this.select<Grade>(
      `
      SELECT v.course_code AS "courseCode", v.course_name AS "courseName",
        v.assignment_code AS "assignmentCode", v.grade_item AS "gradeItem",
        v.score::double precision AS score, v.max_grade::double precision AS "maxGrade",
        v.percentage::double precision AS percentage, v.grade_result AS "gradeResult",
        v.feedback, v.graded_at AS "gradedAt", v.teacher_name AS "teacherName"
      FROM lms.vw_student_grade_overview v
      WHERE v.student_code = $1 AND ${visibleAssignment}
      ORDER BY v.course_code, v.assignment_code`,
      [code],
    );
  }

  progress(code: string): Promise<Progress[]> {
    return this.select<Progress>(
      `
      SELECT v.course_id::text AS "courseId", v.course_code AS "courseCode",
        v.course_name AS "courseName", v.total_activities::double precision AS "totalActivities",
        v.completed_activities::double precision AS "completedActivities",
        v.progress_percent::double precision AS "progressPercent"
      FROM lms.vw_student_progress v WHERE v.student_code = $1
      ORDER BY v.course_code`,
      [code],
    );
  }

  deadlines(code: string): Promise<Deadline[]> {
    return this.linked<Deadline>(
      `
      SELECT v.course_code AS "courseCode", v.course_name AS "courseName",
        v.assignment_code AS "assignmentCode", v.assignment_name AS "assignmentName",
        v.due_at AS "dueAt", v.submission_status AS "submissionStatus",
        v.days_remaining AS "daysRemaining"
      FROM lms.vw_upcoming_deadlines v
      WHERE v.student_code = $1 AND ${visibleAssignment}
      ORDER BY v.due_at, v.course_code, v.assignment_code`,
      [code],
    );
  }
}
