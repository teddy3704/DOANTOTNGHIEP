import assert from "node:assert/strict";
import { Writable } from "node:stream";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { buildApp } from "../src/app.ts";
import type { AppConfig } from "../src/config.ts";
import { ApiFailure } from "../src/domain/learning-service.ts";
import {
  InnovationService,
  rankAttention,
  rankRecommendations,
} from "../src/domain/innovation.ts";
import { GroupStudentDataSource } from "../src/data/group-student-data-source.ts";
import { GroupTeacherDataSource } from "../src/data/group-teacher-data-source.ts";
import {
  assignment,
  assignmentStatus,
  attention,
  fixedNow,
  MemoryInnovationStore,
  progress,
  sources,
} from "./innovation-fixtures.ts";

// Synthetic isolated test doubles only. No credential, database or network I/O.
const config: AppConfig = {
  environment: "staging",
  port: 10000,
  host: "0.0.0.0",
  databaseUrl: "unused",
  demoAuthEnabled: true,
  databaseModel: "group_39_20",
};
const future = "2030-01-02T12:00:00.000Z";
const conflict = (e: unknown) =>
  e instanceof ApiFailure && e.statusCode === 409;
const invalid = (e: unknown) => e instanceof ApiFailure && e.statusCode === 400;

test("readiness: liveness remains available during database failure; readiness sanitizes the failure", async (t) => {
  const { student } = sources();
  student.health = async () => {
    throw new Error("synthetic-driver-private-marker");
  };
  const app = await buildApp(config, student, false);
  t.after(() => app.close());
  assert.equal((await app.inject("/health/live")).statusCode, 200);
  const result = await app.inject("/health");
  assert.equal(result.statusCode, 503);
  assert.equal(result.body.includes("synthetic-driver-private-marker"), false);
  assert.equal(result.json().error.code, "DATA_SOURCE_UNAVAILABLE");
});

test("group readiness checks required source and workflow relation-column surfaces, not merely SELECT1", async () => {
  let statement = "";
  const source = new GroupStudentDataSource({
    read: async (sql) => {
      statement = sql;
      return [];
    },
  });
  await source.health();
  for (const required of [
    "lms.assign",
    "derived.student_course_learning_items",
    "derived.teacher_student_monitoring",
    "app.study_plan_items",
    "app.teacher_interventions",
    "app.intervention_followups",
  ])
    assert.ok(statement.includes(required));
  assert.equal(/INSERT|UPDATE|DELETE|CREATE|ALTER|DROP/.test(statement), false);
});

test("logs: sanitized 415 stays4xx; status-only diagnostics distinguish unexpected500 without raw payload", async (t) => {
  let captured = "";
  const stream = new Writable({
    write(chunk, _encoding, done) {
      captured += chunk.toString();
      done();
    },
  });
  const { student, teacher } = sources();
  const app = await buildApp(
    config,
    student,
    { stream, level: "info" },
    teacher,
    new MemoryInnovationStore(),
  );
  t.after(() => app.close());
  app.get("/unexpected-test", async () => {
    throw new Error("synthetic-error-private-marker");
  });
  const result = await app.inject({
    method: "POST",
    url: "/api/v1/me/study-plan/items",
    headers: {
      "X-Demo-Student-Code": "SV001",
      "content-type": "application/synthetic-private-type",
      authorization: "Bearer synthetic-header-marker",
      cookie: "synthetic-cookie-marker",
    },
    payload: "synthetic-body-marker",
  });
  assert.equal(result.statusCode, 415);
  assert.equal(result.json().error.code, "UNSUPPORTED_MEDIA_TYPE");
  await app.inject("/unexpected-test");
  for (const marker of [
    "synthetic-private-type",
    "synthetic-error-private-marker",
    "synthetic-header-marker",
    "synthetic-cookie-marker",
    "synthetic-body-marker",
    "sv001@example.test",
  ])
    assert.equal(captured.includes(marker), false);
  app.log.info(
    {
      req: {
        url: "synthetic-serializer-marker",
        headers: { authorization: "synthetic-serializer-marker" },
        body: "synthetic-serializer-marker",
      },
      res: { body: "synthetic-serializer-marker" },
      err: new Error("synthetic-serializer-marker"),
      authorization: "synthetic-serializer-marker",
      password: "synthetic-serializer-marker",
      cookie: "synthetic-serializer-marker",
      token: "synthetic-serializer-marker",
      DATABASE_URL: "synthetic-serializer-marker",
    },
    "safe_redaction_test",
  );
  assert.equal(captured.includes("synthetic-serializer-marker"), false);
  const logs = captured
    .trim()
    .split("\n")
    .map((line) => JSON.parse(line));
  assert.ok(logs.some((log) => log.statusCode === 415 && log.level === 30));
  assert.ok(
    logs.some(
      (log) =>
        log.statusCode === 500 &&
        log.failureCode === "INTERNAL_ERROR" &&
        log.level === 50,
    ),
  );
  assert.ok(logs.every((log) => log.service === "dlu-lms-support-api"));
});

test("recommendations: duplicate rows deduplicate, conflicting source states fail closed and epoch deadline is not overdue", () => {
  const a = assignment();
  assert.equal(
    rankRecommendations(
      [a, a],
      [assignmentStatus(a), assignmentStatus(a)],
      [],
      [],
      fixedNow,
    ).length,
    1,
  );
  for (const statuses of [
    [assignmentStatus(a), assignmentStatus(a, "submitted")],
    [assignmentStatus(a, "submitted"), assignmentStatus(a)],
  ])
    assert.deepEqual(rankRecommendations([a], statuses, [], [], fixedNow), []);
  assert.deepEqual(
    rankRecommendations(
      [a, { ...a, dueAt: "2030-01-03T12:00:00.000Z" }],
      [assignmentStatus(a)],
      [],
      [],
      fixedNow,
    ),
    [],
  );
  const ambiguousProgress = rankRecommendations(
    [a],
    [assignmentStatus(a)],
    [progress("1", 25), progress("1", 75)],
    [],
    fixedNow,
  )[0]!;
  assert.equal(ambiguousProgress.priorityScore, 60);
  assert.equal(
    ambiguousProgress.reasons.some((reason) => reason.includes("Tiến độ")),
    false,
  );
  assert.deepEqual(
    rankRecommendations(
      [{ ...a, dueAt: null }],
      [assignmentStatus(a)],
      [],
      [],
      fixedNow,
    ),
    [],
  );
  assert.deepEqual(
    rankRecommendations(
      [{ ...a, dueAt: "1970-01-01T00:00:00.000Z" }],
      [assignmentStatus(a)],
      [],
      [],
      fixedNow,
    ),
    [],
  );
});

test("attention: zero tracked activities is not low progress; duplicate scoped monitoring fails closed", () => {
  const row = {
    ...attention(),
    riskLevel: "HIGH",
    progressPercent: 0,
    pendingTasks: 0,
    overdueTasks: 0,
    totalActivities: 0,
  };
  const result = rankAttention([row])[0]!;
  assert.equal(result.priorityScore, 0);
  assert.equal(
    result.reasons.some((r) => /dưới 50%/.test(r)),
    false,
  );
  assert.throws(
    () => rankAttention([row, row]),
    (e) => e instanceof ApiFailure && e.statusCode === 503,
  );
  assert.throws(
    () => rankAttention([{ ...row, totalActivities: Number.NaN }]),
    (e) => e instanceof ApiFailure && e.statusCode === 503,
  );
});

test("teacher roster and attention both recheck active learner role/enrolment with a batched query", async () => {
  const queries: string[] = [];
  const source = new GroupTeacherDataSource({
    read: async <T>(sql: string) => {
      queries.push(sql);
      return sql.includes("derived.teacher_student_monitoring")
        ? []
        : ([{ id: "1" }] as T[]);
    },
  });
  await source.students("GV001", "1");
  await source.attention("GV001");
  assert.equal(queries.length, 3);
  for (const sql of queries.filter((q) =>
    q.includes("derived.teacher_student_monitoring"),
  )) {
    assert.match(sql, /ue\.status=0/);
    assert.match(sql, /ue\.timeend>/);
    assert.match(sql, /r\.shortname='student'/);
    assert.match(sql, /total_tracked_activities/);
  }
});

test("roster risk badge uses the same known signals as inbox, never raw legacy risk or invented no-activity progress", async () => {
  const row = {
    ...attention(),
    riskLevel: "HIGH",
    progressPercent: 0,
    pendingTasks: 0,
    overdueTasks: 0,
    totalActivities: 0,
  };
  const source = new GroupTeacherDataSource({
    read: async <T>(sql: string) =>
      (sql.includes("derived.teacher_student_monitoring")
        ? [row]
        : [{ id: "1" }]) as T[],
  });
  const result = await source.students("GV001", "1");
  assert.equal(result![0]!.riskLevel, "LOW");
  assert.equal(result![0]!.progressPercent, 0);
  assert.equal(result![0]!.studentId, row.studentId);
});

test("no-deadline source contract preserves explicitnull rather than fabricating epoch; HTTP serializer accepts null", async (t) => {
  const statements: string[] = [];
  const database = {
    read: async <T>(sql: string) => {
      statements.push(sql);
      return [] as T[];
    },
  };
  await new GroupStudentDataSource(database).assignments("SV001");
  await new GroupTeacherDataSource(database).courses("GV001");
  assert.equal(
    statements
      .filter((sql) => sql.includes('AS "dueAt"'))
      .every((sql) => /to_timestamp\(nullif\(a\.duedate,0\)\)/.test(sql)),
    true,
  );
  const { student, teacher } = sources();
  student.assignments = async () => [{ ...assignment(), dueAt: null }];
  const app = await buildApp(
    config,
    student,
    false,
    teacher,
    new MemoryInnovationStore(),
  );
  t.after(() => app.close());
  const response = await app.inject({
    url: "/api/v1/me/assignments",
    headers: { "X-Demo-Student-Code": "SV001" },
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().data[0].dueAt, null);
  assert.deepEqual(
    (
      await app.inject({
        url: "/api/v1/me/recommendations",
        headers: { "X-Demo-Student-Code": "SV001" },
      })
    ).json().data,
    [],
  );
});

test("startup configuration failure emits a fixed structured event, not credentials, paths or stacks", () => {
  const result = spawnSync(
    process.execPath,
    [
      "--experimental-strip-types",
      fileURLToPath(new URL("../src/server.ts", import.meta.url)),
    ],
    {
      encoding: "utf8",
      env: {
        APP_ENV: "production",
        DATABASE_URL: "synthetic-bootstrap-private-marker",
        SystemRoot: process.env.SystemRoot ?? "",
      },
    },
  );
  assert.equal(result.status, 1);
  assert.equal(result.stdout, "");
  assert.equal(
    result.stderr.includes("synthetic-bootstrap-private-marker"),
    false,
  );
  assert.equal(result.stderr.includes("server.ts"), false);
  assert.equal(JSON.parse(result.stderr.trim()).event, "startup_failed");
});

test("workflow: handled plans cannot reopen/reschedule, but old schedules can be marked handled and deleted", async () => {
  const { student, teacher } = sources();
  const store = new MemoryInnovationStore();
  let now = fixedNow;
  const service = new InnovationService(student, teacher, store, () => now);
  const plan = await service.createPlan("SV001", {
    assignmentId: "20",
    scheduledStartAt: future,
  });
  now = new Date("2030-01-03T12:00:00.000Z");
  assert.equal(
    (await service.updatePlan("SV001", plan.id, { status: "handled" })).status,
    "handled",
  );
  await assert.rejects(
    service.updatePlan("SV001", plan.id, { status: "planned" }),
    conflict,
  );
  await assert.rejects(
    service.updatePlan("SV001", plan.id, {
      scheduledStartAt: "2030-01-04T12:00:00.000Z",
    }),
    conflict,
  );
  assert.deepEqual(await service.deletePlan("SV001", plan.id), {
    deleted: true,
  });
});

test("workflow: new follow-up time cannot be past; closing legacy-due records is allowed, closed history cannot reopen", async () => {
  const { student, teacher } = sources();
  const store = new MemoryInnovationStore();
  let now = fixedNow;
  const service = new InnovationService(student, teacher, store, () => now);
  const input = {
    courseId: "1",
    studentId: "201",
    title: "Theo dõi",
    note: "Nội dung hỗ trợ",
    actionType: "monitoring" as const,
    followUpAt: future,
  };
  await assert.rejects(
    service.createIntervention("GV001", {
      ...input,
      followUpAt: "2029-01-01T12:00:00.000Z",
    }),
    invalid,
  );
  const item = await service.createIntervention("GV001", input);
  await assert.rejects(
    service.updateIntervention("GV001", item.id, {
      followUpAt: "2029-01-01T12:00:00.000Z",
    }),
    invalid,
  );
  await assert.rejects(
    service.followup("GV001", item.id, {
      note: "Nội dung theo dõi",
      outcomeStatus: "following_up",
      nextFollowUpAt: "2029-01-01T12:00:00.000Z",
    }),
    invalid,
  );
  now = new Date("2030-01-03T12:00:00.000Z");
  assert.equal((await service.dueFollowups("GV001"))[0]!.id, item.id);
  assert.equal(
    (
      await service.updateIntervention("GV001", item.id, {
        note: "Ghi chú bổ sung",
        followUpAt: future,
      })
    ).note,
    "Ghi chú bổ sung",
  );
  await service.followup("GV001", item.id, {
    note: "Đã trao đổi",
    outcomeStatus: "following_up",
    nextFollowUpAt: future,
  });
  await assert.rejects(
    service.updateIntervention("GV001", item.id, { status: "open" }),
    conflict,
  );
  const closed = await service.updateIntervention("GV001", item.id, {
    status: "resolved",
    followUpAt: null,
  });
  assert.equal(closed.followUpAt, null);
  await assert.rejects(
    service.updateIntervention("GV001", item.id, { status: "open" }),
    conflict,
  );
  await assert.rejects(
    service.updateIntervention("GV001", item.id, { note: "Sửa lịch sử" }),
    conflict,
  );
});

test("workflow time compares absolute instants across Vietnam midnight without double conversion", async () => {
  const { student, teacher } = sources();
  const store = new MemoryInnovationStore();
  let now = new Date("2030-01-01T17:00:00.000Z"); // 00:00 in Vietnam on Jan2.
  const service = new InnovationService(student, teacher, store, () => now);
  const followUpAt = "2030-01-02T00:10:00+07:00";
  const record = await service.createIntervention("GV001", {
    courseId: "1",
    studentId: "201",
    title: "Theo dõi",
    note: "Nội dung hỗ trợ",
    actionType: "monitoring",
    followUpAt,
  });
  assert.deepEqual(await service.dueFollowups("GV001"), []);
  now = new Date("2030-01-01T17:11:00.000Z");
  assert.equal((await service.dueFollowups("GV001"))[0]!.id, record.id);
  const plan = await service.createPlan("SV001", {
    assignmentId: "20",
    scheduledStartAt: "2030-01-02T00:30:00+07:00",
  });
  assert.equal(
    Date.parse(plan.scheduledStartAt),
    Date.parse("2030-01-01T17:30:00.000Z"),
  );
});

test("HTTP date-time validation rejects impossible civil dates and missing timezone before Date.parse normalization", async (t) => {
  const { student, teacher } = sources();
  const app = await buildApp(
    config,
    student,
    false,
    teacher,
    new MemoryInnovationStore(),
  );
  t.after(() => app.close());
  for (const timestamp of [
    "2027-02-31T10:00:00Z",
    "2027-02-29T10:00:00Z",
    "2030-04-31T10:00:00Z",
    "2030-13-01T10:00:00Z",
    "2030-01-01T10:00:00",
    "2030-01-01T25:00:00Z",
  ]) {
    for (const [url, headers, payload] of [
      [
        "/api/v1/me/study-plan/items",
        { "X-Demo-Student-Code": "SV001" },
        { assignmentId: "20", scheduledStartAt: timestamp },
      ],
      [
        "/api/v1/me/teacher/interventions",
        { "X-Demo-Teacher-Code": "GV001" },
        {
          courseId: "1",
          studentId: "201",
          title: "Theo dõi",
          note: "Nội dung hỗ trợ",
          actionType: "monitoring",
          followUpAt: timestamp,
        },
      ],
    ] as const) {
      const response = await app.inject({
        method: "POST",
        url,
        headers,
        payload,
      });
      assert.equal(response.statusCode, 400);
      assert.equal(response.json().error.code, "INVALID_REQUEST");
    }
  }
  const validLeap = await app.inject({
    method: "POST",
    url: "/api/v1/me/study-plan/items",
    headers: { "X-Demo-Student-Code": "SV001" },
    payload: { assignmentId: "20", scheduledStartAt: "2032-02-29T10:00:00Z" },
  });
  assert.equal(validLeap.statusCode, 201);
});
