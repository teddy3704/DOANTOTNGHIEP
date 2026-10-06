import type { FastifyInstance } from "fastify";
import type {
  InnovationService,
  PlanCreate,
  PlanPatch,
  InterventionCreate,
  InterventionPatch,
  FollowupCreate,
} from "../domain/innovation.ts";
import {
  object,
  list,
  single,
  errorResponses as standardErrors,
  status,
} from "./schemas.ts";
import { ApiFailure } from "../domain/learning-service.ts";

const text = { type: "string" };
const errorResponses = {
  ...standardErrors,
  409: standardErrors[400],
  413: standardErrors[400],
  429: standardErrors[400],
};
const date = { type: "string", format: "date-time" };
const nullableDate = { ...date, nullable: true };
const sourceId = { type: "string", pattern: "^[1-9][0-9]{0,14}$" };
const uuid = { type: "string", format: "uuid" };
const priority = { type: "string", enum: ["high", "medium", "low"] };
const reasons = { type: "array", items: text };
const score = { type: "integer", minimum: 0, maximum: 100 };
const note = { type: "string", maxLength: 500 };
const requiredNote = { ...note, minLength: 1, pattern: "\\S" };
const title = { type: "string", minLength: 1, maxLength: 120, pattern: "\\S" };
const action = { type: "string", enum: ["contacted", "monitoring"] };
const interventionStatus = {
  type: "string",
  enum: ["open", "following_up", "resolved"],
};
const outcome = { type: "string", enum: ["following_up", "resolved"] };
const minutes = { type: "integer", minimum: 5, maximum: 480 };
const snapshot = {
  progressPercent: { type: "number", minimum: 0, maximum: 100 },
  pendingTasks: { type: "integer", minimum: 0 },
  overdueTasks: { type: "integer", minimum: 0 },
};
const recommendation = object({
  sourceType: { type: "string", enum: ["assignment"] },
  assignmentId: sourceId,
  assignmentCode: text,
  assignmentName: text,
  courseId: sourceId,
  courseCode: text,
  courseName: text,
  dueAt: date,
  submissionStatus: status,
  priorityScore: score,
  priority,
  reasons,
  recommendedDurationMinutes: minutes,
  planned: { type: "boolean" },
});
const plan = object({
  id: uuid,
  assignmentId: sourceId,
  assignmentCode: text,
  courseId: sourceId,
  courseName: text,
  title: text,
  dueAt: date,
  priorityScore: score,
  priority,
  reasons,
  scheduledStartAt: date,
  estimatedMinutes: minutes,
  notes: note,
  status: { type: "string", enum: ["planned", "handled"] },
  createdAt: date,
  updatedAt: date,
});
const attention = object({
  courseId: sourceId,
  courseName: text,
  studentId: sourceId,
  studentName: text,
  ...snapshot,
  priorityScore: score,
  priority,
  reasons,
});
const intervention = object({
  id: uuid,
  courseId: sourceId,
  studentId: sourceId,
  studentName: text,
  courseName: text,
  title,
  note: requiredNote,
  actionType: action,
  status: interventionStatus,
  followUpAt: nullableDate,
  createdAt: date,
  updatedAt: date,
  reasons,
  baseline: object(snapshot),
  current: object(snapshot),
  followups: {
    type: "array",
    items: object({
      id: uuid,
      note: requiredNote,
      createdAt: date,
      outcomeStatus: outcome,
      ...snapshot,
    }),
  },
});
const idParams = object({ id: uuid });
const partial = (
  properties: Record<string, object>,
  required: string[] = [],
) => ({
  ...object(properties),
  required,
  minProperties: 1,
});
// Synthetic identities are not production authentication. Keep public staging
// writes bounded: fixed allowlisted actor keys, 30 workflow writes/minute/role.
function mutationLimit() {
  const buckets = new Map<string, { minute: number; count: number }>();
  return async (req: {
    method: string;
    principal: { studentCode: string } | null;
    teacherPrincipal?: { teacherCode: string } | null;
  }) => {
    if (!["POST", "PATCH", "DELETE"].includes(req.method)) return;
    const code =
      req.principal?.studentCode ?? req.teacherPrincipal?.teacherCode;
    if (!code) return;
    const minute = Math.floor(Date.now() / 60000);
    const bucket = buckets.get(code);
    if (bucket?.minute === minute && bucket.count >= 30)
      throw new ApiFailure(
        429,
        "SUPPORT_RATE_LIMITED",
        "Bạn thao tác quá nhanh. Vui lòng thử lại sau một phút.",
      );
    buckets.set(code, {
      minute,
      count: bucket?.minute === minute ? bucket.count + 1 : 1,
    });
  };
}
// Common identity/no-query schemas are supplied by the enclosing authenticated
// plugin. Only app-owned workflow fields are accepted, never user IDs or LMS state.
export function registerStudentInnovationRoutes(
  api: FastifyInstance,
  service: InnovationService,
  common: object,
) {
  const limit = mutationLimit();
  api.get(
    "/me/recommendations",
    {
      schema: {
        ...common,
        operationId: "getStudyRecommendations",
        summary:
          "Explainable assignment priorities from current scoped source data",
        response: { 200: list(recommendation), ...errorResponses },
      },
    },
    async (req) => {
      const data = await service.safe(() =>
        service.recommendations(req.principal!.studentCode),
      );
      return { data, meta: { count: data.length } };
    },
  );
  api.get(
    "/me/study-plan",
    {
      schema: {
        ...common,
        operationId: "getStudyPlan",
        summary:
          "Own study sessions; handled is not an official LMS completion",
        response: { 200: list(plan), ...errorResponses },
      },
    },
    async (req) => {
      const data = await service.safe(() =>
        service.plans(req.principal!.studentCode),
      );
      return { data, meta: { count: data.length } };
    },
  );
  api.post<{ Body: PlanCreate }>(
    "/me/study-plan/items",
    {
      preHandler: limit,
      bodyLimit: 8192,
      schema: {
        ...common,
        operationId: "createStudyPlanItem",
        summary:
          "Schedule an accessible recommendation; source snapshots are server-owned",
        body: partial(
          {
            assignmentId: sourceId,
            scheduledStartAt: date,
            estimatedMinutes: minutes,
            notes: note,
          },
          ["assignmentId", "scheduledStartAt"],
        ),
        response: {
          201: single(plan),
          ...errorResponses,
          409: errorResponses[400],
        },
      },
    },
    async (req, reply) => {
      const data = await service.safe(() =>
        service.createPlan(req.principal!.studentCode, req.body),
      );
      return reply.code(201).send({ data });
    },
  );
  api.patch<{ Params: { id: string }; Body: PlanPatch }>(
    "/me/study-plan/items/:id",
    {
      preHandler: limit,
      bodyLimit: 8192,
      schema: {
        ...common,
        operationId: "updateStudyPlanItem",
        summary:
          "Reschedule or mark an own plan item handled without changing LMS",
        params: idParams,
        body: partial({
          scheduledStartAt: date,
          estimatedMinutes: minutes,
          notes: note,
          status: { type: "string", enum: ["planned", "handled"] },
        }),
        response: { 200: single(plan), ...errorResponses },
      },
    },
    async (req) => ({
      data: await service.safe(() =>
        service.updatePlan(req.principal!.studentCode, req.params.id, req.body),
      ),
    }),
  );
  api.delete<{ Params: { id: string } }>(
    "/me/study-plan/items/:id",
    {
      preHandler: limit,
      schema: {
        ...common,
        operationId: "deleteStudyPlanItem",
        summary: "Remove an own personal plan item only",
        params: idParams,
        response: {
          200: single(object({ deleted: { type: "boolean" } })),
          ...errorResponses,
        },
      },
    },
    async (req) => ({
      data: await service.safe(() =>
        service.deletePlan(req.principal!.studentCode, req.params.id),
      ),
    }),
  );
}

export function registerTeacherInnovationRoutes(
  api: FastifyInstance,
  service: InnovationService,
  common: object,
) {
  const limit = mutationLimit();
  for (const [path, operationId, summary, read, schema] of [
    [
      "attention",
      "getTeacherAttention",
      "Explainable support priorities for assigned courses",
      service.attention.bind(service),
      attention,
    ],
    [
      "interventions",
      "getTeacherInterventions",
      "Own scoped interventions with actual baseline/current snapshots and history",
      service.interventions.bind(service),
      intervention,
    ],
    [
      "followups",
      "getTeacherDueFollowups",
      "Own unresolved follow-ups due now",
      service.dueFollowups.bind(service),
      intervention,
    ],
  ] as const) {
    api.get(
      `/me/teacher/${path}`,
      {
        schema: {
          ...common,
          operationId,
          summary,
          response: { 200: list(schema), ...errorResponses },
        },
      },
      async (req) => {
        const data = await service.safe<readonly unknown[]>(() =>
          read(req.teacherPrincipal!.teacherCode),
        );
        return { data, meta: { count: data.length } };
      },
    );
  }
  api.get<{ Params: { id: string } }>(
    "/me/teacher/interventions/:id",
    {
      schema: {
        ...common,
        operationId: "getTeacherIntervention",
        summary: "Scoped intervention detail and append-only follow-up history",
        params: idParams,
        response: { 200: single(intervention), ...errorResponses },
      },
    },
    async (req) => ({
      data: await service.safe(() =>
        service.intervention(req.teacherPrincipal!.teacherCode, req.params.id),
      ),
    }),
  );
  api.post<{ Body: InterventionCreate }>(
    "/me/teacher/interventions",
    {
      preHandler: limit,
      bodyLimit: 8192,
      schema: {
        ...common,
        operationId: "createTeacherIntervention",
        summary: "Record app-owned support action, not an LMS message or grade",
        body: object({
          courseId: sourceId,
          studentId: sourceId,
          title,
          note: requiredNote,
          actionType: action,
          followUpAt: nullableDate,
        }),
        response: { 201: single(intervention), ...errorResponses },
      },
    },
    async (req, reply) => {
      const data = await service.safe(() =>
        service.createIntervention(req.teacherPrincipal!.teacherCode, req.body),
      );
      return reply.code(201).send({ data });
    },
  );
  api.patch<{ Params: { id: string }; Body: InterventionPatch }>(
    "/me/teacher/interventions/:id",
    {
      preHandler: limit,
      bodyLimit: 8192,
      schema: {
        ...common,
        operationId: "updateTeacherIntervention",
        summary: "Update an own support record or next follow-up time",
        params: idParams,
        body: partial({
          title,
          note: requiredNote,
          actionType: action,
          status: interventionStatus,
          followUpAt: nullableDate,
        }),
        response: { 200: single(intervention), ...errorResponses },
      },
    },
    async (req) => ({
      data: await service.safe(() =>
        service.updateIntervention(
          req.teacherPrincipal!.teacherCode,
          req.params.id,
          req.body,
        ),
      ),
    }),
  );
  api.post<{ Params: { id: string }; Body: FollowupCreate }>(
    "/me/teacher/interventions/:id/followups",
    {
      preHandler: limit,
      bodyLimit: 8192,
      schema: {
        ...common,
        operationId: "createTeacherFollowup",
        summary:
          "Record follow-up outcome and fresh source snapshot atomically",
        params: idParams,
        body: partial(
          {
            note: requiredNote,
            outcomeStatus: outcome,
            nextFollowUpAt: nullableDate,
          },
          ["note", "outcomeStatus"],
        ),
        response: { 201: single(intervention), ...errorResponses },
      },
    },
    async (req, reply) => {
      const data = await service.safe(() =>
        service.followup(
          req.teacherPrincipal!.teacherCode,
          req.params.id,
          req.body,
        ),
      );
      return reply.code(201).send({ data });
    },
  );
}
