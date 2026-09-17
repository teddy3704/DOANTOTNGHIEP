import { buildApp } from "../src/app.ts";
import { loadConfig } from "../src/config.ts";
import { createPool, PostgresReadDatabase } from "../src/data/database.ts";
import { PostgresDevelopmentDataSource } from "../src/data/postgres-development-data-source.ts";

let pool: ReturnType<typeof createPool> | undefined;
let app: Awaited<ReturnType<typeof buildApp>> | undefined;
const results: {
  test: string;
  status: "PASS" | "FAIL";
  http?: number;
  count?: number;
}[] = [];
let phase = "configuration";
const ensure = (condition: unknown) => {
  if (!condition) throw new Error("SMOKE_ASSERTION_FAILED");
};
try {
  const config = loadConfig();
  pool = createPool(config.databaseUrl);
  const db = new PostgresReadDatabase(pool);
  phase = "app-registration";
  app = await buildApp(config, new PostgresDevelopmentDataSource(db), false);
  phase = "listen-and-schemas";
  const base = await app.listen({ host: "127.0.0.1", port: 0 });
  const get = async (
    path: string,
    identity: string | null = "SV001",
    expected = 200,
  ) => {
    phase = path;
    const response = await fetch(base + path, {
      headers: identity ? { "X-Demo-Student-Code": identity } : {},
    });
    const text = await response.text();
    ensure(response.status === expected && !text.includes(config.databaseUrl));
    ensure(
      !/postgres(?:ql)?:\/\/|\"(?:password|access_token|refresh_token|stack|databaseUrl)\"/i.test(
        text,
      ),
    );
    const body = JSON.parse(text) as {
      data: Record<string, unknown>[] & Record<string, unknown>;
      meta?: { count: number };
      status?: string;
    };
    results.push({
      test: path + (identity ? "" : " (no identity)"),
      status: "PASS",
      http: response.status,
      ...(body.meta ? { count: body.meta.count } : {}),
    });
    return body;
  };
  ensure((await get("/health")).status === "ok");
  ensure((await get("/api/v1/me")).data.studentCode === "SV001");
  const courses = await get("/api/v1/me/courses");
  ensure(courses.data.length > 0);
  const courseId = courses.data[0]?.courseId;
  ensure(typeof courseId === "string");
  await get(`/api/v1/me/courses/${courseId}/content`);
  for (const path of [
    "resources",
    "assignments",
    "assignment-status",
    "progress",
    "deadlines",
    "overview",
  ])
    await get("/api/v1/me/" + path);
  const grades = await get("/api/v1/me/grades");
  const expectedGrades = await db.read<{
    assignmentCode: string;
    score: number;
  }>(
    `
    SELECT g.assignment_code AS "assignmentCode",g.score::float8 AS score
    FROM lms.vw_student_grade_overview g WHERE g.student_code=$1 AND EXISTS (
      SELECT 1 FROM lms.vw_student_assignments a WHERE a.student_code=g.student_code AND a.course_code=g.course_code AND a.assignment_code=g.assignment_code)
    ORDER BY g.assignment_code`,
    ["SV001"],
  );
  const received = grades.data
    .map((g) => ({ assignmentCode: g.assignmentCode, score: g.score }))
    .sort((a, b) =>
      String(a.assignmentCode).localeCompare(String(b.assignmentCode)),
    );
  ensure(JSON.stringify(received) === JSON.stringify(expectedGrades));
  results.push({
    test: "SV001 grade response equals scoped database query",
    status: "PASS",
  });
  const other = await get("/api/v1/me/grades", "SV002");
  const otherExpected = await db.read<{ count: number }>(
    `SELECT count(*)::int AS count FROM lms.vw_student_grade_overview g WHERE g.student_code=$1 AND EXISTS (SELECT 1 FROM lms.vw_student_assignments a WHERE a.student_code=g.student_code AND a.course_code=g.course_code AND a.assignment_code=g.assignment_code)`,
    ["SV002"],
  );
  ensure(other.data.length === otherExpected[0]?.count);
  await get("/api/v1/me/courses", null, 401);
  await get("/api/v1/me", "GV001", 401);
  await get("/api/v1/me", "SV999", 401);
  await get("/api/v1/me/courses/3/content", "SV001", 404);
  await get("/api/v1/me/courses/999999999/content", "SV001", 404);
  await get("/api/v1/me/grades?studentCode=SV002", "SV001", 400);
  const spec = (await fetch(base + "/openapi.json").then((r) => r.json())) as {
    paths: Record<string, unknown>;
  };
  ensure(Object.keys(spec.paths).length === 11);
  const docs = await fetch(base + "/docs/");
  ensure(docs.ok && (await docs.text()).includes("swagger-ui"));
  results.push({
    test: "OpenAPI 11 read routes and Swagger HTML",
    status: "PASS",
  });
  console.log(JSON.stringify({ NEON_SMOKE: "PASS", results }, null, 2));
} catch (error) {
  const code =
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof error.code === "string" &&
    /^FST_ERR_[A-Z_]+$/.test(error.code)
      ? error.code
      : "SAFE_FAILURE";
  console.log(
    JSON.stringify(
      { NEON_SMOKE: "FAIL", phase, code, completed: results },
      null,
      2,
    ),
  );
  process.exitCode = 1;
} finally {
  await app?.close();
  await pool?.end();
}
