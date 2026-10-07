import assert from "node:assert/strict";
import { Writable } from "node:stream";
import test, { type TestContext } from "node:test";
import { randomUUID } from "node:crypto";
import { buildApp } from "../src/app.ts";
import type { AppConfig } from "../src/config.ts";
import { MemoryInnovationStore, sources } from "./innovation-fixtures.ts";

const config: AppConfig = {
  environment: "staging",
  port: 10000,
  host: "0.0.0.0",
  databaseUrl: "not-used-by-mock",
  databaseModel: "group_39_20",
  demoAuthEnabled: true,
};
const studentHeaders = { "X-Demo-Student-Code": "SV001" };
const teacherHeaders = { "X-Demo-Teacher-Code": "GV001" };
const planBody = {
  assignmentId: "20",
  scheduledStartAt: "2030-01-01T12:00:00.000Z",
  estimatedMinutes: 45,
  notes: "Đọc bài trước khi làm",
};
const interventionBody = {
  courseId: "1",
  studentId: "201",
  title: "Trao đổi kế hoạch",
  note: "Cần xem lại bài tập quá hạn",
  actionType: "contacted",
  followUpAt: "2030-01-01T12:00:00.000Z",
};
const planPath = "/api/v1/me/study-plan/items";
const interventionPath = "/api/v1/me/teacher/interventions";

async function setup(t: TestContext, enabled = true) {
  const source = sources();
  const store = new MemoryInnovationStore();
  const app = await buildApp(
    { ...config, demoAuthEnabled: enabled },
    source.student,
    false,
    source.teacher,
    store,
  );
  t.after(() => app.close());
  return { app, source, store };
}

test("workflow identity: missing, wrong-role, mixed, unknown and disabled identities all fail closed", async (t) => {
  const { app } = await setup(t);
  for (const path of [
    "/api/v1/me/recommendations",
    "/api/v1/me/study-plan",
    "/api/v1/me/teacher/attention",
    interventionPath,
    "/api/v1/me/teacher/followups",
  ])
    assert.equal((await app.inject(path)).statusCode, 401);
  for (const headers of [
    teacherHeaders,
    { ...studentHeaders, ...teacherHeaders },
    { "X-Demo-Student-Code": "SV999" },
  ])
    assert.equal(
      (await app.inject({ url: "/api/v1/me/recommendations", headers }))
        .statusCode,
      401,
    );
  for (const headers of [
    studentHeaders,
    { ...studentHeaders, ...teacherHeaders },
    { "X-Demo-Teacher-Code": "GV999" },
  ])
    assert.equal(
      (await app.inject({ url: "/api/v1/me/teacher/attention", headers }))
        .statusCode,
      401,
    );
  const disabled = await setup(t, false);
  assert.equal(
    (
      await disabled.app.inject({
        url: "/api/v1/me/recommendations",
        headers: studentHeaders,
      })
    ).statusCode,
    401,
  );
  assert.equal(
    (
      await disabled.app.inject({
        url: "/api/v1/me/teacher/attention",
        headers: teacherHeaders,
      })
    ).statusCode,
    401,
  );
});

test("workflow HTTP: canonical server recommendation feeds persisted personal planning; no academic mutation", async (t) => {
  const { app, source } = await setup(t);
  const academicBefore = await source.student.assignmentStatus("SV001");
  const recommendations = await app.inject({
    url: "/api/v1/me/recommendations",
    headers: studentHeaders,
  });
  assert.equal(recommendations.statusCode, 200);
  assert.equal(recommendations.json().meta.count, 1);
  const response = await app.inject({
    method: "POST",
    url: planPath,
    headers: studentHeaders,
    payload: planBody,
  });
  assert.equal(response.statusCode, 201);
  const item = response.json().data;
  assert.equal(item.title, recommendations.json().data[0].assignmentName);
  assert.equal(item.status, "planned");
  assert.equal(item.estimatedMinutes, 45);
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: planPath,
        headers: studentHeaders,
        payload: planBody,
      })
    ).statusCode,
    409,
  );
  const list = await app.inject({
    url: "/api/v1/me/study-plan",
    headers: studentHeaders,
  });
  assert.equal(list.json().data[0].id, item.id);
  const patched = await app.inject({
    method: "PATCH",
    url: `${planPath}/${item.id}`,
    headers: studentHeaders,
    payload: { status: "handled", notes: "Đã xử lý kế hoạch cá nhân" },
  });
  assert.equal(patched.statusCode, 200);
  assert.equal(patched.json().data.status, "handled");
  assert.deepEqual(
    (
      await app.inject({
        url: "/api/v1/me/recommendations",
        headers: studentHeaders,
      })
    ).json().data,
    [],
  );
  assert.deepEqual(
    await source.student.assignmentStatus("SV001"),
    academicBefore,
  );
  const deleted = await app.inject({
    method: "DELETE",
    url: `${planPath}/${item.id}`,
    headers: studentHeaders,
  });
  assert.equal(deleted.statusCode, 200);
  assert.deepEqual(deleted.json().data, { deleted: true });
  assert.deepEqual(
    (
      await app.inject({
        url: "/api/v1/me/study-plan",
        headers: studentHeaders,
      })
    ).json().data,
    [],
  );
});

test("workflow scope: another student cannot read, patch, delete or schedule a foreign assignment", async (t) => {
  const { app } = await setup(t);
  const other = { "X-Demo-Student-Code": "SV002" };
  const item = (
    await app.inject({
      method: "POST",
      url: planPath,
      headers: studentHeaders,
      payload: planBody,
    })
  ).json().data;
  assert.deepEqual(
    (await app.inject({ url: "/api/v1/me/study-plan", headers: other })).json()
      .data,
    [],
  );
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: planPath,
        headers: other,
        payload: planBody,
      })
    ).statusCode,
    404,
  );
  const forbidden = await app.inject({
    method: "PATCH",
    url: `${planPath}/${item.id}`,
    headers: other,
    payload: { notes: "cross-user" },
  });
  const missing = await app.inject({
    method: "PATCH",
    url: `${planPath}/${randomUUID()}`,
    headers: other,
    payload: { notes: "cross-user" },
  });
  assert.equal(forbidden.statusCode, 404);
  assert.deepEqual(forbidden.json(), missing.json());
  assert.equal(
    (
      await app.inject({
        method: "DELETE",
        url: `${planPath}/${item.id}`,
        headers: other,
      })
    ).statusCode,
    404,
  );
  assert.equal(
    (
      await app.inject({
        url: "/api/v1/me/study-plan",
        headers: studentHeaders,
      })
    ).json().data[0].notes,
    planBody.notes,
  );
});

test("workflow validation: rejects ownership/source spoofing, invalid duration/date/status, empty patches and query overrides", async (t) => {
  const { app } = await setup(t);
  for (const changes of [
    { ownerUserId: "202" },
    { priorityScore: 100 },
    { reasons: ["client risk"] },
    { assignmentId: "0" },
    { estimatedMinutes: 4 },
    { estimatedMinutes: 481 },
    { estimatedMinutes: 5.5 },
    { scheduledStartAt: "not-date" },
    { notes: "a".repeat(501) },
  ]) {
    const result = await app.inject({
      method: "POST",
      url: planPath,
      headers: studentHeaders,
      payload: { ...planBody, ...changes },
    });
    assert.equal(result.statusCode, 400);
    assert.equal(result.json().error.code, "INVALID_REQUEST");
  }
  const item = (
    await app.inject({
      method: "POST",
      url: planPath,
      headers: studentHeaders,
      payload: planBody,
    })
  ).json().data;
  for (const payload of [{}, { status: "submitted" }, { ownerUserId: "202" }])
    assert.equal(
      (
        await app.inject({
          method: "PATCH",
          url: `${planPath}/${item.id}`,
          headers: studentHeaders,
          payload,
        })
      ).statusCode,
      400,
    );
  for (const id of ["not-uuid", "1", "..%2Fgrades"])
    assert.equal(
      (
        await app.inject({
          method: "PATCH",
          url: `${planPath}/${id}`,
          headers: studentHeaders,
          payload: { notes: "note" },
        })
      ).statusCode,
      400,
    );
  assert.equal(
    (
      await app.inject({
        url: "/api/v1/me/recommendations?studentCode=SV002",
        headers: studentHeaders,
      })
    ).statusCode,
    400,
  );
});

test("teacher workflow: scoped create/detail/update/followup/history/resolution are genuine state changes", async (t) => {
  const { app, source } = await setup(t);
  const attention = await app.inject({
    url: "/api/v1/me/teacher/attention",
    headers: teacherHeaders,
  });
  assert.equal(attention.statusCode, 200);
  assert.equal(attention.json().meta.count, 1);
  const created = await app.inject({
    method: "POST",
    url: interventionPath,
    headers: teacherHeaders,
    payload: interventionBody,
  });
  assert.equal(created.statusCode, 201);
  const item = created.json().data;
  assert.equal(item.baseline.progressPercent, 25);
  assert.equal(item.status, "open");
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: interventionPath,
        headers: teacherHeaders,
        payload: interventionBody,
      })
    ).statusCode,
    409,
  );
  assert.deepEqual(
    (
      await app.inject({
        url: "/api/v1/me/teacher/followups",
        headers: teacherHeaders,
      })
    ).json().data,
    [],
  );
  const patched = await app.inject({
    method: "PATCH",
    url: `${interventionPath}/${item.id}`,
    headers: teacherHeaders,
    payload: { title: "Kế hoạch theo dõi mới", actionType: "monitoring" },
  });
  assert.equal(patched.statusCode, 200);
  assert.equal(patched.json().data.actionType, "monitoring");
  source.setMetrics({
    ...attention.json().data[0],
    progressPercent: 60,
    pendingTasks: 1,
    overdueTasks: 0,
  });
  const followed = await app.inject({
    method: "POST",
    url: `${interventionPath}/${item.id}/followups`,
    headers: teacherHeaders,
    payload: {
      note: "Đã kiểm tra lượt hỗ trợ",
      outcomeStatus: "following_up",
      nextFollowUpAt: "2031-01-01T12:00:00.000Z",
    },
  });
  assert.equal(followed.statusCode, 201);
  assert.equal(followed.json().data.baseline.progressPercent, 25);
  assert.equal(followed.json().data.current.progressPercent, 60);
  assert.equal(followed.json().data.followups[0].progressPercent, 60);
  assert.deepEqual(
    (
      await app.inject({
        url: "/api/v1/me/teacher/followups",
        headers: teacherHeaders,
      })
    ).json().data,
    [],
  );
  const closed = await app.inject({
    method: "POST",
    url: `${interventionPath}/${item.id}/followups`,
    headers: teacherHeaders,
    payload: { note: "Đã kết thúc theo dõi", outcomeStatus: "resolved" },
  });
  assert.equal(closed.statusCode, 201);
  assert.equal(closed.json().data.followUpAt, null);
  const detail = await app.inject({
    url: `${interventionPath}/${item.id}`,
    headers: teacherHeaders,
  });
  assert.equal(detail.statusCode, 200);
  assert.equal(detail.json().data.followups.length, 2);
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: `${interventionPath}/${item.id}/followups`,
        headers: teacherHeaders,
        payload: { note: "closed", outcomeStatus: "following_up" },
      })
    ).statusCode,
    409,
  );
});

test("teacher scope: wrong-course/student access and another teacher's record are indistinguishable from missing", async (t) => {
  const { app } = await setup(t);
  const other = { "X-Demo-Teacher-Code": "GV002" };
  const item = (
    await app.inject({
      method: "POST",
      url: interventionPath,
      headers: teacherHeaders,
      payload: interventionBody,
    })
  ).json().data;
  assert.deepEqual(
    (await app.inject({ url: interventionPath, headers: other })).json().data,
    [],
  );
  const denied = await app.inject({
    url: `${interventionPath}/${item.id}`,
    headers: other,
  });
  const missing = await app.inject({
    url: `${interventionPath}/${randomUUID()}`,
    headers: other,
  });
  assert.equal(denied.statusCode, 404);
  assert.deepEqual(denied.json(), missing.json());
  assert.equal(
    (
      await app.inject({
        method: "PATCH",
        url: `${interventionPath}/${item.id}`,
        headers: other,
        payload: { note: "wrong-owner" },
      })
    ).statusCode,
    404,
  );
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: `${interventionPath}/${item.id}/followups`,
        headers: other,
        payload: { note: "wrong-owner", outcomeStatus: "resolved" },
      })
    ).statusCode,
    404,
  );
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: interventionPath,
        headers: teacherHeaders,
        payload: { ...interventionBody, courseId: "2", studentId: "202" },
      })
    ).statusCode,
    404,
  );
});

test("teacher validation: note/title constraints, scope IDs, statuses and server-owned snapshots cannot be spoofed", async (t) => {
  const { app } = await setup(t);
  for (const change of [
    { title: "   " },
    { note: "\n\t" },
    { title: "a".repeat(121) },
    { actionType: "graded" },
    { followUpAt: "bad" },
    { ownerTeacherId: "102" },
    { baseline: { progressPercent: 100 } },
  ])
    assert.equal(
      (
        await app.inject({
          method: "POST",
          url: interventionPath,
          headers: teacherHeaders,
          payload: { ...interventionBody, ...change },
        })
      ).statusCode,
      400,
    );
  const item = (
    await app.inject({
      method: "POST",
      url: interventionPath,
      headers: teacherHeaders,
      payload: interventionBody,
    })
  ).json().data;
  for (const payload of [
    { note: "" },
    { note: "history", outcomeStatus: "open" },
    { note: "history", outcomeStatus: "resolved", progressPercent: 100 },
    {
      note: "history",
      outcomeStatus: "following_up",
      nextFollowUpAt: "invalid",
    },
  ])
    assert.equal(
      (
        await app.inject({
          method: "POST",
          url: `${interventionPath}/${item.id}/followups`,
          headers: teacherHeaders,
          payload,
        })
      ).statusCode,
      400,
    );
});

test("workflow errors: source/store failures sanitize details and large request bodies remain bounded", async (t) => {
  const { app, source, store } = await setup(t);
  source.student.assignments = async () => {
    throw new Error("synthetic-private-db-marker");
  };
  const fail = await app.inject({
    url: "/api/v1/me/recommendations",
    headers: studentHeaders,
  });
  assert.equal(fail.statusCode, 503);
  assert.equal(fail.body.includes("synthetic-private-db-marker"), false);
  store.interventions = async () => {
    throw new Error("synthetic-private-db-marker");
  };
  assert.equal(
    (await app.inject({ url: interventionPath, headers: teacherHeaders }))
      .statusCode,
    503,
  );
  const oversized = await app.inject({
    method: "POST",
    url: planPath,
    headers: studentHeaders,
    payload: { ...planBody, notes: "a".repeat(9000) },
  });
  assert.equal(oversized.statusCode, 413);
  assert.equal(oversized.json().error.code, "REQUEST_TOO_LARGE");
  assert.equal(oversized.body.includes("aaaa"), false);
});

test("public staging writes are rate bounded per actor; other actors are not charged", async (t) => {
  const { app } = await setup(t);
  const item = (
    await app.inject({
      method: "POST",
      url: planPath,
      headers: studentHeaders,
      payload: planBody,
    })
  ).json().data;
  for (let i = 0; i < 29; i++)
    assert.equal(
      (
        await app.inject({
          method: "PATCH",
          url: `${planPath}/${item.id}`,
          headers: studentHeaders,
          payload: { notes: `Lần ${i}` },
        })
      ).statusCode,
      200,
    );
  const limited = await app.inject({
    method: "PATCH",
    url: `${planPath}/${item.id}`,
    headers: studentHeaders,
    payload: { notes: "beyond-limit" },
  });
  assert.equal(limited.statusCode, 429);
  assert.equal(limited.json().error.code, "SUPPORT_RATE_LIMITED");
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: planPath,
        headers: { "X-Demo-Student-Code": "SV002" },
        payload: { ...planBody, assignmentId: "30" },
      })
    ).statusCode,
    201,
  );
});

test("innovation OpenAPI includes app-owned writes only; submitted notes/errors are absent from status-only logs", async (t) => {
  let captured = "";
  const stream = new Writable({
    write(chunk, _encoding, done) {
      captured += chunk.toString();
      done();
    },
  });
  const source = sources();
  const store = new MemoryInnovationStore();
  const app = await buildApp(
    config,
    source.student,
    { stream, level: "info" },
    source.teacher,
    store,
  );
  t.after(() => app.close());
  const spec = (await app.inject("/openapi.json")).json();
  const mutations = Object.entries(
    spec.paths as Record<string, Record<string, unknown>>,
  ).flatMap(([path, methods]) =>
    Object.keys(methods)
      .filter((m) => m !== "get")
      .map((method) => ({ path, method })),
  );
  assert.equal(mutations.length, 6);
  assert.equal(
    mutations.every(
      ({ path }) =>
        path.includes("/study-plan/items") ||
        path.includes("/teacher/interventions"),
    ),
    true,
  );
  assert.equal(spec.paths["/api/v1/me/grades"].patch, undefined);
  await app.inject({
    method: "POST",
    url: interventionPath,
    headers: teacherHeaders,
    payload: { ...interventionBody, note: "synthetic-private-note-marker" },
  });
  store.interventions = async () => {
    throw new Error("synthetic-private-error-marker");
  };
  await app.inject({ url: interventionPath, headers: teacherHeaders });
  await app.inject({
    url: "/api/v1/me/recommendations?secret=synthetic-private-query-marker",
    headers: studentHeaders,
  });
  assert.match(captured, /request_completed/);
  for (const marker of [
    "synthetic-private-note-marker",
    "synthetic-private-error-marker",
    "synthetic-private-query-marker",
    "gv001@example.test",
  ])
    assert.equal(captured.includes(marker), false);
});
