const string = { type: "string" };
const number = { type: "number" };
const integer = { type: "integer", minimum: 0 };
const date = { type: "string", format: "date-time" };
const nullable = (schema: object) => ({ ...schema, nullable: true });
export const object = (properties: Record<string, object>) => ({
  type: "object",
  additionalProperties: false,
  properties,
  required: Object.keys(properties),
});
const deepLink = {
  deepLink: { type: "string", nullable: true, enum: [null] },
  deepLinkStatus: {
    type: "string",
    enum: ["TO_VERIFY_DLU"],
    example: "TO_VERIFY_DLU",
  },
};
const courseRef = { courseCode: string, courseName: string };
const assignmentRef = {
  ...courseRef,
  assignmentCode: string,
  assignmentName: string,
};
export const status = {
  type: "string",
  enum: [
    "graded",
    "returned_for_resubmission",
    "draft",
    "late",
    "submitted",
    "missing",
    "not_submitted",
  ],
};
export const studentSchema = object({
  studentCode: { type: "string", example: "SV001" },
  fullName: string,
  email: { type: "string", format: "email" },
  department: string,
  role: { type: "string", enum: ["student"] },
});
export const courseSchema = object({
  courseId: { type: "string", example: "1" },
  ...courseRef,
  categoryName: string,
  summary: string,
  startsAt: date,
  endsAt: nullable(date),
  teacherNames: nullable(string),
});
export const contentSchema = object({
  courseCode: string,
  sectionNumber: integer,
  sectionName: string,
  courseModuleId: string,
  position: integer,
  activityType: string,
  activityName: string,
  description: string,
  assignmentCode: nullable(string),
  dueAt: nullable(date),
  filenames: nullable(string),
  totalSizeBytes: nullable(number),
  ...deepLink,
});
export const resourceSchema = object({
  courseId: string,
  ...courseRef,
  sectionName: string,
  resourceId: string,
  resourceName: string,
  description: string,
  filename: nullable(string),
  fileSizeBytes: nullable(number),
  mimeType: nullable(string),
  ...deepLink,
});
export const assignmentSchema = object({
  courseId: string,
  ...assignmentRef,
  assignmentId: string,
  description: string,
  opensAt: date,
  dueAt: date,
  maxGrade: number,
  ...deepLink,
});
export const assignmentStatusSchema = object({
  ...assignmentRef,
  submissionStatus: status,
  submittedAt: nullable(date),
  isLate: { type: "boolean" },
  attemptNumber: nullable(integer),
  ...deepLink,
});
export const gradeSchema = object({
  ...courseRef,
  assignmentCode: string,
  gradeItem: string,
  score: number,
  maxGrade: number,
  percentage: nullable(number),
  gradeResult: string,
  feedback: nullable(string),
  gradedAt: date,
  teacherName: string,
});
export const progressSchema = object({
  courseId: string,
  ...courseRef,
  totalActivities: integer,
  completedActivities: integer,
  progressPercent: number,
});
export const deadlineSchema = object({
  ...assignmentRef,
  dueAt: date,
  submissionStatus: status,
  daysRemaining: integer,
  ...deepLink,
});
export const overviewSchema = object({
  student: studentSchema,
  courseCount: integer,
  upcomingDeadlineCount: integer,
  assignmentSummary: object({
    total: integer,
    submitted: integer,
    graded: integer,
    outstanding: integer,
    late: integer,
  }),
  progressSummary: { type: "array", items: progressSchema },
  gradeSummary: object({ gradedItemCount: integer }),
  nextDeadline: nullable(deadlineSchema),
});
export const errorSchema = object({
  error: object({ code: string, message: string }),
});
export const single = (schema: object) => object({ data: schema });
export const list = (schema: object) =>
  object({
    data: { type: "array", items: schema },
    meta: object({ count: integer }),
  });
export const healthSchema = object({
  status: { type: "string", enum: ["ok"] },
  environment: { type: "string", enum: ["development", "staging"] },
  database: { type: "string", enum: ["reachable"] },
  dataSource: { type: "string", enum: ["neon-development-model"] },
});
export const identityHeaders = {
  type: "object",
  properties: {
    "x-demo-student-code": {
      type: "string",
      pattern: "^SV[0-9]{3}$",
      example: "SV001",
      description:
        "Synthetic student identity. Development/staging only; NOT production authentication.",
    },
  },
  required: ["x-demo-student-code"],
};
export const noQuery = {
  type: "object",
  properties: {},
  additionalProperties: false,
};
export const errorResponses = {
  400: errorSchema,
  401: errorSchema,
  403: errorSchema,
  404: errorSchema,
  500: errorSchema,
  503: errorSchema,
};
