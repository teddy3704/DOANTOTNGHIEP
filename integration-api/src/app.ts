import Fastify, { LogController } from "fastify";
import type { FastifyServerOptions } from "fastify";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import type { AppConfig } from "./config.ts";
import type {
  Student,
  StudentLearningDataSource,
} from "./domain/student-learning.ts";
import { ApiFailure, LearningService } from "./domain/learning-service.ts";
import * as s from "./http/schemas.ts";
import type { TeacherSupportDataSource } from "./domain/teacher-support.ts";
import { registerTeacherRoutes } from "./http/teacher-routes.ts";
import {
  InnovationService,
  type InnovationStore,
} from "./domain/innovation.ts";
import { registerStudentInnovationRoutes } from "./http/innovation-routes.ts";
import { safeLoggerOptions } from "./logging.ts";

declare module "fastify" {
  interface FastifyRequest {
    principal: Student | null;
    diagnosticFailureCode: string | null;
  }
}

// Central onResponse logs provide status-only diagnostics. Framework exception
// serializers must never serialize a driver error, request URL or headers.
class SafeLogController extends LogController {
  constructor() {
    super({ disableRequestLogging: true });
  }
  override defaultErrorLog() {}
  override streamError() {}
  override routeNotFound() {}
  override writeHeadError() {}
  override serializerError() {}
}

export async function buildApp(
  config: AppConfig,
  source: StudentLearningDataSource,
  logger: FastifyServerOptions["logger"] = true,
  teacherSource?: TeacherSupportDataSource,
  innovationStore?: InnovationStore,
) {
  const app = Fastify({
    logger: safeLoggerOptions(logger),
    logController: new SafeLogController(),
    requestIdHeader: false,
    exposeHeadRoutes: false,
    bodyLimit: 1024,
    requestTimeout: 15000,
    connectionTimeout: 20000,
    ajv: {
      customOptions: { removeAdditional: false, coerceTypes: false },
      plugins: [(ajv) => ajv.addKeyword({ keyword: "example", valid: true })],
    },
  });
  const service = new LearningService(source);
  const innovation =
    teacherSource && innovationStore
      ? new InnovationService(source, teacherSource, innovationStore)
      : undefined;
  app.decorateRequest("principal", null);
  app.decorateRequest("diagnosticFailureCode", null);
  app.setErrorHandler((error, request, reply) => {
    if (error instanceof ApiFailure) {
      request.diagnosticFailureCode = error.code;
      return reply
        .code(error.statusCode)
        .send({ error: { code: error.code, message: error.message } });
    }
    if (
      typeof error === "object" &&
      error !== null &&
      "statusCode" in error &&
      error.statusCode === 415
    ) {
      request.diagnosticFailureCode = "UNSUPPORTED_MEDIA_TYPE";
      return reply.code(415).send({
        error: {
          code: "UNSUPPORTED_MEDIA_TYPE",
          message: "Định dạng nội dung yêu cầu không được hỗ trợ.",
        },
      });
    }
    if (
      typeof error === "object" &&
      error !== null &&
      "statusCode" in error &&
      error.statusCode === 413
    )
      return reply.code(413).send({
        error: {
          code: "REQUEST_TOO_LARGE",
          message: "Nội dung yêu cầu quá dài.",
        },
      });
    if (
      typeof error === "object" &&
      error !== null &&
      (("validation" in error && error.validation) ||
        ("statusCode" in error && error.statusCode === 400))
    )
      return reply.code(400).send({
        error: {
          code: "INVALID_REQUEST",
          message: "Tham số yêu cầu không hợp lệ.",
        },
      });
    request.diagnosticFailureCode = "INTERNAL_ERROR";
    return reply.code(500).send({
      error: {
        code: "INTERNAL_ERROR",
        message: "Không thể xử lý yêu cầu lúc này.",
      },
    });
  });
  app.setNotFoundHandler((_request, reply) =>
    reply.code(404).send({
      error: {
        code: "NOT_FOUND",
        message: "Không tìm thấy chức năng được yêu cầu.",
      },
    }),
  );
  app.addHook("onResponse", async (request, reply) => {
    // Never log raw URL, headers, records, error objects or environment.
    const log =
      reply.statusCode >= 500
        ? app.log.error.bind(app.log)
        : app.log.info.bind(app.log);
    log(
      {
        requestId: request.id,
        method: request.method,
        path: request.routeOptions.url ?? "[unmatched]",
        statusCode: reply.statusCode,
        durationMs: Math.round(reply.elapsedTime),
        ...(request.diagnosticFailureCode
          ? { failureCode: request.diagnosticFailureCode }
          : {}),
      },
      "request_completed",
    );
  });
  app.addHook("onSend", async (_request, reply, payload) => {
    reply.header("X-Content-Type-Options", "nosniff");
    reply.header("Cache-Control", "no-store");
    return payload;
  });
  await app.register(swagger, {
    openapi: {
      openapi: "3.0.3",
      info: {
        title: "DLU LMS Student Support — Development Integration API",
        version: "0.1.0",
        description:
          "This development/staging API uses the PostgreSQL Database-First development model. It is NOT the production API of DLU LMS. Synthetic student data only. No submissions, uploads or teacher grading. DLU production integration: TO_VERIFY_DLU.",
      },
      servers: [
        {
          url:
            config.environment === "staging"
              ? "/"
              : `http://localhost:${config.port}`,
          description:
            config.environment === "staging"
              ? "Same-origin staging; synthetic data only, not DLU production"
              : "Local development only",
        },
      ],
      components: {
        securitySchemes: {
          DemoTeacher: {
            type: "apiKey",
            in: "header",
            name: "X-Demo-Teacher-Code",
            description:
              "Synthetic staging identity only; not DLU authentication.",
          },
          DemoStudent: {
            type: "apiKey",
            in: "header",
            name: "X-Demo-Student-Code",
            description:
              "Development/staging identity only; NOT production authentication. Example: SV001.",
          },
        },
      },
    },
  });
  await app.register(swaggerUi, {
    routePrefix: "/docs",
    uiConfig: { docExpansion: "list", persistAuthorization: false },
    staticCSP: true,
  });
  app.get("/openapi.json", { schema: { hide: true } }, async () =>
    app.swagger(),
  );
  // Liveness is deliberately separate from readiness. Never use this probe to
  // claim the database or app workflow is ready; Render continues using /health.
  app.get(
    "/health/live",
    { schema: { hide: true, querystring: s.noQuery } },
    async () => ({ status: "ok" }),
  );
  app.get(
    "/health",
    {
      schema: {
        operationId: "getHealth",
        summary: "Development API health",
        description:
          "Readiness: checks actual PostgreSQL reachability and essential source/workflow relation-column surfaces using read-only queries. Exposes no database internals. /health/live is process liveness only.",
        tags: ["Health"],
        querystring: s.noQuery,
        response: { 200: s.healthSchema, ...s.errorResponses },
      },
    },
    async () => {
      await service.read(() => source.health());
      return {
        status: "ok",
        environment: config.environment,
        database: "reachable",
        dataSource: "neon-development-model",
      };
    },
  );
  await app.register(
    async (api) => {
      api.addHook("onRequest", async (request) => {
        if (request.headers["x-demo-teacher-code"] !== undefined)
          throw new ApiFailure(
            401,
            "DEVELOPMENT_IDENTITY_INVALID",
            "Hồ sơ không hợp lệ.",
          );
        request.principal = await service.identify(
          request.headers["x-demo-student-code"],
          config.demoAuthEnabled,
        );
      });
      const common = {
        headers: s.identityHeaders,
        querystring: s.noQuery,
        security: [{ DemoStudent: [] }],
        tags: ["Student support"],
      };
      if (innovation) registerStudentInnovationRoutes(api, innovation, common);
      api.get(
        "/me",
        {
          schema: {
            ...common,
            operationId: "getStudentProfile",
            summary: "Current synthetic student",
            description:
              "Returns only the resolved active synthetic student profile; no other identity parameter is accepted.",
            response: { 200: s.single(s.studentSchema), ...s.errorResponses },
          },
        },
        async (request) => ({ data: request.principal }),
      );
      const collections = [
        [
          "courses",
          "getCourses",
          "Courses",
          "Currently enrolled visible courses.",
          s.courseSchema,
          source.courses.bind(source),
        ],
        [
          "resources",
          "getResources",
          "Learning resources",
          "Visible resource metadata only. No binary files or unverified download URLs.",
          s.resourceSchema,
          source.resources.bind(source),
        ],
        [
          "assignments",
          "getAssignments",
          "Assignments",
          "Visible assignment catalogue and deadlines. Complete submission on the approved LMS, not this API.",
          s.assignmentSchema,
          source.assignments.bind(source),
        ],
        [
          "assignment-status",
          "getAssignmentStatus",
          "Assignment status",
          "Read-only status of the current student, restricted to visible assignments.",
          s.assignmentStatusSchema,
          source.assignmentStatus.bind(source),
        ],
        [
          "grades",
          "getGrades",
          "Grades and feedback",
          "Published grades belonging to the current student and visible assignments only.",
          s.gradeSchema,
          source.grades.bind(source),
        ],
        [
          "progress",
          "getProgress",
          "Learning progress",
          "Visible tracked activity completion, not a passing-grade calculation.",
          s.progressSchema,
          source.progress.bind(source),
        ],
        [
          "deadlines",
          "getDeadlines",
          "Upcoming deadlines",
          "Upcoming outstanding assignments at query time, ordered by due date.",
          s.deadlineSchema,
          source.deadlines.bind(source),
        ],
      ] as const;
      for (const [
        path,
        operationId,
        summary,
        description,
        schema,
        read,
      ] of collections) {
        api.get(
          `/me/${path}`,
          {
            schema: {
              ...common,
              operationId,
              summary,
              description,
              response: { 200: s.list(schema), ...s.errorResponses },
            },
          },
          async (request) => {
            const data = await service.read<readonly unknown[]>(() =>
              read(request.principal!.studentCode),
            );
            return { data, meta: { count: data.length } };
          },
        );
      }
      api.get<{ Params: { courseId: string } }>(
        "/me/courses/:courseId/content",
        {
          schema: {
            ...common,
            operationId: "getCourseContent",
            summary: "Course content",
            description:
              "Checks current enrollment before exposing visible content. Inaccessible and nonexistent courses both return 404.",
            params: s.object({
              courseId: {
                type: "string",
                pattern: "^[1-9][0-9]{0,14}$",
                example: "1",
              },
            }),
            response: { 200: s.list(s.contentSchema), ...s.errorResponses },
          },
        },
        async (request) => {
          const data = await service.content(
            request.principal!.studentCode,
            request.params.courseId,
          );
          return { data, meta: { count: data.length } };
        },
      );
      api.get(
        "/me/overview",
        {
          schema: {
            ...common,
            operationId: "getOverview",
            summary: "Student learning overview",
            description:
              "Aggregates the same scoped sources. No invented totals; upcoming data changes with time.",
            response: { 200: s.single(s.overviewSchema), ...s.errorResponses },
          },
        },
        async (request) => ({
          data: await service.overview(request.principal!),
        }),
      );
    },
    { prefix: "/api/v1" },
  );
  if (teacherSource)
    await registerTeacherRoutes(
      app,
      teacherSource,
      config.demoAuthEnabled,
      innovation,
    );
  return app;
}
