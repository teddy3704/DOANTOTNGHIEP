import assert from "node:assert/strict";
import test from "node:test";
import { randomUUID } from "node:crypto";
import {
  InnovationService,
  rankAttention,
  rankRecommendations,
} from "../src/domain/innovation.ts";
import { ApiFailure } from "../src/domain/learning-service.ts";
import {
  assignment,
  assignmentStatus,
  attention,
  fixedNow,
  MemoryInnovationStore,
  progress,
  sources,
} from "./innovation-fixtures.ts";
const futureStart = "2030-01-01T12:30:00.000Z";

test("recommendations: actual outstanding states only; unknown/submitted/graded never infer a task", () => {
  const states = [
    "missing",
    "not_submitted",
    "draft",
    "returned_for_resubmission",
    "graded",
    "submitted",
    "late",
  ] as const;
  const assignments = states.map((_, i) => assignment(String(i + 1)));
  assignments.push(assignment("99"));
  const rows = rankRecommendations(
    assignments,
    states.map((s, i) => assignmentStatus(assignments[i]!, s)),
    [],
    [],
    fixedNow,
  );
  assert.deepEqual(rows.map((r) => r.submissionStatus).sort(), [
    "draft",
    "missing",
    "not_submitted",
    "returned_for_resubmission",
  ]);
  assert.equal(
    rows.some((r) => r.assignmentId === "99"),
    false,
  );
});

test("recommendations: deadline score boundaries and human-readable reasons are deterministic", () => {
  const hours = [-1, 0, 24, 24.01, 72, 72.01, 168, 168.01];
  const assignments = hours.map((h, i) => assignment(String(i + 1), h));
  const rows = rankRecommendations(
    assignments,
    assignments.map((a) => assignmentStatus(a)),
    [],
    [],
    fixedNow,
  );
  const expected = [70, 60, 60, 45, 45, 25, 25, 10];
  for (let i = 0; i < assignments.length; i++) {
    const row = rows.find((r) => r.assignmentId === String(i + 1))!;
    assert.equal(row.priorityScore, expected[i]);
    assert.equal(row.reasons.length, 1);
    assert.equal(row.recommendedDurationMinutes, 45);
  }
  assert.match(rows[0]!.reasons[0]!, /Đã qua hạn/);
  assert.deepEqual(
    rows,
    rankRecommendations(
      [...assignments].reverse(),
      assignments.map((a) => assignmentStatus(a)),
      [],
      [],
      fixedNow,
    ),
  );
});

test("recommendations: draft/returned/known low activity progress contribute; zero/unknown metrics do not", () => {
  const a = assignment();
  assert.equal(
    rankRecommendations(
      [a],
      [assignmentStatus(a, "draft")],
      [progress("1", 49)],
      [],
      fixedNow,
    )[0]!.priorityScore,
    80,
  );
  assert.equal(
    rankRecommendations(
      [a],
      [assignmentStatus(a, "returned_for_resubmission")],
      [progress("1", 25)],
      [],
      fixedNow,
    )[0]!.priorityScore,
    90,
  );
  for (const p of [
    progress("1", 50),
    progress("1", 0, 0),
    progress("1", Number.NaN),
    { ...progress(), progressPercent: null },
  ]) {
    assert.equal(
      rankRecommendations(
        [a],
        [assignmentStatus(a)],
        [p as ReturnType<typeof progress>],
        [],
        fixedNow,
      )[0]!.priorityScore,
      60,
    );
  }
  const overdue = assignment("20", -1);
  assert.equal(
    rankRecommendations(
      [overdue],
      [assignmentStatus(overdue, "returned_for_resubmission")],
      [progress("1", 25)],
      [],
      fixedNow,
    )[0]!.priorityScore,
    100,
  );
});

test("recommendations: stable same-score/date tie, invalid date excluded, composite course/status matching", () => {
  const assignments = [
    assignment("30"),
    assignment("20"),
    { ...assignment("40"), dueAt: "not-a-date" },
  ];
  const rows = rankRecommendations(
    assignments,
    assignments.map((a) => assignmentStatus(a)),
    [],
    [],
    fixedNow,
  );
  assert.deepEqual(
    rows.map((r) => r.assignmentId),
    ["20", "30"],
  );
  assert.deepEqual(
    rankRecommendations(
      [assignment()],
      [{ ...assignmentStatus(assignment()), courseCode: "OTHER" }],
      [],
      [],
      fixedNow,
    ),
    [],
  );
});

test("attention: scores use actual metrics, tie order and explanatory non-priority state", () => {
  const monitored = { ...attention(), riskLevel: "HIGH" };
  const rows = rankAttention([
    {
      ...monitored,
      courseId: "2",
      studentId: "202",
      pendingTasks: 10,
      overdueTasks: 10,
    },
    { ...monitored },
    { ...monitored, studentId: "200" },
    {
      ...monitored,
      studentId: "203",
      progressPercent: 50,
      overdueTasks: 0,
      pendingTasks: 0,
    },
  ]);
  assert.equal(rows[0]!.priorityScore, 100);
  assert.deepEqual(
    rows.slice(1, 3).map((r) => r.studentId),
    ["200", "201"],
  );
  assert.equal(rows.at(-1)!.priorityScore, 0);
  assert.match(rows.at(-1)!.reasons[0]!, /Chưa có dấu hiệu/);
  assert.equal(
    rows[0]!.reasons.some((reason) => /AI|prediction|inactiv/i.test(reason)),
    false,
  );
});

test("attention: null/non-finite/negative metrics fail closed rather than invent zero progress", () => {
  for (const malformed of [
    { progressPercent: null },
    { progressPercent: Number.NaN },
    { progressPercent: 101 },
    { pendingTasks: -1 },
    { overdueTasks: 1.5 },
  ]) {
    assert.throws(
      () =>
        rankAttention([
          { ...attention(), riskLevel: "LOW", ...malformed } as Parameters<
            typeof rankAttention
          >[0][number],
        ]),
      (e) => e instanceof ApiFailure && e.statusCode === 503,
    );
  }
});

test("study plan service: persists, postpones, handles and deletes own plan without modifying official source", async () => {
  const { student, teacher } = sources();
  const store = new MemoryInnovationStore();
  const service = new InnovationService(
    student,
    teacher,
    store,
    () => fixedNow,
  );
  const before = await student.assignmentStatus("SV001");
  const item = await service.createPlan("SV001", {
    assignmentId: "20",
    scheduledStartAt: futureStart,
  });
  assert.equal((await service.recommendations("SV001"))[0]!.planned, true);
  await assert.rejects(
    service.createPlan("SV001", {
      assignmentId: "20",
      scheduledStartAt: futureStart,
    }),
    (e) => e instanceof ApiFailure && e.statusCode === 409,
  );
  const restored = new InnovationService(
    student,
    teacher,
    store,
    () => fixedNow,
  );
  assert.deepEqual(await restored.plans("SV001"), [item]);
  assert.deepEqual(await restored.plans("SV002"), []);
  await assert.rejects(
    restored.updatePlan("SV002", item.id, { notes: "cross-user" }),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  await assert.rejects(
    restored.deletePlan("SV002", item.id),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  const postponed = await restored.updatePlan("SV001", item.id, {
    scheduledStartAt: "2030-01-02T12:00:00.000Z",
    estimatedMinutes: 60,
  });
  assert.equal(postponed.estimatedMinutes, 60);
  assert.equal(postponed.scheduledStartAt, "2030-01-02T12:00:00.000Z");
  await restored.updatePlan("SV001", item.id, { status: "handled" });
  assert.deepEqual(await restored.recommendations("SV001"), []);
  assert.deepEqual(await student.assignmentStatus("SV001"), before);
  await restored.deletePlan("SV001", item.id);
  assert.equal((await restored.recommendations("SV001"))[0]!.planned, false);
  await assert.rejects(
    restored.createPlan("SV001", {
      assignmentId: "30",
      scheduledStartAt: futureStart,
    }),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
});

test("plan service: revoked assignment scope hides old record and blocks update/delete", async () => {
  const { student, teacher } = sources();
  const service = new InnovationService(
    student,
    teacher,
    new MemoryInnovationStore(),
    () => fixedNow,
  );
  const item = await service.createPlan("SV001", {
    assignmentId: "20",
    scheduledStartAt: futureStart,
  });
  student.assignments = async () => [];
  assert.deepEqual(await service.plans("SV001"), []);
  await assert.rejects(
    service.updatePlan("SV001", item.id, { notes: "revoked" }),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  await assert.rejects(
    service.deletePlan("SV001", item.id),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
});

test("study plan service: scheduling in the past, at now or invalid fails without losing an existing plan", async () => {
  const { student, teacher } = sources();
  const service = new InnovationService(
    student,
    teacher,
    new MemoryInnovationStore(),
    () => fixedNow,
  );
  for (const scheduledStartAt of [
    "2029-12-31T12:00:00.000Z",
    fixedNow.toISOString(),
    "not-date",
  ])
    await assert.rejects(
      service.createPlan("SV001", { assignmentId: "20", scheduledStartAt }),
      (e) => e instanceof ApiFailure && e.statusCode === 400,
    );
  const item = await service.createPlan("SV001", {
    assignmentId: "20",
    scheduledStartAt: futureStart,
  });
  for (const scheduledStartAt of [
    "2029-12-31T12:00:00.000Z",
    fixedNow.toISOString(),
    "not-date",
  ])
    await assert.rejects(
      service.updatePlan("SV001", item.id, { scheduledStartAt }),
      (e) => e instanceof ApiFailure && e.statusCode === 400,
    );
  assert.equal(
    (await service.plans("SV001"))[0]!.scheduledStartAt,
    futureStart,
  );
});

test("intervention lifecycle: actual baseline/current/followup snapshots, due time, isolation and closure", async () => {
  const { student, teacher, setMetrics } = sources();
  const store = new MemoryInnovationStore();
  const service = new InnovationService(
    student,
    teacher,
    store,
    () => fixedNow,
  );
  const input = {
    courseId: "1",
    studentId: "201",
    title: "Theo dõi tiến độ",
    note: "Đã trao đổi nội dung cần học",
    actionType: "contacted" as const,
    followUpAt: fixedNow.toISOString(),
  };
  const created = await service.createIntervention("GV001", input);
  assert.deepEqual(created.baseline, {
    progressPercent: 25,
    pendingTasks: 2,
    overdueTasks: 1,
  });
  assert.equal((await service.dueFollowups("GV001"))[0]!.id, created.id);
  assert.deepEqual(await service.interventions("GV002"), []);
  await assert.rejects(
    service.intervention("GV002", created.id),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  await assert.rejects(
    service.followup("GV002", created.id, {
      note: "cross-owner",
      outcomeStatus: "resolved",
    }),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  await assert.rejects(
    service.createIntervention("GV001", input),
    (e) => e instanceof ApiFailure && e.statusCode === 409,
  );
  await assert.rejects(
    service.createIntervention("GV001", {
      ...input,
      courseId: "2",
      studentId: "202",
    }),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  setMetrics({
    ...attention(),
    progressPercent: 50,
    pendingTasks: 1,
    overdueTasks: 0,
  });
  const next = await service.followup("GV001", created.id, {
    note: "Xem lại số liệu sau trao đổi",
    outcomeStatus: "following_up",
    nextFollowUpAt: "2030-01-02T12:00:00.000Z",
  });
  assert.equal(next.baseline.progressPercent, 25);
  assert.equal(next.current.progressPercent, 50);
  assert.equal(next.followups[0]!.progressPercent, 50);
  assert.deepEqual(await service.dueFollowups("GV001"), []);
  const restored = new InnovationService(
    student,
    teacher,
    store,
    () => fixedNow,
  );
  const closed = await restored.followup("GV001", created.id, {
    note: "Hoàn tất lượt hỗ trợ",
    outcomeStatus: "resolved",
  });
  assert.equal(closed.status, "resolved");
  assert.equal(closed.followUpAt, null);
  assert.equal(closed.followups.length, 2);
  await assert.rejects(
    restored.followup("GV001", created.id, {
      note: "Không được thêm",
      outcomeStatus: "following_up",
    }),
    (e) => e instanceof ApiFailure && e.statusCode === 409,
  );
  assert.equal(
    (await restored.createIntervention("GV001", input)).status,
    "open",
  );
});

test("intervention service: revoked membership removes history, unknown IDs fail, sources sanitize errors", async () => {
  const { student, teacher } = sources();
  const store = new MemoryInnovationStore();
  const service = new InnovationService(
    student,
    teacher,
    store,
    () => fixedNow,
  );
  const created = await service.createIntervention("GV001", {
    courseId: "1",
    studentId: "201",
    title: "Theo dõi",
    note: "Nội dung hỗ trợ",
    actionType: "monitoring",
    followUpAt: null,
  });
  teacher.attention = async () => [];
  assert.deepEqual(await service.interventions("GV001"), []);
  await assert.rejects(
    service.updateIntervention("GV001", created.id, { title: "Mới" }),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  await assert.rejects(
    service.intervention("GV001", randomUUID()),
    (e) => e instanceof ApiFailure && e.statusCode === 404,
  );
  const error = new Error("synthetic-private-driver-detail");
  await assert.rejects(
    service.safe(async () => {
      throw error;
    }),
    (e) =>
      e instanceof ApiFailure &&
      e.statusCode === 503 &&
      !e.message.includes(error.message),
  );
});
