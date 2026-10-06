import assert from "node:assert/strict";
import test from "node:test";
import type pg from "pg";
import type { QueryResultRow } from "pg";
import { readFileSync } from "node:fs";
import { randomUUID } from "node:crypto";
import {
  PostgresAppDatabase,
  PostgresInnovationStore,
  type AppDatabase,
  type AppQuery,
} from "../src/data/innovation-store.ts";
import { rankRecommendations } from "../src/domain/innovation.ts";
import {
  assignment,
  assignmentStatus,
  attention,
  fixedNow,
} from "./innovation-fixtures.ts";

class RecordingDatabase implements AppDatabase {
  queries: { sql: string; values: readonly unknown[] }[] = [];
  response: (sql: string) => QueryResultRow[] = () => [];
  async transaction<T>(operation: (query: AppQuery) => Promise<T>): Promise<T> {
    return operation({
      query: async <R extends QueryResultRow>(
        sql: string,
        values: readonly unknown[] = [],
      ) => {
        this.queries.push({ sql, values });
        return this.response(sql) as R[];
      },
    });
  }
}
class FakeClient {
  queries: { sql: string; values?: unknown[] }[] = [];
  releases: (boolean | undefined)[] = [];
  failures = new Set<string>();
  async query(sql: string, values?: unknown[]) {
    this.queries.push(values === undefined ? { sql } : { sql, values });
    if (this.failures.has(sql)) throw new Error("synthetic-driver-detail");
    return { rows: sql === "SELECT 1" ? [{ value: 1 }] : [] };
  }
  release(discard?: boolean) {
    this.releases.push(discard);
  }
}
function transactionFixture() {
  const client = new FakeClient();
  const pool = { connect: async () => client } as unknown as pg.Pool;
  return { client, db: new PostgresAppDatabase(pool) };
}

test("app writer transaction: short timeout/lock bound, parameter copies, commit and release", async () => {
  const { db, client } = transactionFixture();
  const values = Object.freeze(["synthetic-value"]);
  assert.deepEqual(await db.transaction((q) => q.query("SELECT 1", values)), [
    { value: 1 },
  ]);
  assert.deepEqual(
    client.queries.map((q) => q.sql),
    [
      "BEGIN",
      "SET LOCAL statement_timeout = '10s'",
      "SET LOCAL lock_timeout = '5s'",
      "SELECT 1",
      "COMMIT",
    ],
  );
  assert.notEqual(client.queries[3]!.values, values);
  assert.deepEqual(client.queries[3]!.values, values);
  assert.deepEqual(client.releases, [false]);
});

test("app writer transaction: failed query/setup/commit rollback once; failed rollback discards client", async () => {
  for (const failure of [
    "BEGIN",
    "SET LOCAL statement_timeout = '10s'",
    "SET LOCAL lock_timeout = '5s'",
    "SELECT 1",
    "COMMIT",
  ]) {
    const { db, client } = transactionFixture();
    client.failures.add(failure);
    await assert.rejects(
      db.transaction((q) => q.query("SELECT 1")),
      /synthetic-driver-detail/,
    );
    assert.equal(client.queries.at(-1)!.sql, "ROLLBACK");
    assert.deepEqual(client.releases, [false]);
  }
  const { db, client } = transactionFixture();
  client.failures.add("SELECT 1");
  client.failures.add("ROLLBACK");
  await assert.rejects(
    db.transaction((q) => q.query("SELECT 1")),
    /synthetic-driver-detail/,
  );
  assert.deepEqual(client.releases, [true]);
});

test("innovation store: fixed actor allowlist rejects arbitrary IDs or wrong role without a database request", async () => {
  const db = new RecordingDatabase();
  const store = new PostgresInnovationStore(db);
  const a = assignment();
  const recommendation = rankRecommendations(
    [a],
    [assignmentStatus(a)],
    [],
    [],
    fixedNow,
  )[0]!;
  for (const code of ["201", "SV999", "GV001", "SV001' OR 1=1--"]) {
    assert.deepEqual(await store.plans(code), []);
    assert.equal(
      await store.createPlan(code, recommendation, {
        assignmentId: a.assignmentId,
        scheduledStartAt: fixedNow.toISOString(),
      }),
      null,
    );
    assert.equal(
      await store.updatePlan(code, randomUUID(), { notes: "note" }),
      null,
    );
    assert.equal(await store.deletePlan(code, randomUUID()), false);
  }
  for (const code of ["101", "GV999", "SV001"]) {
    assert.deepEqual(await store.interventions(code), []);
    assert.equal(
      await store.createIntervention(code, attention(), {
        courseId: "1",
        studentId: "201",
        title: "Theo dõi",
        note: "Nội dung",
        actionType: "monitoring",
        followUpAt: null,
      }),
      null,
    );
    assert.equal(
      await store.updateIntervention(code, randomUUID(), { note: "note" }),
      null,
    );
    assert.equal(
      await store.addFollowup(code, randomUUID(), attention(), {
        note: "note",
        outcomeStatus: "resolved",
      }),
      null,
    );
  }
  assert.deepEqual(db.queries, []);
});

test("plan store SQL: every read/write checks current owner, active course enrollment and assignment visibility", async () => {
  const db = new RecordingDatabase();
  const store = new PostgresInnovationStore(db);
  const a = assignment();
  const recommendation = rankRecommendations(
    [a],
    [assignmentStatus(a)],
    [],
    [],
    fixedNow,
  )[0]!;
  await store.plans("SV001");
  await store.createPlan("SV001", recommendation, {
    assignmentId: "20",
    scheduledStartAt: fixedNow.toISOString(),
    notes: "synthetic-note' OR 1=1--",
  });
  await store.updatePlan("SV001", randomUUID(), {
    notes: "synthetic-note' OR 1=1--",
  });
  await store.deletePlan("SV001", randomUUID());
  assert.equal(db.queries.length, 4);
  for (const { sql, values } of db.queries) {
    assert.equal(values[0], "201");
    assert.match(sql, /u\.deleted=0 AND u\.suspended=0/);
    assert.match(sql, /ue\.status=0/);
    assert.match(sql, /ue\.timeend/);
    assert.match(sql, /r\.shortname='student'/);
    assert.match(sql, /cm\.visible=1/);
    assert.match(sql, /sec\.visible=1/);
    assert.equal(sql.includes("synthetic-note"), false);
  }
  assert.match(
    db.queries[1]!.sql,
    /ON CONFLICT\(owner_user_id,assignment_id\) DO NOTHING/,
  );
  assert.match(db.queries[2]!.sql, /p\.owner_user_id=\$1::bigint/);
  assert.match(db.queries[3]!.sql, /p\.owner_user_id=\$1::bigint/);
  assert.equal(
    db.queries[1]!.values.includes("synthetic-note' OR 1=1--"),
    true,
  );
});

test("teacher store SQL: record owner/course role and target's active enrollment are rechecked on every operation", async () => {
  const db = new RecordingDatabase();
  db.response = (sql) =>
    /RETURNING id|FOR UPDATE OF i/.test(sql) ? [{ id: randomUUID() }] : [];
  const store = new PostgresInnovationStore(db);
  await store.interventions("GV001");
  await store.createIntervention("GV001", attention(), {
    courseId: "1",
    studentId: "201",
    title: "Theo dõi",
    note: "synthetic-private-note",
    actionType: "monitoring",
    followUpAt: null,
  });
  await store.updateIntervention("GV001", randomUUID(), {
    status: "resolved",
    note: "synthetic-private-note",
  });
  await store.addFollowup("GV001", randomUUID(), attention(), {
    note: "synthetic-private-note",
    outcomeStatus: "resolved",
  });
  const scoped = db.queries.filter(({ sql }) => sql.startsWith("WITH actor"));
  assert.ok(scoped.length >= 6);
  for (const { sql, values } of scoped) {
    assert.equal(values[0], "101");
    assert.match(sql, /i\.owner_teacher_id=\$1::bigint/);
    assert.match(sql, /teacher','editingteacher/);
    assert.match(sql, /u\.deleted=0 AND u\.suspended=0/);
    assert.match(sql, /r\.shortname='student'/);
    assert.match(sql, /ue\.status=0/);
    assert.match(sql, /ue\.timestart/);
    assert.match(sql, /ue\.timeend/);
    assert.equal(sql.includes("synthetic-private-note"), false);
  }
  assert.equal(
    db.queries.some(({ sql }) => /pg_advisory_xact_lock/.test(sql)),
    true,
  );
  assert.equal(
    db.queries.some(({ sql }) =>
      /count\(\*\).*owner_teacher_id=\$1::bigint\)<200/s.test(sql),
    ),
    true,
  );
  assert.equal(
    db.queries.some(({ sql }) => /FOR UPDATE OF i/.test(sql)),
    true,
  );
  assert.equal(
    db.queries.some(({ sql }) => /intervention_id=\$2::uuid\)<100/.test(sql)),
    true,
  );
  assert.equal(
    db.queries.some(({ sql }) => /WHEN \$3='resolved' THEN NULL/.test(sql)),
    true,
  );
  for (const { sql } of db.queries) {
    const mutations = [
      ...sql.matchAll(
        /(?:INSERT INTO|UPDATE(?!\s+OF\b)|DELETE FROM)\s+([\w.]+)/g,
      ),
    ];
    for (const match of mutations) assert.match(match[1]!, /^app\./);
  }
});

test("teacher store SQL: absent or revoked locked record cannot append history or change parent", async () => {
  const db = new RecordingDatabase();
  const store = new PostgresInnovationStore(db);
  assert.equal(
    await store.addFollowup("GV001", randomUUID(), attention(), {
      note: "No access",
      outcomeStatus: "resolved",
    }),
    null,
  );
  assert.equal(db.queries.length, 1);
  assert.match(db.queries[0]!.sql, /FOR UPDATE OF i/);
});

test("innovation migration: candidate guard, app-only indexed FKs, active-record uniqueness and nonempty rollback protection", () => {
  const up = readFileSync(
    new URL("../migrations/001_innovation_support.up.sql", import.meta.url),
    "utf8",
  );
  const down = readFileSync(
    new URL("../migrations/001_innovation_support.down.sql", import.meta.url),
    "utf8",
  );
  const tables = [...up.matchAll(/CREATE TABLE\s+([\w.]+)/g)].map((m) => m[1]);
  assert.deepEqual(tables, [
    "app.study_plan_items",
    "app.teacher_interventions",
    "app.intervention_followups",
  ]);
  assert.match(up, /current_database\(\) <> 'lms_mobile_learning_candidate'/);
  assert.equal(
    /(?:ALTER|DROP|TRUNCATE|UPDATE|DELETE FROM|INSERT INTO)\s+(?:TABLE\s+)?(?:lms|derived)\./i.test(
      up,
    ),
    false,
  );
  for (const column of [
    "owner_user_id",
    "assignment_id",
    "course_id",
    "owner_teacher_id",
    "student_id",
    "intervention_id",
  ])
    assert.match(
      up,
      new RegExp(`CREATE (?:UNIQUE )?INDEX[^;]+\\(${column}(?:,|\\))`),
    );
  assert.match(
    up,
    /UNIQUE INDEX teacher_intervention_active_scope_idx[^;]+WHERE status<>'resolved'/,
  );
  assert.match(down, /ROLLBACK_BLOCKED_NONEMPTY_APP_DATA/);
  assert.equal(
    down.indexOf("ROLLBACK_BLOCKED_NONEMPTY_APP_DATA") <
      down.indexOf("DROP TABLE"),
    true,
  );
});
