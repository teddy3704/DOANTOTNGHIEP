// Explicit candidate integration test; never loads .env or outputs credentials.
import { loadConfig } from "../src/config.ts";
import { createPool, PostgresReadDatabase } from "../src/data/database.ts";
import { GroupStudentDataSource } from "../src/data/group-student-data-source.ts";
import { GroupTeacherDataSource } from "../src/data/group-teacher-data-source.ts";
import { buildApp } from "../src/app.ts";

let pool: ReturnType<typeof createPool> | undefined;
let app: Awaited<ReturnType<typeof buildApp>> | undefined;
let failed = 0;
const isolationOnly = process.argv.includes("--isolation-only");
try {
  const config = loadConfig({
    APP_ENV: "development",
    PORT: "3001",
    DEMO_AUTH_ENABLED: "true",
    DATABASE_MODEL: "group_39_20",
    DATABASE_URL: process.env.CANDIDATE_DATABASE_URL,
  });
  pool = createPool(config.databaseUrl, "group_39_20");
  const db = new PostgresReadDatabase(pool);
  app = await buildApp(
    config,
    new GroupStudentDataSource(db),
    false,
    new GroupTeacherDataSource(db),
  );
  await app.listen({ host: "127.0.0.1", port: 0 });
  const address = app.server.address();
  if (!address || typeof address === "string")
    throw new Error("LOCAL_BIND_FAILED");
  const base = `http://127.0.0.1:${address.port}`;
  async function check(
    path: string,
    headers: Record<string, string> = {},
    expected = 200,
    method = "GET",
  ) {
    const response = await fetch(base + path, { headers, method });
    const body = (await response.json()) as {
      data?: unknown;
      error?: { code: string };
      meta?: { count: number };
    };
    const pass = response.status === expected;
    if (!pass) failed++;
    console.log(
      JSON.stringify({
        path,
        identity:
          headers["X-Demo-Student-Code"] ??
          headers["X-Demo-Teacher-Code"] ??
          "none",
        method,
        status: response.status,
        pass,
        count: body.meta?.count,
        error: body.error?.code,
      }),
    );
    return body.data;
  }
  await check("/health");
  for (const code of ["SV001", "SV002"]) {
    const headers = { "X-Demo-Student-Code": code };
    if (!isolationOnly)
      for (const route of [
        "",
        "/resources",
        "/assignments",
        "/assignment-status",
        "/grades",
        "/progress",
        "/deadlines",
        "/overview",
      ])
        await check("/api/v1/me" + route, headers);
    const courses = (await check("/api/v1/me/courses", headers)) as {
      courseId: string;
    }[];
    const id = code === "SV001" ? "201" : "202";
    const independentlyEnrolled = await db.read(
      `SELECT DISTINCT c.id::text AS id FROM lms.course c JOIN lms.enrol e ON e.courseid=c.id
      JOIN lms.user_enrolments ue ON ue.enrolid=e.id JOIN lms.context ctx ON ctx.instanceid=c.id AND ctx.contextlevel=50
      JOIN lms.role_assignments ra ON ra.contextid=ctx.id AND ra.userid=ue.userid JOIN lms.role r ON r.id=ra.roleid
      WHERE ue.userid=$1::bigint AND ue.status=0 AND e.status=0 AND c.visible=1 AND r.shortname='student'
      AND (ue.timestart=0 OR ue.timestart<=extract(epoch FROM now())) AND (ue.timeend=0 OR ue.timeend>extract(epoch FROM now()))`,
      [id],
    );
    const expectedIds = independentlyEnrolled.map((r) => r.id as string).sort();
    const courseSetPass =
      JSON.stringify(courses.map((c) => c.courseId).sort()) ===
      JSON.stringify(expectedIds);
    if (!courseSetPass) failed++;
    console.log(
      JSON.stringify({
        check: "student_exact_enrolment_scope",
        identity: code,
        pass: courseSetPass,
      }),
    );
    if (!isolationOnly) await check("/api/v1/me/courses/11/content", headers);
    const outside = (
      await db.read(
        "SELECT id::text AS id FROM lms.course WHERE visible=1 ORDER BY id",
      )
    ).find((r) => !expectedIds.includes(r.id as string));
    if (!outside) throw new Error("NO_NEGATIVE_SCOPE_FIXTURE");
    await check(`/api/v1/me/courses/${outside.id}/content`, headers, 404);
    await check("/api/v1/me?userId=202", headers, 400);
    await check("/api/v1/me/teacher", headers, 401);
  }
  if (!isolationOnly)
    for (const code of ["GV001", "GV002"]) {
      const headers = { "X-Demo-Teacher-Code": code };
      for (const route of ["", "/overview", "/courses", "/assignments"])
        await check("/api/v1/me/teacher" + route, headers);
      const own = code === "GV001" ? "11" : "13";
      const other = code === "GV001" ? "13" : "11";
      const roster = (await check(
        `/api/v1/me/teacher/courses/${own}/students`,
        headers,
      )) as { courseId: string }[];
      if (!Array.isArray(roster) || roster.some((r) => r.courseId !== own))
        failed++;
      await check(`/api/v1/me/teacher/courses/${other}/students`, headers, 404);
      await check("/api/v1/me", headers, 401);
    }
  if (!isolationOnly) {
    await check("/api/v1/me", {}, 401);
    await check("/api/v1/me/teacher", {}, 401);
    await check("/api/v1/me", { "X-Demo-Student-Code": "201" }, 401);
    await check("/api/v1/me", { "X-Demo-Student-Code": "SV999" }, 401);
    await check("/api/v1/me/teacher", { "X-Demo-Teacher-Code": "101" }, 401);
    await check("/api/v1/me/teacher", { "X-Demo-Teacher-Code": "GV999" }, 401);
    await check(
      "/api/v1/me/teacher",
      { "X-Demo-Teacher-Code": "GV001", "X-Demo-Student-Code": "SV001" },
      401,
    );
    await check(
      "/api/v1/me/teacher/grades",
      { "X-Demo-Teacher-Code": "GV001" },
      404,
      "POST",
    );
  }
  console.log(
    JSON.stringify({
      candidateHttpSmoke: failed === 0 ? "PASS" : "FAIL",
      scope: isolationOnly ? "TARGETED_STUDENT_ISOLATION" : "FULL",
      failed,
      transport: "REAL_LOCAL_HTTP",
      academicWrites: false,
    }),
  );
  if (failed) process.exitCode = 1;
} catch {
  console.log(
    JSON.stringify({
      candidateHttpSmoke: "FAIL",
      code: "CANDIDATE_SMOKE_ERROR",
    }),
  );
  process.exitCode = 1;
} finally {
  await app?.close();
  await pool?.end();
}
