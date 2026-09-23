// Public, GET-only verification. No database connection or credential is loaded.
const base = "https://dlu-lms-student-support-staging.onrender.com";
let failed = 0;
let checks = 0;
function verify(name: string, pass: boolean) {
  checks++;
  if (!pass) failed++;
  console.log(JSON.stringify({ check: name, pass }));
}
async function request(
  path: string,
  headers: Record<string, string> = {},
  expected = 200,
) {
  const response = await fetch(base + path, {
    headers,
    signal: AbortSignal.timeout(45000),
  });
  verify(
    `${Object.values(headers).join("+") || "none"} ${path} ${expected}`,
    response.status === expected,
  );
  const content = await response.text();
  verify(
    `safe response ${path}`,
    !/postgres(?:ql)?:\/\/|BEGIN (?:RSA )?PRIVATE KEY/i.test(content),
  );
  const body = response.headers.get("content-type")?.includes("json")
    ? JSON.parse(content)
    : null;
  if (body?.meta)
    verify(
      `list envelope ${path}`,
      Array.isArray(body.data) && body.meta.count === body.data.length,
    );
  return body;
}
try {
  const health = await request("/health");
  verify(
    "database reachable",
    health.status === "ok" && health.database === "reachable",
  );
  await request("/docs");
  const openapi = await request("/openapi.json");
  verify(
    "five read-only teacher routes published",
    Object.entries(openapi.paths).filter(([p]) => p.includes("/teacher"))
      .length === 5,
  );
  for (const code of ["SV001", "SV002"]) {
    const headers = { "X-Demo-Student-Code": code };
    const profile = await request("/api/v1/me", headers);
    verify(
      "student identity response " + code,
      profile.data.studentCode === code &&
        profile.data.role === "student" &&
        profile.data.email.endsWith("@example.test"),
    );
    const courses = await request("/api/v1/me/courses", headers);
    verify(
      "candidate enrollment " + code,
      JSON.stringify(
        courses.data.map((c: { courseId: string }) => c.courseId).sort(),
      ) === JSON.stringify(["11", "12", "3000015"]),
    );
    for (const route of [
      "resources",
      "assignments",
      "assignment-status",
      "grades",
      "progress",
      "deadlines",
      "overview",
      "courses/11/content",
    ])
      await request("/api/v1/me/" + route, headers);
    await request("/api/v1/me/courses/13/content", headers, 404);
    await request("/api/v1/me?userId=202", headers, 400);
    await request("/api/v1/me/teacher", headers, 401);
  }
  for (const code of ["GV001", "GV002"]) {
    const headers = { "X-Demo-Teacher-Code": code };
    const profile = await request("/api/v1/me/teacher", headers);
    verify(
      "teacher identity response " + code,
      profile.data.teacherCode === code &&
        profile.data.role === "teacher" &&
        profile.data.email.endsWith("@example.test"),
    );
    const courses = await request("/api/v1/me/teacher/courses", headers);
    const expected = code === "GV001" ? ["11", "12"] : ["13", "14", "3000015"];
    verify(
      "teacher course ownership " + code,
      JSON.stringify(courses.data.map((c: { id: string }) => c.id).sort()) ===
        JSON.stringify(expected),
    );
    await request("/api/v1/me/teacher/overview", headers);
    await request("/api/v1/me/teacher/assignments", headers);
    const own = code === "GV001" ? "11" : "13";
    const other = code === "GV001" ? "13" : "11";
    const roster = await request(
      `/api/v1/me/teacher/courses/${own}/students`,
      headers,
    );
    verify(
      "roster stays within teacher course " + code,
      roster.data.length > 0 &&
        roster.data.every((r: { courseId: string }) => r.courseId === own),
    );
    await request(`/api/v1/me/teacher/courses/${other}/students`, headers, 404);
    await request("/api/v1/me", headers, 401);
  }
  await request("/api/v1/me", {}, 401);
  await request("/api/v1/me/teacher", {}, 401);
  for (const id of ["101", "GV999"])
    await request("/api/v1/me/teacher", { "X-Demo-Teacher-Code": id }, 401);
  await request(
    "/api/v1/me/teacher",
    { "X-Demo-Teacher-Code": "GV001", "X-Demo-Student-Code": "SV001" },
    401,
  );
  verify(
    "no academic write routes published",
    Object.entries(openapi.paths).every(([, value]) =>
      Object.keys(value as object).every((method) =>
        ["get", "head", "parameters"].includes(method),
      ),
    ),
  );
} catch {
  verify("public request completed without transport/contract error", false);
}
console.log(
  JSON.stringify({
    stagingGroupSmoke: failed ? "FAIL" : "PASS",
    checks,
    failed,
    academicWrites: false,
  }),
);
if (failed) process.exitCode = 1;
