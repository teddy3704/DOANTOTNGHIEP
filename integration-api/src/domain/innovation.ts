import type {
  Assignment,
  AssignmentStatus,
  Progress,
  StudentLearningDataSource,
} from "./student-learning.ts";
import type {
  StudentMonitoring,
  TeacherSupportDataSource,
} from "./teacher-support.ts";
import { ApiFailure } from "./learning-service.ts";
import { priorityRules as rules } from "./priority-rules.ts";

export type Priority = "high" | "medium" | "low";
export interface Recommendation {
  sourceType: "assignment";
  assignmentId: string;
  assignmentCode: string;
  assignmentName: string;
  courseId: string;
  courseCode: string;
  courseName: string;
  dueAt: string;
  submissionStatus: AssignmentStatus["submissionStatus"];
  priorityScore: number;
  priority: Priority;
  reasons: string[];
  recommendedDurationMinutes: number;
  planned: boolean;
}
export interface PlanItem {
  id: string;
  assignmentId: string;
  assignmentCode: string;
  courseId: string;
  courseName: string;
  title: string;
  dueAt: string;
  priorityScore: number;
  priority: Priority;
  reasons: string[];
  scheduledStartAt: string;
  estimatedMinutes: number;
  notes: string;
  status: "planned" | "handled";
  createdAt: string;
  updatedAt: string;
}
export interface PlanCreate {
  assignmentId: string;
  scheduledStartAt: string;
  estimatedMinutes?: number;
  notes?: string;
}
export interface PlanPatch {
  scheduledStartAt?: string;
  estimatedMinutes?: number;
  notes?: string;
  status?: "planned" | "handled";
}
export interface Snapshot {
  progressPercent: number;
  pendingTasks: number;
  overdueTasks: number;
}
export interface Attention extends Snapshot {
  courseId: string;
  courseName: string;
  studentId: string;
  studentName: string;
  priorityScore: number;
  priority: Priority;
  reasons: string[];
}
export type InterventionStatus = "open" | "following_up" | "resolved";
export interface Followup extends Snapshot {
  id: string;
  note: string;
  createdAt: string;
  outcomeStatus: "following_up" | "resolved";
}
export interface Intervention {
  id: string;
  courseId: string;
  studentId: string;
  studentName: string;
  courseName: string;
  title: string;
  note: string;
  actionType: "contacted" | "monitoring";
  status: InterventionStatus;
  followUpAt: string | null;
  createdAt: string;
  updatedAt: string;
  reasons: string[];
  baseline: Snapshot;
  current: Snapshot;
  followups: Followup[];
}
export interface InterventionCreate {
  courseId: string;
  studentId: string;
  title: string;
  note: string;
  actionType: "contacted" | "monitoring";
  followUpAt: string | null;
}
export interface InterventionPatch {
  title?: string;
  note?: string;
  actionType?: "contacted" | "monitoring";
  status?: InterventionStatus;
  followUpAt?: string | null;
}
export interface FollowupCreate {
  note: string;
  outcomeStatus: "following_up" | "resolved";
  nextFollowUpAt?: string | null;
}
export interface InnovationStore {
  plans(code: string): Promise<PlanItem[]>;
  createPlan(
    code: string,
    recommendation: Recommendation,
    input: PlanCreate,
  ): Promise<PlanItem | null>;
  updatePlan(
    code: string,
    id: string,
    patch: PlanPatch,
  ): Promise<PlanItem | null>;
  deletePlan(code: string, id: string): Promise<boolean>;
  interventions(code: string): Promise<Intervention[]>;
  createIntervention(
    code: string,
    attention: Attention,
    input: InterventionCreate,
  ): Promise<Intervention | null>;
  updateIntervention(
    code: string,
    id: string,
    patch: InterventionPatch,
  ): Promise<Intervention | null>;
  addFollowup(
    code: string,
    id: string,
    snapshot: Snapshot,
    input: FollowupCreate,
  ): Promise<Intervention | null>;
}
const outstanding = new Set([
  "missing",
  "not_submitted",
  "draft",
  "returned_for_resubmission",
]);
const priority = (score: number): Priority =>
  score >= rules.highThreshold
    ? "high"
    : score >= rules.mediumThreshold
      ? "medium"
      : "low";
const key = (course: string, assignment: string) =>
  JSON.stringify([course, assignment]);
export function rankRecommendations(
  assignments: Assignment[],
  statuses: AssignmentStatus[],
  progress: Progress[],
  plans: PlanItem[],
  now: Date,
): Recommendation[] {
  // Duplicated read-model rows are never resolved by last-write/order wins: a
  // conflicting status suppresses the recommendation instead of inventing one.
  const statusByKey = new Map<string, AssignmentStatus>();
  const conflicting = new Set<string>();
  for (const status of statuses) {
    const identity = key(status.courseCode, status.assignmentCode);
    const prior = statusByKey.get(identity);
    if (prior && prior.submissionStatus !== status.submissionStatus)
      conflicting.add(identity);
    else statusByKey.set(identity, status);
  }
  const seen = new Set<string>();
  const assignmentById = new Map<string, Assignment>();
  const conflictingAssignments = new Set<string>();
  for (const assignment of assignments) {
    const previous = assignmentById.get(assignment.assignmentId);
    if (
      previous &&
      (previous.courseId !== assignment.courseId ||
        previous.assignmentCode !== assignment.assignmentCode ||
        previous.dueAt !== assignment.dueAt ||
        previous.assignmentName !== assignment.assignmentName)
    )
      conflictingAssignments.add(assignment.assignmentId);
    else assignmentById.set(assignment.assignmentId, assignment);
  }
  return assignments
    .flatMap((a) => {
      if (
        seen.has(a.assignmentId) ||
        conflictingAssignments.has(a.assignmentId)
      )
        return [];
      seen.add(a.assignmentId);
      const identity = key(a.courseCode, a.assignmentCode);
      const status = statusByKey.get(identity);
      // No inferred status: unknown/missing source row is not a recommendation.
      if (
        !status ||
        conflicting.has(identity) ||
        !outstanding.has(status.submissionStatus) ||
        plans.some(
          (p) => p.assignmentId === a.assignmentId && p.status === "handled",
        )
      )
        return [];
      if (typeof a.dueAt !== "string") return [];
      const due = Date.parse(a.dueAt);
      const hours = (due - now.getTime()) / 3600000;
      // Moodle's zero deadline is unknown, not an overdue task. Defensively
      // reject historical epoch sentinels from older source implementations too.
      if (!Number.isFinite(hours) || due <= 0) return [];
      let score: number =
        hours < 0
          ? rules.deadline.overdue
          : hours <= rules.deadlineHours.day
            ? rules.deadline.within24Hours
            : hours <= rules.deadlineHours.threeDays
              ? rules.deadline.within72Hours
              : hours <= rules.deadlineHours.week
                ? rules.deadline.within168Hours
                : rules.deadline.later;
      const reasons = [
        hours < 0
          ? "Đã qua hạn và chưa hoàn tất trên LMS"
          : hours <= rules.deadlineHours.day
            ? "Đến hạn trong 24 giờ"
            : hours <= rules.deadlineHours.threeDays
              ? "Đến hạn trong 3 ngày"
              : hours <= rules.deadlineHours.week
                ? "Đến hạn trong 7 ngày"
                : "Bài tập còn cần thực hiện",
      ];
      if (status.submissionStatus === "returned_for_resubmission") {
        score += rules.returnedWeight;
        reasons.push("Giảng viên yêu cầu nộp lại trên LMS");
      }
      if (status.submissionStatus === "draft") {
        score += rules.draftWeight;
        reasons.push("Bài nộp trên LMS còn ở trạng thái nháp");
      }
      const progressRows = progress.filter((p) => p.courseId === a.courseId);
      const courseProgress =
        progressRows.length === 1 ? progressRows[0] : undefined;
      if (
        courseProgress &&
        Number.isInteger(courseProgress.totalActivities) &&
        courseProgress.totalActivities > 0 &&
        Number.isFinite(courseProgress.progressPercent) &&
        courseProgress.progressPercent >= 0 &&
        courseProgress.progressPercent < rules.lowProgressThreshold
      ) {
        score += rules.studentLowProgressWeight;
        reasons.push(
          `Tiến độ hoạt động của học phần dưới ${rules.lowProgressThreshold}%`,
        );
      }
      score = Math.min(score, rules.maxScore);
      return [
        {
          sourceType: "assignment" as const,
          assignmentId: a.assignmentId,
          assignmentCode: a.assignmentCode,
          assignmentName: a.assignmentName,
          courseId: a.courseId,
          courseCode: a.courseCode,
          courseName: a.courseName,
          dueAt: a.dueAt,
          submissionStatus: status.submissionStatus,
          priorityScore: score,
          priority: priority(score),
          reasons,
          recommendedDurationMinutes: rules.recommendedMinutes,
          planned: plans.some(
            (p) => p.assignmentId === a.assignmentId && p.status === "planned",
          ),
        },
      ];
    })
    .sort(
      (a, b) =>
        b.priorityScore - a.priorityScore ||
        Date.parse(a.dueAt) - Date.parse(b.dueAt) ||
        a.assignmentId.localeCompare(b.assignmentId),
    );
}
export function rankAttention(
  rows: (StudentMonitoring & { courseName: string })[],
): Attention[] {
  const seen = new Set<string>();
  return rows
    .map((row) => {
      // Unknown source metrics must not become an invented zero or risk signal.
      // The public snapshot contract is numeric; fail closed if the source breaks it.
      if (
        !Number.isFinite(row.progressPercent) ||
        row.progressPercent < 0 ||
        row.progressPercent > 100 ||
        !Number.isInteger(row.pendingTasks) ||
        row.pendingTasks < 0 ||
        !Number.isInteger(row.overdueTasks) ||
        row.overdueTasks < 0 ||
        (row.totalActivities !== undefined &&
          (!Number.isInteger(row.totalActivities) ||
            row.totalActivities < 0)) ||
        seen.has(key(row.courseId, row.studentId))
      )
        throw new ApiFailure(
          503,
          "SUPPORT_UNAVAILABLE",
          "Dữ liệu hỗ trợ tạm thời chưa sẵn sàng. Vui lòng thử lại.",
        );
      seen.add(key(row.courseId, row.studentId));
      const reasons: string[] = [];
      let score = 0;
      if (row.overdueTasks > 0) {
        score += Math.min(
          rules.teacherOverdueCap,
          row.overdueTasks * rules.teacherOverdueWeight,
        );
        reasons.push(`${row.overdueTasks} bài tập quá hạn chưa hoàn tất`);
      }
      if (row.pendingTasks > 0) {
        score += Math.min(
          rules.teacherPendingCap,
          row.pendingTasks * rules.teacherPendingWeight,
        );
        reasons.push(`${row.pendingTasks} bài tập đang chờ thực hiện`);
      }
      if (
        row.progressPercent < rules.lowProgressThreshold &&
        (row.totalActivities === undefined ||
          (Number.isInteger(row.totalActivities) && row.totalActivities > 0))
      ) {
        score += rules.teacherLowProgressWeight;
        reasons.push(`Tiến độ hoạt động dưới ${rules.lowProgressThreshold}%`);
      }
      if (!reasons.length)
        reasons.push("Chưa có dấu hiệu cần ưu tiên từ dữ liệu hiện có");
      return {
        courseId: row.courseId,
        courseName: row.courseName,
        studentId: row.studentId,
        studentName: row.studentName,
        progressPercent: row.progressPercent,
        pendingTasks: row.pendingTasks,
        overdueTasks: row.overdueTasks,
        priorityScore: score,
        priority: priority(score),
        reasons,
      };
    })
    .sort(
      (a, b) =>
        b.priorityScore - a.priorityScore ||
        a.courseId.localeCompare(b.courseId) ||
        a.studentId.localeCompare(b.studentId),
    );
}
export const snapshotOf = (a: Snapshot): Snapshot => ({
  progressPercent: a.progressPercent,
  pendingTasks: a.pendingTasks,
  overdueTasks: a.overdueTasks,
});
const missing = () =>
  new ApiFailure(
    404,
    "SUPPORT_ITEM_NOT_FOUND",
    "Không tìm thấy nội dung được phép truy cập.",
  );
const sameInstant = (a: string | null, b: string | null) =>
  (a === null && b === null) ||
  (typeof a === "string" &&
    typeof b === "string" &&
    Number.isFinite(Date.parse(a)) &&
    Date.parse(a) === Date.parse(b));
export class InnovationService {
  readonly student: StudentLearningDataSource;
  readonly teacher: TeacherSupportDataSource;
  readonly store: InnovationStore;
  readonly clock: () => Date;
  constructor(
    student: StudentLearningDataSource,
    teacher: TeacherSupportDataSource,
    store: InnovationStore,
    clock: () => Date = () => new Date(),
  ) {
    this.student = student;
    this.teacher = teacher;
    this.store = store;
    this.clock = clock;
  }
  async safe<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      if (error instanceof ApiFailure) throw error;
      // Driver detail and submitted note are never copied into a failure or log.
      throw new ApiFailure(
        503,
        "SUPPORT_UNAVAILABLE",
        "Dữ liệu hỗ trợ tạm thời chưa sẵn sàng. Vui lòng thử lại.",
      );
    }
  }
  async recommendations(code: string) {
    const [assignments, statuses, progress, plans] = await Promise.all([
      this.student.assignments(code),
      this.student.assignmentStatus(code),
      this.student.progress(code),
      this.store.plans(code),
    ]);
    return rankRecommendations(
      assignments,
      statuses,
      progress,
      plans,
      this.clock(),
    );
  }
  async plans(code: string) {
    const [items, assignments] = await Promise.all([
      this.store.plans(code),
      this.student.assignments(code),
    ]);
    const allowed = new Set(assignments.map((a) => a.assignmentId));
    return items.filter((item) => allowed.has(item.assignmentId));
  }
  async createPlan(code: string, input: PlanCreate) {
    if (!(Date.parse(input.scheduledStartAt) > this.clock().getTime()))
      throw new ApiFailure(
        400,
        "PLAN_TIME_INVALID",
        "Vui lòng chọn thời gian học trong tương lai.",
      );
    const recommendation = (await this.recommendations(code)).find(
      (r) => r.assignmentId === input.assignmentId,
    );
    if (!recommendation) throw missing();
    if (recommendation.planned)
      throw new ApiFailure(
        409,
        "PLAN_ALREADY_EXISTS",
        "Bài tập đã có trong kế hoạch của bạn.",
      );
    const created = await this.store.createPlan(code, recommendation, input);
    if (!created)
      throw new ApiFailure(
        409,
        "PLAN_ALREADY_EXISTS",
        "Bài tập đã có trong kế hoạch hoặc không còn khả dụng.",
      );
    return created;
  }
  async updatePlan(code: string, id: string, patch: PlanPatch) {
    const existing = (await this.plans(code)).find((p) => p.id === id);
    if (!existing) throw missing();
    if (
      existing.status === "handled" &&
      (patch.status === "planned" ||
        patch.scheduledStartAt !== undefined ||
        patch.estimatedMinutes !== undefined)
    )
      throw new ApiFailure(
        409,
        "PLAN_ALREADY_HANDLED",
        "Buổi học đã được xử lý. Hãy tạo kế hoạch mới nếu cần.",
      );
    if (
      patch.scheduledStartAt !== undefined &&
      !(Date.parse(patch.scheduledStartAt) > this.clock().getTime())
    )
      throw new ApiFailure(
        400,
        "PLAN_TIME_INVALID",
        "Vui lòng chọn thời gian học trong tương lai.",
      );
    const result = await this.store.updatePlan(code, id, patch);
    if (!result) throw missing();
    return result;
  }
  async deletePlan(code: string, id: string) {
    if (
      !(await this.plans(code)).some((p) => p.id === id) ||
      !(await this.store.deletePlan(code, id))
    )
      throw missing();
    return { deleted: true as const };
  }
  async attention(code: string) {
    if (this.teacher.attention)
      return rankAttention(await this.teacher.attention(code));
    const courses = await this.teacher.courses(code);
    return rankAttention(
      (
        await Promise.all(
          courses.map(async (c) =>
            ((await this.teacher.students(code, c.id)) ?? []).map((s) => ({
              ...s,
              courseName: c.name,
            })),
          ),
        )
      ).flat(),
    );
  }
  async interventions(code: string) {
    const [items, attention] = await Promise.all([
      this.store.interventions(code),
      this.attention(code),
    ]);
    return items.flatMap((i) => {
      const current = attention.find(
        (a) => a.courseId === i.courseId && a.studentId === i.studentId,
      );
      return current ? [{ ...i, current: snapshotOf(current) }] : [];
    });
  }
  async intervention(code: string, id: string) {
    const result = (await this.interventions(code)).find(
      (item) => item.id === id,
    );
    if (!result) throw missing();
    return result;
  }
  async dueFollowups(code: string) {
    const now = this.clock().getTime();
    return (await this.interventions(code))
      .filter(
        (item) =>
          item.status !== "resolved" &&
          item.followUpAt !== null &&
          Date.parse(item.followUpAt) <= now,
      )
      .sort(
        (a, b) =>
          Date.parse(a.followUpAt!) - Date.parse(b.followUpAt!) ||
          a.id.localeCompare(b.id),
      );
  }
  async createIntervention(code: string, input: InterventionCreate) {
    this.validateFollowupTime(input.followUpAt);
    const attention = (await this.attention(code)).find(
      (a) => a.courseId === input.courseId && a.studentId === input.studentId,
    );
    if (!attention) throw missing();
    const existing = await this.interventions(code);
    if (
      existing.length >= 200 ||
      existing.some(
        (i) =>
          i.courseId === input.courseId &&
          i.studentId === input.studentId &&
          i.status !== "resolved",
      )
    )
      throw new ApiFailure(
        409,
        "INTERVENTION_ALREADY_OPEN",
        "Hãy tiếp tục hồ sơ theo dõi hiện có trước khi tạo hồ sơ mới.",
      );
    const result = await this.store.createIntervention(code, attention, input);
    if (!result)
      throw new ApiFailure(
        409,
        "INTERVENTION_NOT_CREATED",
        "Không thể tạo hồ sơ trùng hoặc vượt giới hạn lưu trữ.",
      );
    return result;
  }
  async updateIntervention(code: string, id: string, patch: InterventionPatch) {
    const existing = (await this.interventions(code)).find((i) => i.id === id);
    if (!existing) throw missing();
    if (existing.status === "resolved")
      throw new ApiFailure(
        409,
        "INTERVENTION_CLOSED",
        "Hồ sơ đã khép lại. Hãy tạo lượt hỗ trợ mới nếu cần.",
      );
    if (existing.status === "following_up" && patch.status === "open")
      throw new ApiFailure(
        409,
        "INTERVENTION_TRANSITION_INVALID",
        "Hồ sơ đang theo dõi không thể trở lại trạng thái mới.",
      );
    if (
      patch.status !== "resolved" &&
      patch.followUpAt !== undefined &&
      !sameInstant(patch.followUpAt, existing.followUpAt)
    )
      this.validateFollowupTime(patch.followUpAt);
    const result = await this.store.updateIntervention(code, id, patch);
    if (!result) throw missing();
    return { ...result, current: existing.current };
  }
  async followup(code: string, id: string, input: FollowupCreate) {
    const existing = (await this.interventions(code)).find((i) => i.id === id);
    if (!existing) throw missing();
    if (existing.status === "resolved" || existing.followups.length >= 100)
      throw new ApiFailure(
        409,
        "FOLLOWUP_CLOSED",
        "Hồ sơ đã kết thúc hoặc đã đủ số lần theo dõi.",
      );
    if (
      input.outcomeStatus !== "resolved" &&
      input.nextFollowUpAt !== undefined &&
      !sameInstant(input.nextFollowUpAt, existing.followUpAt)
    )
      this.validateFollowupTime(input.nextFollowUpAt);
    const result = await this.store.addFollowup(
      code,
      id,
      existing.current,
      input,
    );
    if (!result) throw missing();
    return { ...result, current: existing.current };
  }
  private validateFollowupTime(value: string | null) {
    if (value !== null && !(Date.parse(value) >= this.clock().getTime()))
      throw new ApiFailure(
        400,
        "FOLLOWUP_TIME_INVALID",
        "Vui lòng chọn thời gian theo dõi từ hiện tại trở đi.",
      );
  }
}
