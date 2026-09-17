import type { Student, StudentLearningDataSource } from "./student-learning.ts";

export class ApiFailure extends Error {
  readonly statusCode: number;
  readonly code: string;
  constructor(statusCode: number, code: string, message: string) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

export class LearningService {
  readonly source: StudentLearningDataSource;
  constructor(source: StudentLearningDataSource) {
    this.source = source;
  }
  async read<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      if (error instanceof ApiFailure) throw error;
      throw new ApiFailure(
        503,
        "DATA_SOURCE_UNAVAILABLE",
        "Dữ liệu học tập tạm thời chưa sẵn sàng. Vui lòng thử lại.",
      );
    }
  }
  async identify(header: unknown, enabled: boolean): Promise<Student> {
    if (!enabled || typeof header !== "string" || !/^SV\d{3}$/.test(header)) {
      throw new ApiFailure(
        401,
        "DEVELOPMENT_IDENTITY_REQUIRED",
        "Cần mã sinh viên mẫu hợp lệ để sử dụng môi trường phát triển.",
      );
    }
    const student = await this.read(() => this.source.student(header));
    if (!student)
      throw new ApiFailure(
        401,
        "DEVELOPMENT_IDENTITY_INVALID",
        "Mã sinh viên mẫu không hợp lệ.",
      );
    return student;
  }
  async content(code: string, courseId: string) {
    const content = await this.read(() => this.source.content(code, courseId));
    if (content === null)
      throw new ApiFailure(
        404,
        "COURSE_NOT_FOUND",
        "Không tìm thấy khóa học được phép truy cập.",
      );
    return content;
  }
  async overview(student: Student) {
    const code = student.studentCode;
    const [courses, statuses, grades, progress, deadlines] = await this.read(
      () =>
        Promise.all([
          this.source.courses(code),
          this.source.assignmentStatus(code),
          this.source.grades(code),
          this.source.progress(code),
          this.source.deadlines(code),
        ]),
    );
    return {
      student,
      courseCount: courses.length,
      upcomingDeadlineCount: deadlines.length,
      assignmentSummary: {
        total: statuses.length,
        submitted: statuses.filter((s) =>
          ["submitted", "late", "graded"].includes(s.submissionStatus),
        ).length,
        graded: statuses.filter((s) => s.submissionStatus === "graded").length,
        outstanding: statuses.filter((s) =>
          [
            "not_submitted",
            "missing",
            "draft",
            "returned_for_resubmission",
          ].includes(s.submissionStatus),
        ).length,
        late: statuses.filter((s) => s.isLate).length,
      },
      progressSummary: progress,
      gradeSummary: { gradedItemCount: grades.length },
      nextDeadline: deadlines[0] ?? null,
    };
  }
}
