import assert from "node:assert/strict";
import { Writable } from "node:stream";
import test from "node:test";
import type { TestContext } from "node:test";
import { buildApp } from "../src/app.ts";
import type { AppConfig } from "../src/config.ts";
import type {
  Assignment,
  AssignmentStatus,
  Content,
  Course,
  Deadline,
  Grade,
  Progress,
  Resource,
  Student,
  StudentLearningDataSource,
} from "../src/domain/student-learning.ts";

// MOCK implementation: deterministic synthetic unit-test data, no network or .env.
class MockStudentSource implements StudentLearningDataSource {
  calls: { method: string; code: string }[] = [];
  empty = false;
  failure = false;
  private record(method: string, code: string) {
    this.calls.push({ method, code });
    if (this.failure) throw new Error("synthetic-internal-database-detail");
  }
  async health() {
    if (this.failure) throw new Error("synthetic-internal-database-detail");
  }
  async student(code: string): Promise<Student | null> {
    this.record("student", code);
    if (!["SV001", "SV002"].includes(code)) return null;
    return {
      studentCode: code,
      fullName: `Sinh viên ${code}`,
      email: `${code.toLowerCase()}@example.test`,
      department: "Khoa mẫu",
      role: "student",
    };
  }
  async courses(code: string): Promise<Course[]> {
    this.record("courses", code);
    if (this.empty) return [];
    const id = code === "SV001" ? "1" : "2";
    return [
      {
        courseId: id,
        courseCode: `COURSE${id}`,
        courseName: `Học phần ${id}`,
        categoryName: "Học phần mẫu",
        summary: "Nội dung học tập",
        startsAt: "2030-01-01T00:00:00.000Z",
        endsAt: null,
        teacherNames: null,
      },
    ];
  }
  async content(code: string, courseId: string): Promise<Content[] | null> {
    this.record(`content:${courseId}`, code);
    if (courseId !== (code === "SV001" ? "1" : "2")) return null;
    if (this.empty) return [];
    return [
      {
        courseCode: `COURSE${courseId}`,
        sectionNumber: 1,
        sectionName: "Giới thiệu",
        courseModuleId: "10",
        position: 1,
        activityType: "resource",
        activityName: "Tài liệu mở đầu",
        description: "Đọc trước buổi học",
        assignmentCode: null,
        dueAt: null,
        filenames: "gioi-thieu.pdf",
        totalSizeBytes: 1024,
        deepLink: null,
        deepLinkStatus: "TO_VERIFY_DLU",
      },
    ];
  }
  async resources(code: string): Promise<Resource[]> {
    this.record("resources", code);
    if (this.empty) return [];
    return [
      {
        courseId: "1",
        courseCode: "COURSE1",
        courseName: "Học phần 1",
        sectionName: "Giới thiệu",
        resourceId: "10",
        resourceName: "Tài liệu mở đầu",
        description: "Tài liệu học tập",
        filename: "gioi-thieu.pdf",
        fileSizeBytes: 1024,
        mimeType: "application/pdf",
        deepLink: null,
        deepLinkStatus: "TO_VERIFY_DLU",
      },
    ];
  }
  async assignments(code: string): Promise<Assignment[]> {
    this.record("assignments", code);
    if (this.empty) return [];
    return [
      {
        courseId: "1",
        courseCode: "COURSE1",
        courseName: "Học phần 1",
        assignmentId: "20",
        assignmentCode: "BT01",
        assignmentName: "Bài tập mở đầu",
        description: "Đọc nội dung trên LMS",
        opensAt: "2030-01-01T00:00:00.000Z",
        dueAt: "2030-01-31T00:00:00.000Z",
        maxGrade: 10,
        deepLink: null,
        deepLinkStatus: "TO_VERIFY_DLU",
      },
    ];
  }
  async assignmentStatus(code: string): Promise<AssignmentStatus[]> {
    this.record("assignmentStatus", code);
    if (this.empty) return [];
    return [
      {
        courseCode: "COURSE1",
        courseName: "Học phần 1",
        assignmentCode: "BT01",
        assignmentName: "Bài tập mở đầu",
        submissionStatus: "graded",
        submittedAt: "2030-01-20T10:00:00.000Z",
        isLate: false,
        attemptNumber: 1,
        deepLink: null,
        deepLinkStatus: "TO_VERIFY_DLU",
      },
    ];
  }
  async grades(code: string): Promise<Grade[]> {
    this.record("grades", code);
    if (this.empty) return [];
    return [
      {
        courseCode: code === "SV001" ? "COURSE1" : "COURSE2",
        courseName: "Học phần mẫu",
        assignmentCode: "BT01",
        gradeItem: "Bài tập mở đầu",
        score: code === "SV001" ? 8.5 : 6.5,
        maxGrade: 10,
        percentage: code === "SV001" ? 85 : 65,
        gradeResult: "Đạt",
        feedback: `Nhận xét dành cho ${code}`,
        gradedAt: "2030-01-21T10:00:00.000Z",
        teacherName: "Giảng viên mẫu",
      },
    ];
  }
  async progress(code: string): Promise<Progress[]> {
    this.record("progress", code);
    if (this.empty) return [];
    return [
      {
        courseId: "1",
        courseCode: "COURSE1",
        courseName: "Học phần 1",
        totalActivities: 4,
        completedActivities: 3,
        progressPercent: 75,
      },
    ];
  }
  async deadlines(code: string): Promise<Deadline[]> {
    this.record("deadlines", code);
    if (this.empty) return [];
    return [
      {
        courseCode: "COURSE1",
        courseName: "Học phần 1",
        assignmentCode: "BT02",
        assignmentName: "Bài tập tiếp theo",
        dueAt: "2030-02-28T00:00:00.000Z",
        submissionStatus: "not_submitted",
        daysRemaining: 10,
        deepLink: null,
        deepLinkStatus: "TO_VERIFY_DLU",
      },
    ];
  }
}

const config: AppConfig = {
  environment: "development",
  port: 3000,
  host: "127.0.0.1",
  databaseUrl: "not-used-by-mock-source",
  demoAuthEnabled: true,
};
const headers = { "X-Demo-Student-Code": "SV001" };
const listPaths = [
  "courses",
  "resources",
  "assignments",
  "assignment-status",
  "grades",
  "progress",
  "deadlines",
];

async function setup(
  t: TestContext,
  source = new MockStudentSource(),
  overrides: Partial<AppConfig> = {},
) {
  const app = await buildApp({ ...config, ...overrides }, source, false);
  t.after(() => app.close());
  return { app, source };
}

test("health: reachability returns only the declared development metadata", async (t) => {
  const { app } = await setup(t);
  const response = await app.inject("/health");
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), {
    status: "ok",
    environment: "development",
    database: "reachable",
    dataSource: "neon-development-model",
  });
  assert.match(response.headers["content-type"]!, /^application\/json/);
  assert.equal(response.headers["cache-control"], "no-store");
  assert.equal(response.headers["x-content-type-options"], "nosniff");
});

test("health: unavailable database fails closed with a sanitized 503", async (t) => {
  const source = new MockStudentSource();
  source.failure = true;
  const { app } = await setup(t, source);
  const response = await app.inject("/health");
  assert.equal(response.statusCode, 503);
  assert.equal(response.json().error.code, "DATA_SOURCE_UNAVAILABLE");
  assert.equal(
    response.body.includes("synthetic-internal-database-detail"),
    false,
  );
});

test("SEC01: missing identity is 401 on every student endpoint", async (t) => {
  const { app, source } = await setup(t);
  for (const path of [
    "",
    ...listPaths.map((p) => `/${p}`),
    "/courses/1/content",
    "/overview",
  ]) {
    const response = await app.inject(`/api/v1/me${path}`);
    assert.equal(response.statusCode, 401);
    assert.equal(response.json().error.code, "DEVELOPMENT_IDENTITY_REQUIRED");
  }
  assert.equal(source.calls.length, 0);
});

test("SEC02: malformed, unknown and teacher identities cannot resolve a student principal", async (t) => {
  const { app } = await setup(t);
  for (const code of [
    "SV999",
    "SV1",
    "sv001",
    "GV001",
    "teacher",
    "SV001,SV002",
    "SV001' OR 1=1--",
  ]) {
    const response = await app.inject({
      url: "/api/v1/me",
      headers: { "X-Demo-Student-Code": code },
    });
    assert.equal(response.statusCode, 401);
    assert.equal(Object.hasOwn(response.json(), "data"), false);
  }
});

test("profile: only the current scoped synthetic profile is returned", async (t) => {
  const { app } = await setup(t);
  const response = await app.inject({ url: "/api/v1/me", headers });
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), {
    data: {
      studentCode: "SV001",
      fullName: "Sinh viên SV001",
      email: "sv001@example.test",
      department: "Khoa mẫu",
      role: "student",
    },
  });
});

test("lists: all student collections return typed data, count and JSON content type", async (t) => {
  const { app } = await setup(t);
  for (const path of listPaths) {
    const response = await app.inject({ url: `/api/v1/me/${path}`, headers });
    assert.equal(response.statusCode, 200);
    const result = response.json();
    assert.deepEqual(Object.keys(result).sort(), ["data", "meta"]);
    assert.equal(Array.isArray(result.data), true);
    assert.equal(result.data.length, 1);
    assert.deepEqual(result.meta, { count: 1 });
    assert.match(response.headers["content-type"]!, /^application\/json/);
  }
});

test("SEC03: inaccessible and nonexistent course content are indistinguishable 404 responses", async (t) => {
  const { app } = await setup(t);
  const inaccessible = await app.inject({
    url: "/api/v1/me/courses/2/content",
    headers,
  });
  const nonexistent = await app.inject({
    url: "/api/v1/me/courses/999/content",
    headers,
  });
  assert.equal(inaccessible.statusCode, 404);
  assert.equal(nonexistent.statusCode, 404);
  assert.deepEqual(inaccessible.json(), nonexistent.json());
  assert.equal(inaccessible.json().error.code, "COURSE_NOT_FOUND");
});

test("course content: own enrollment is served, with no fabricated live deep link", async (t) => {
  const { app, source } = await setup(t);
  const response = await app.inject({
    url: "/api/v1/me/courses/1/content",
    headers,
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().data[0].deepLink, null);
  assert.equal(response.json().data[0].deepLinkStatus, "TO_VERIFY_DLU");
  assert.deepEqual(source.calls.at(-1), { method: "content:1", code: "SV001" });
});

test("SEC04: grades are scoped to the resolved student rather than a caller-supplied ID", async (t) => {
  const { app, source } = await setup(t);
  const first = await app.inject({ url: "/api/v1/me/grades", headers });
  const second = await app.inject({
    url: "/api/v1/me/grades",
    headers: { "X-Demo-Student-Code": "SV002" },
  });
  assert.equal(first.statusCode, 200);
  assert.equal(second.statusCode, 200);
  assert.equal(first.json().data[0].score, 8.5);
  assert.equal(second.json().data[0].score, 6.5);
  assert.equal(first.body.includes("SV002"), false);
  assert.equal(second.body.includes("SV001"), false);
  assert.deepEqual(
    source.calls.filter((c) => c.method === "grades"),
    [
      { method: "grades", code: "SV001" },
      { method: "grades", code: "SV002" },
    ],
  );
});

test("SEC05: query identity spoofing and malformed path identifiers are rejected with 400", async (t) => {
  const { app } = await setup(t);
  for (const query of [
    "studentId=102",
    "userId=102",
    "studentCode=SV002",
    "role=teacher",
    "courseId=2",
    "unexpected=value",
  ]) {
    const response = await app.inject({
      url: `/api/v1/me/grades?${query}`,
      headers,
    });
    assert.equal(response.statusCode, 400);
    assert.equal(response.json().error.code, "INVALID_REQUEST");
  }
  for (const id of [
    "0",
    "-1",
    "1.5",
    "abc",
    "9999999999999999",
    "1%27%20OR%201%3D1",
  ]) {
    const response = await app.inject({
      url: `/api/v1/me/courses/${id}/content`,
      headers,
    });
    assert.equal(response.statusCode, 400);
    assert.equal(response.json().error.code, "INVALID_REQUEST");
  }
});

test("SEC06: no submission, upload, grade, teacher or database mutation routes exist", async (t) => {
  const { app } = await setup(t);
  for (const url of [
    "/api/v1/me/submissions",
    "/api/v1/me/assignments/1/submit",
    "/api/v1/me/upload",
    "/api/v1/teacher/grades",
    "/api/v1/me/grades",
    "/api/v1/courses",
  ]) {
    for (const method of ["POST", "PUT", "PATCH", "DELETE"] as const) {
      const response = await app.inject({ method, url, headers });
      assert.equal(response.statusCode, 404);
      assert.equal(response.json().error.code, "NOT_FOUND");
    }
  }
});

test("SEC07: database details are sanitized and response schemas discard unapproved fields", async (t) => {
  const source = new MockStudentSource();
  source.student = async () => ({
    studentCode: "SV001",
    fullName: "Sinh viên mẫu",
    email: "student@example.test",
    department: "Khoa mẫu",
    role: "student",
    internalPasswordHash: "synthetic-private-test-marker",
  });
  source.grades = async () => {
    throw new Error("synthetic-internal-database-detail");
  };
  const { app } = await setup(t, source);
  const profile = await app.inject({ url: "/api/v1/me", headers });
  assert.equal(profile.statusCode, 200);
  assert.equal(profile.body.includes("synthetic-private-test-marker"), false);
  assert.equal(
    Object.hasOwn(profile.json().data, "internalPasswordHash"),
    false,
  );
  const grades = await app.inject({ url: "/api/v1/me/grades", headers });
  assert.equal(grades.statusCode, 503);
  assert.equal(
    grades.body.includes("synthetic-internal-database-detail"),
    false,
  );
  assert.deepEqual(Object.keys(grades.json()), ["error"]);
  assert.deepEqual(Object.keys(grades.json().error).sort(), [
    "code",
    "message",
  ]);
});

test("SEC08: unexpected handler exceptions become a generic 500 without raw internals", async (t) => {
  const { app } = await setup(t);
  app.get("/unit-test-error", async () => {
    throw new Error("synthetic-private-test-marker");
  });
  const response = await app.inject("/unit-test-error");
  assert.equal(response.statusCode, 500);
  assert.equal(response.json().error.code, "INTERNAL_ERROR");
  assert.equal(response.body.includes("synthetic-private-test-marker"), false);
  assert.equal(Object.hasOwn(response.json().error, "stack"), false);
});

test("SEC09: disabled demo authentication fails closed even for a known student", async (t) => {
  const { app, source } = await setup(t, new MockStudentSource(), {
    demoAuthEnabled: false,
  });
  const response = await app.inject({ url: "/api/v1/me", headers });
  assert.equal(response.statusCode, 401);
  assert.equal(source.calls.length, 0);
});

test("safe request logs: raw query, headers, error objects and personal data are never written", async (t) => {
  let captured = "";
  const stream = new Writable({
    write(chunk, _encoding, done) {
      captured += chunk.toString();
      done();
    },
  });
  const source = new MockStudentSource();
  const app = await buildApp(config, source, { stream, level: "info" });
  t.after(() => app.close());
  app.get("/unit-test-error", async () => {
    throw new Error("synthetic-error-private-marker");
  });
  await app.inject({
    url: "/api/v1/me?unknown=synthetic-query-private-marker",
    headers: {
      ...headers,
      authorization: "Bearer synthetic-header-private-marker",
    },
  });
  await app.inject("/unit-test-error");
  await app.inject("/not-found/synthetic-path-private-marker");
  assert.equal(captured.includes("request_completed"), true);
  for (const marker of [
    "synthetic-error-private-marker",
    "synthetic-query-private-marker",
    "synthetic-header-private-marker",
    "synthetic-path-private-marker",
    "sv001@example.test",
  ]) {
    assert.equal(captured.includes(marker), false);
  }
});

test("empty collections and overview return genuine zero states without fixture fallback", async (t) => {
  const source = new MockStudentSource();
  source.empty = true;
  const { app } = await setup(t, source);
  for (const path of [...listPaths, "courses/1/content"]) {
    const response = await app.inject({ url: `/api/v1/me/${path}`, headers });
    assert.equal(response.statusCode, 200);
    assert.deepEqual(response.json(), { data: [], meta: { count: 0 } });
  }
  const response = await app.inject({ url: "/api/v1/me/overview", headers });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().data.courseCount, 0);
  assert.equal(response.json().data.nextDeadline, null);
  assert.deepEqual(response.json().data.assignmentSummary, {
    total: 0,
    submitted: 0,
    graded: 0,
    outstanding: 0,
    late: 0,
  });
});

test("overview: aggregation uses only the current student in every source call", async (t) => {
  const { app, source } = await setup(t);
  const response = await app.inject({ url: "/api/v1/me/overview", headers });
  assert.equal(response.statusCode, 200);
  const data = response.json().data;
  assert.equal(data.student.studentCode, "SV001");
  assert.equal(data.courseCount, 1);
  assert.equal(data.upcomingDeadlineCount, 1);
  assert.deepEqual(data.assignmentSummary, {
    total: 1,
    submitted: 1,
    graded: 1,
    outstanding: 0,
    late: 0,
  });
  assert.deepEqual(data.gradeSummary, { gradedItemCount: 1 });
  assert.equal(data.nextDeadline.deepLink, null);
  assert.equal(
    source.calls.every((call) => call.code === "SV001"),
    true,
  );
});

test("OpenAPI: exact read-only contract, development disclaimer, header identity and local server", async (t) => {
  const { app } = await setup(t);
  const response = await app.inject("/openapi.json");
  assert.equal(response.statusCode, 200);
  const spec = response.json();
  assert.equal(spec.openapi, "3.0.3");
  assert.match(spec.info.title, /Development Integration API/);
  assert.match(spec.info.description, /NOT the production API/);
  assert.deepEqual(
    spec.servers.map((server: { url: string }) => server.url),
    ["http://localhost:3000"],
  );
  assert.equal(
    spec.components.securitySchemes.DemoStudent.name,
    "X-Demo-Student-Code",
  );
  assert.equal(spec.components.securitySchemes.DemoStudent.in, "header");
  const expected = [
    "/health",
    "/api/v1/me",
    ...listPaths.map((path) => `/api/v1/me/${path}`),
    "/api/v1/me/courses/{courseId}/content",
    "/api/v1/me/overview",
  ].sort();
  assert.deepEqual(Object.keys(spec.paths).sort(), expected);
  for (const [path, operations] of Object.entries(spec.paths) as [
    string,
    Record<
      string,
      {
        parameters?: { in: string; name: string; required?: boolean }[];
        security?: object[];
        responses: object;
      }
    >,
  ][]) {
    assert.deepEqual(Object.keys(operations), ["get"]);
    const get = operations.get!;
    assert.equal(Object.hasOwn(get.responses, "200"), true);
    if (path !== "/health") {
      assert.deepEqual(get.security, [{ DemoStudent: [] }]);
      assert.equal(
        get.parameters?.some(
          (p) =>
            p.in === "header" &&
            p.name === "x-demo-student-code" &&
            p.required === true,
        ),
        true,
      );
    }
  }
});

test("Swagger UI: local documentation is actually served", async (t) => {
  const { app } = await setup(t);
  const response = await app.inject("/docs/");
  assert.equal(response.statusCode, 200);
  assert.match(response.headers["content-type"]!, /^text\/html/);
  assert.match(response.body, /swagger-ui/i);
});

test("OpenAPI staging: same-origin server preserves the synthetic-only disclaimer without reflecting request hosts", async (t) => {
  const { app } = await setup(t, new MockStudentSource(), {
    environment: "staging",
    port: 10000,
    host: "0.0.0.0",
  });
  const response = await app.inject({
    url: "/openapi.json",
    headers: {
      host: "untrusted.example.test",
      "x-forwarded-host": "untrusted-forwarded.example.test",
      "x-forwarded-proto": "http",
    },
  });
  assert.equal(response.statusCode, 200);
  const spec = response.json();
  assert.deepEqual(spec.servers, [
    {
      url: "/",
      description:
        "Same-origin staging; synthetic data only, not DLU production",
    },
  ]);
  assert.match(spec.info.description, /development\/staging API/);
  assert.match(spec.info.description, /NOT the production API/);
  assert.match(spec.info.description, /Synthetic student data only/);
  assert.match(
    spec.components.securitySchemes.DemoStudent.description,
    /NOT production authentication/,
  );
  for (const marker of [
    "localhost",
    "0.0.0.0",
    "untrusted.example.test",
    "untrusted-forwarded.example.test",
  ]) {
    assert.equal(response.body.includes(marker), false);
  }
  const docs = await app.inject("/docs/");
  assert.equal(docs.statusCode, 200);
  assert.match(docs.headers["content-type"]!, /^text\/html/);
});
