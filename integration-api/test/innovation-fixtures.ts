import { randomUUID } from "node:crypto";
import type {
  Assignment,
  AssignmentStatus,
  Progress,
  StudentLearningDataSource,
} from "../src/domain/student-learning.ts";
import type { TeacherSupportDataSource } from "../src/domain/teacher-support.ts";
import type {
  Attention,
  InnovationStore,
  Intervention,
  InterventionCreate,
  InterventionPatch,
  FollowupCreate,
  PlanItem,
  PlanCreate,
  PlanPatch,
  Recommendation,
  Snapshot,
} from "../src/domain/innovation.ts";
import { snapshotOf } from "../src/domain/innovation.ts";

// MOCK data only. No .env, credentials or external service is used by these tests.
export const fixedNow = new Date("2030-01-01T12:00:00.000Z");
export function assignment(id = "20", hours = 24, courseId = "1"): Assignment {
  return {
    assignmentId: id,
    assignmentCode: `BT${id}`,
    assignmentName: `Bài tập ${id}`,
    courseId,
    courseCode: `COURSE${courseId}`,
    courseName: `Học phần ${courseId}`,
    description: "Nội dung trên LMS",
    opensAt: "2029-12-01T00:00:00.000Z",
    dueAt: new Date(fixedNow.getTime() + hours * 3600000).toISOString(),
    maxGrade: 10,
    deepLink: null,
    deepLinkStatus: "TO_VERIFY_DLU",
  };
}
export function assignmentStatus(
  a: Assignment,
  submissionStatus: AssignmentStatus["submissionStatus"] = "not_submitted",
): AssignmentStatus {
  return {
    courseCode: a.courseCode,
    courseName: a.courseName,
    assignmentCode: a.assignmentCode,
    assignmentName: a.assignmentName,
    submissionStatus,
    submittedAt: null,
    isLate: false,
    attemptNumber: null,
    deepLink: null,
    deepLinkStatus: "TO_VERIFY_DLU",
  };
}
export function progress(courseId = "1", percent = 75, total = 4): Progress {
  return {
    courseId,
    courseCode: `COURSE${courseId}`,
    courseName: `Học phần ${courseId}`,
    totalActivities: total,
    completedActivities: (total * percent) / 100,
    progressPercent: percent,
  };
}
export function attention(courseId = "1", studentId = "201"): Attention {
  return {
    courseId,
    courseName: `Học phần ${courseId}`,
    studentId,
    studentName: `Sinh viên ${studentId}`,
    progressPercent: 25,
    pendingTasks: 2,
    overdueTasks: 1,
    priorityScore: 50,
    priority: "medium",
    reasons: [
      "1 bài tập quá hạn chưa hoàn tất",
      "2 bài tập đang chờ thực hiện",
      "Tiến độ hoạt động dưới 50%",
    ],
  };
}
export function sources() {
  const assignments = {
    SV001: [assignment()],
    SV002: [assignment("30", 24, "2")],
  };
  const student: StudentLearningDataSource = {
    async health() {},
    async student(code) {
      return Object.hasOwn(assignments, code)
        ? {
            studentCode: code,
            fullName: `Sinh viên ${code}`,
            email: code.toLowerCase() + "@example.test",
            department: "Khoa mẫu",
            role: "student",
          }
        : null;
    },
    async courses(code) {
      return (await this.assignments(code)).map((a) => ({
        courseId: a.courseId,
        courseCode: a.courseCode,
        courseName: a.courseName,
        summary: "Nội dung",
        categoryName: "Mẫu",
        startsAt: a.opensAt,
        endsAt: null,
        teacherNames: null,
      }));
    },
    async content(code, courseId) {
      return (await this.assignments(code)).some((a) => a.courseId === courseId)
        ? []
        : null;
    },
    async resources() {
      return [];
    },
    async assignments(code) {
      return assignments[code as keyof typeof assignments] ?? [];
    },
    async assignmentStatus(code) {
      return (await this.assignments(code)).map((a) => assignmentStatus(a));
    },
    async grades() {
      return [];
    },
    async progress(code) {
      return (await this.assignments(code)).map((a) => progress(a.courseId));
    },
    async deadlines() {
      return [];
    },
  };
  let metrics: Attention = attention();
  const teacher: TeacherSupportDataSource = {
    async teacher(code) {
      return ["GV001", "GV002"].includes(code)
        ? {
            teacherCode: code,
            fullName: `Giảng viên ${code}`,
            email: code.toLowerCase() + "@example.test",
            department: "Khoa mẫu",
            role: "teacher",
          }
        : null;
    },
    async courses(code) {
      const courseId = code === "GV001" ? "1" : "2";
      return [
        {
          id: courseId,
          code: `COURSE${courseId}`,
          name: `Học phần ${courseId}`,
          summary: "Nội dung",
          studentCount: 1,
          work: [],
          sections: [],
        },
      ];
    },
    async students(code, courseId) {
      const rows = await this.attention!(code);
      return rows[0]?.courseId === courseId
        ? rows.map((a) => ({ ...a, riskLevel: "MEDIUM" }))
        : null;
    },
    async attention(code) {
      return code === "GV001"
        ? [{ ...metrics, riskLevel: "MEDIUM" }]
        : [{ ...attention("2", "202"), riskLevel: "MEDIUM" }];
    },
  };
  return {
    student,
    teacher,
    setMetrics(value: Attention) {
      metrics = value;
    },
  };
}

// Shared backing state simulates repository persistence across service instances;
// actual PostgreSQL persistence is verified separately on the approved candidate.
export class MemoryInnovationStore implements InnovationStore {
  private planRows = new Map<string, PlanItem[]>();
  private interventionRows = new Map<string, Intervention[]>();
  async plans(code: string) {
    return structuredClone(this.planRows.get(code) ?? []);
  }
  async createPlan(code: string, r: Recommendation, input: PlanCreate) {
    const rows = this.planRows.get(code) ?? [];
    if (rows.some((p) => p.assignmentId === input.assignmentId)) return null;
    const item: PlanItem = {
      id: randomUUID(),
      assignmentId: r.assignmentId,
      assignmentCode: r.assignmentCode,
      courseId: r.courseId,
      courseName: r.courseName,
      title: r.assignmentName,
      dueAt: r.dueAt,
      priorityScore: r.priorityScore,
      priority: r.priority,
      reasons: r.reasons,
      scheduledStartAt: input.scheduledStartAt,
      estimatedMinutes: input.estimatedMinutes ?? 45,
      notes: input.notes ?? "",
      status: "planned",
      createdAt: fixedNow.toISOString(),
      updatedAt: fixedNow.toISOString(),
    };
    rows.push(item);
    this.planRows.set(code, rows);
    return structuredClone(item);
  }
  async updatePlan(code: string, id: string, patch: PlanPatch) {
    const item = this.planRows.get(code)?.find((p) => p.id === id);
    if (!item) return null;
    Object.assign(item, patch);
    return structuredClone(item);
  }
  async deletePlan(code: string, id: string) {
    const rows = this.planRows.get(code);
    if (!rows?.some((p) => p.id === id)) return false;
    this.planRows.set(
      code,
      rows.filter((p) => p.id !== id),
    );
    return true;
  }
  async interventions(code: string) {
    return structuredClone(this.interventionRows.get(code) ?? []);
  }
  async createIntervention(
    code: string,
    a: Attention,
    input: InterventionCreate,
  ) {
    const rows = this.interventionRows.get(code) ?? [];
    if (
      rows.some(
        (i) =>
          i.courseId === a.courseId &&
          i.studentId === a.studentId &&
          i.status !== "resolved",
      )
    )
      return null;
    const item: Intervention = {
      ...input,
      id: randomUUID(),
      studentName: a.studentName,
      courseName: a.courseName,
      status: "open",
      reasons: a.reasons,
      baseline: snapshotOf(a),
      current: snapshotOf(a),
      followups: [],
      createdAt: fixedNow.toISOString(),
      updatedAt: fixedNow.toISOString(),
    };
    rows.push(item);
    this.interventionRows.set(code, rows);
    return structuredClone(item);
  }
  async updateIntervention(code: string, id: string, patch: InterventionPatch) {
    const item = this.interventionRows.get(code)?.find((i) => i.id === id);
    if (!item) return null;
    Object.assign(item, patch);
    if (item.status === "resolved") item.followUpAt = null;
    return structuredClone(item);
  }
  async addFollowup(
    code: string,
    id: string,
    snapshot: Snapshot,
    input: FollowupCreate,
  ) {
    const item = this.interventionRows.get(code)?.find((i) => i.id === id);
    if (!item || item.status === "resolved" || item.followups.length >= 100)
      return null;
    item.followups.push({
      ...snapshot,
      id: randomUUID(),
      note: input.note,
      outcomeStatus: input.outcomeStatus,
      createdAt: fixedNow.toISOString(),
    });
    item.status = input.outcomeStatus;
    if (input.outcomeStatus === "resolved") item.followUpAt = null;
    else if (Object.hasOwn(input, "nextFollowUpAt"))
      item.followUpAt = input.nextFollowUpAt ?? null;
    return structuredClone(item);
  }
}
