import type { FastifyInstance } from "fastify";
import type {
  TeacherProfile,
  TeacherSupportDataSource,
} from "../domain/teacher-support.ts";
import { ApiFailure } from "../domain/learning-service.ts";
import { object, list, single, errorResponses, noQuery } from "./schemas.ts";
import type { InnovationService } from "../domain/innovation.ts";
import { registerTeacherInnovationRoutes } from "./innovation-routes.ts";
declare module "fastify" {
  interface FastifyRequest {
    teacherPrincipal: TeacherProfile | null;
  }
}
const str = { type: "string" };
const count = { type: "integer", minimum: 0 };
const profile = object({
  teacherCode: str,
  fullName: str,
  email: { type: "string", format: "email" },
  department: str,
  role: { type: "string", enum: ["teacher"] },
});
const work = object({
  title: str,
  description: str,
  dueAt: { type: "string", format: "date-time", nullable: true },
  submitted: count,
  studentCount: count,
});
const course = object({
  id: str,
  name: str,
  code: str,
  summary: str,
  studentCount: count,
  work: { type: "array", items: work },
  sections: {
    type: "array",
    items: object({ title: str, resources: { type: "array", items: str } }),
  },
});
const monitoring = object({
  courseId: str,
  studentId: str,
  studentName: str,
  progressPercent: { type: "number", minimum: 0, maximum: 100 },
  pendingTasks: count,
  overdueTasks: count,
  riskLevel: { type: "string", enum: ["LOW", "MEDIUM", "HIGH"] },
});
export async function registerTeacherRoutes(
  app: FastifyInstance,
  source: TeacherSupportDataSource,
  enabled: boolean,
  innovation?: InnovationService,
) {
  const read = async <T>(fn: () => Promise<T>) => {
    try {
      return await fn();
    } catch (e) {
      if (e instanceof ApiFailure) throw e;
      throw new ApiFailure(
        503,
        "DATA_SOURCE_UNAVAILABLE",
        "Dữ liệu giảng dạy tạm thời chưa sẵn sàng.",
      );
    }
  };
  await app.register(
    async (api) => {
      api.decorateRequest("teacherPrincipal", null);
      api.addHook("onRequest", async (request) => {
        const code = request.headers["x-demo-teacher-code"];
        if (
          !enabled ||
          typeof code !== "string" ||
          !/^GV\d{3}$/.test(code) ||
          request.headers["x-demo-student-code"] !== undefined
        )
          throw new ApiFailure(
            401,
            "DEVELOPMENT_IDENTITY_REQUIRED",
            "Cần chọn hồ sơ giảng viên hợp lệ.",
          );
        request.teacherPrincipal = await read(() => source.teacher(code));
        if (!request.teacherPrincipal)
          throw new ApiFailure(
            401,
            "DEVELOPMENT_IDENTITY_INVALID",
            "Hồ sơ giảng viên không hợp lệ.",
          );
      });
      const common = {
        querystring: noQuery,
        tags: ["Teacher support"],
        security: [{ DemoTeacher: [] }],
        headers: {
          type: "object",
          required: ["x-demo-teacher-code"],
          properties: {
            "x-demo-teacher-code": { type: "string", pattern: "^GV[0-9]{3}$" },
          },
        },
      };
      if (innovation) registerTeacherInnovationRoutes(api, innovation, common);
      api.get(
        "/me/teacher",
        {
          schema: {
            ...common,
            summary: "Scoped synthetic teacher profile",
            response: { 200: single(profile), ...errorResponses },
          },
        },
        async (req) => ({ data: req.teacherPrincipal }),
      );
      api.get(
        "/me/teacher/overview",
        {
          schema: {
            ...common,
            summary: "Read-only teaching overview",
            response: {
              200: single(
                object({ profile, courses: { type: "array", items: course } }),
              ),
              ...errorResponses,
            },
          },
        },
        async (req) => ({
          data: {
            profile: req.teacherPrincipal,
            courses: await read(() =>
              source.courses(req.teacherPrincipal!.teacherCode),
            ),
          },
        }),
      );
      api.get(
        "/me/teacher/courses",
        {
          schema: {
            ...common,
            summary: "Assigned visible teaching courses",
            response: { 200: list(course), ...errorResponses },
          },
        },
        async (req) => {
          const data = await read(() =>
            source.courses(req.teacherPrincipal!.teacherCode),
          );
          return { data, meta: { count: data.length } };
        },
      );
      api.get(
        "/me/teacher/assignments",
        {
          schema: {
            ...common,
            summary: "Assigned-course work summary, no grading writes",
            response: {
              200: list(
                object({ courseId: str, courseName: str, ...work.properties }),
              ),
              ...errorResponses,
            },
          },
        },
        async (req) => {
          const courses = await read(() =>
            source.courses(req.teacherPrincipal!.teacherCode),
          );
          const data = courses.flatMap((c) =>
            c.work.map((w) => ({ ...w, courseId: c.id, courseName: c.name })),
          );
          return { data, meta: { count: data.length } };
        },
      );
      api.get<{ Params: { courseId: string } }>(
        "/me/teacher/courses/:courseId/students",
        {
          schema: {
            ...common,
            summary:
              "Course-scoped learner monitoring; rule-based support indicators only",
            params: object({
              courseId: { type: "string", pattern: "^[1-9][0-9]{0,14}$" },
            }),
            response: { 200: list(monitoring), ...errorResponses },
          },
        },
        async (req) => {
          const data = await read(() =>
            source.students(
              req.teacherPrincipal!.teacherCode,
              req.params.courseId,
            ),
          );
          if (data === null)
            throw new ApiFailure(
              404,
              "COURSE_NOT_FOUND",
              "Không tìm thấy khóa học được phép truy cập.",
            );
          return { data, meta: { count: data.length } };
        },
      );
    },
    { prefix: "/api/v1" },
  );
}
