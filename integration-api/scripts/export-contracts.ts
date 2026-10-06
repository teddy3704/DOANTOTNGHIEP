import { mkdir, writeFile } from "node:fs/promises";
import { buildApp } from "../src/app.ts";
import type { StudentLearningDataSource } from "../src/domain/student-learning.ts";
import type { InnovationStore } from "../src/domain/innovation.ts";

// Contract generation cannot connect to any data source or read a secret file.
const unavailable = async (): Promise<never> => {
  throw new Error("CONTRACT_GENERATION_ONLY");
};
const source: StudentLearningDataSource = {
  health: unavailable,
  student: unavailable,
  courses: unavailable,
  content: unavailable,
  resources: unavailable,
  assignments: unavailable,
  assignmentStatus: unavailable,
  grades: unavailable,
  progress: unavailable,
  deadlines: unavailable,
};
const candidateStore: InnovationStore = {
  plans: unavailable,
  createPlan: unavailable,
  updatePlan: unavailable,
  deletePlan: unavailable,
  interventions: unavailable,
  createIntervention: unavailable,
  updateIntervention: unavailable,
  addFollowup: unavailable,
};
const app = await buildApp(
  {
    environment: "development",
    port: 3000,
    host: "127.0.0.1",
    databaseUrl: "",
    demoAuthEnabled: true,
  },
  source,
  false,
  process.argv.includes("--candidate")
    ? { teacher: unavailable, courses: unavailable, students: unavailable }
    : undefined,
  process.argv.includes("--candidate") ? candidateStore : undefined,
);
await app.ready();
try {
  const spec = app.swagger();
  const candidate = process.argv.includes("--candidate");
  await writeFile(
    candidate ? "openapi.group-39-20.json" : "openapi.json",
    JSON.stringify(spec, null, 2) + "\n",
  );
  const item = (
    name: string,
    path: string,
    expected = 200,
    identity = true,
    method = "GET",
  ) => ({
    name,
    request: {
      method,
      header: identity
        ? [
            {
              key: "X-Demo-Student-Code",
              value: "{{demo_student_code}}",
              type: "text",
            },
          ]
        : [],
      url: "{{base_url}}" + path,
      description:
        "Development PostgreSQL model only. This is NOT the production DLU LMS API.",
    },
    event: [
      {
        listen: "test",
        script: {
          type: "text/javascript",
          exec: [
            `pm.test('Expected HTTP status', () => pm.response.to.have.status(${expected}));`,
            "pm.test('JSON response', () => pm.expect(pm.response.headers.get('Content-Type')).to.include('application/json'));",
            "const body = pm.response.json();",
            expected === 200
              ? path === "/health"
                ? "pm.test('Health is reachable', () => { pm.expect(body.status).to.eql('ok'); pm.expect(body.database).to.eql('reachable'); });"
                : "pm.test('Data contract', () => pm.expect(body).to.have.property('data'));"
              : "pm.test('Safe error contract', () => { pm.expect(body.error.code).to.be.a('string'); pm.expect(body.error.message).to.be.a('string'); });",
            "function safeKeys(value) { if (!value || typeof value !== 'object') return true; return Object.entries(value).every(([key, val]) => !/password|token|authorization|database.?url|stack|sql/i.test(key) && safeKeys(val)); }",
            "pm.test('No credential or internal error fields', () => pm.expect(safeKeys(body)).to.eql(true));",
            "pm.test('List count is correct', () => { if (Array.isArray(body.data)) { pm.expect(body.meta.count).to.eql(body.data.length); } });",
          ],
        },
      },
    ],
    response: [],
  });
  const folders = [
    { name: "00 Health", item: [item("Health", "/health", 200, false)] },
    {
      name: "01 Student Profile",
      item: [item("Current synthetic student", "/api/v1/me")],
    },
    { name: "02 Courses", item: [item("Courses", "/api/v1/me/courses")] },
    {
      name: "03 Course Content",
      item: [item("Course content", "/api/v1/me/courses/1/content")],
    },
    {
      name: "04 Resources",
      item: [item("Learning resources", "/api/v1/me/resources")],
    },
    {
      name: "05 Assignments",
      item: [
        item("Assignments", "/api/v1/me/assignments"),
        item("Assignment status", "/api/v1/me/assignment-status"),
      ],
    },
    {
      name: "06 Grades",
      item: [item("Grades and feedback", "/api/v1/me/grades")],
    },
    {
      name: "07 Progress",
      item: [item("Learning progress", "/api/v1/me/progress")],
    },
    {
      name: "08 Deadlines",
      item: [item("Upcoming deadlines", "/api/v1/me/deadlines")],
    },
    {
      name: "09 Overview",
      item: [item("Student learning overview", "/api/v1/me/overview")],
    },
    {
      name: "10 Negative & Security Tests",
      item: [
        item("Missing identity", "/api/v1/me/courses", 401, false),
        item(
          "Inaccessible course for SV001",
          "/api/v1/me/courses/3/content",
          404,
        ),
        item("Unknown course", "/api/v1/me/courses/999999999/content", 404),
        item(
          "Reject identity override query",
          "/api/v1/me/grades?studentCode=SV002",
          400,
        ),
        item(
          "No submission route",
          "/api/v1/assignments/1/submit",
          404,
          true,
          "POST",
        ),
        item("No grading route", "/api/v1/teacher/grades", 404, true, "POST"),
      ],
    },
  ];
  if (candidate) {
    folders.push({
      name: "12 Student study planner",
      item: [
        item("Explainable priorities", "/api/v1/me/recommendations"),
        item("Own study plan", "/api/v1/me/study-plan"),
      ],
    });
    folders.push({
      name: "11 Teacher read-only support",
      item: [
        item("Teacher profile", "/api/v1/me/teacher"),
        item("Teacher overview", "/api/v1/me/teacher/overview"),
        item("Teaching courses", "/api/v1/me/teacher/courses"),
        item("Teaching work", "/api/v1/me/teacher/assignments"),
        item("Scoped attention", "/api/v1/me/teacher/attention"),
        item("Own interventions", "/api/v1/me/teacher/interventions"),
        item("Due follow-ups", "/api/v1/me/teacher/followups"),
        item("Own course students", "/api/v1/me/teacher/courses/11/students"),
        item(
          "Other teacher course denied",
          "/api/v1/me/teacher/courses/13/students",
          404,
        ),
      ].map((i) => ({
        ...i,
        request: {
          ...i.request,
          header: [
            { key: "X-Demo-Teacher-Code", value: "GV001", type: "text" },
          ],
        },
      })),
    });
    for (const folder of folders)
      for (const i of folder.item) {
        i.request.url = i.request.url
          .replace("/courses/1/content", "/courses/11/content")
          .replace("/courses/3/content", "/courses/13/content");
      }
  }
  const collection = {
    info: {
      name: candidate
        ? "DLU LMS Student + Teacher — GROUP_39_20 Candidate"
        : "DLU LMS Student Support — Development API",
      schema:
        "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
      description: candidate
        ? "Isolated GROUP_39_20 candidate only. Synthetic identities. No DLU authentication or academic writes."
        : "Synthetic development model, student support only. SV001 enrollment verified in courses 1 and 2. No production DLU authentication or write endpoints.",
    },
    item: folders,
  };
  const environment = {
    name: "DLU LMS Development",
    values: [
      {
        key: "base_url",
        value: candidate ? "http://localhost:3001" : "http://localhost:3000",
        enabled: true,
        type: "default",
      },
      {
        key: "demo_student_code",
        value: "SV001",
        enabled: true,
        type: "default",
      },
    ],
    _postman_variable_scope: "environment",
  };
  await mkdir("postman", { recursive: true });
  await writeFile(
    candidate
      ? "postman/DLU_LMS_GROUP_39_20.postman_collection.json"
      : "postman/DLU_LMS_Student_Support.postman_collection.json",
    JSON.stringify(collection, null, 2) + "\n",
  );
  await writeFile(
    candidate
      ? "postman/DLU_LMS_Candidate.postman_environment.json"
      : "postman/DLU_LMS_Development.postman_environment.json",
    JSON.stringify(environment, null, 2) + "\n",
  );
  console.log("OPENAPI_AND_POSTMAN_EXPORT=PASS");
} finally {
  await app.close();
}
