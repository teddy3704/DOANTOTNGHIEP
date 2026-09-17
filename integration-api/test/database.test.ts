import assert from "node:assert/strict";
import test from "node:test";
import type pg from "pg";
import { createPool, PostgresReadDatabase } from "../src/data/database.ts";

class FakeClient {
  queries: { sql: string; values: unknown[] | undefined }[] = [];
  releases: (boolean | Error | undefined)[] = [];
  failures = new Map<string, Error>();
  rows = [{ courseId: "1" }];

  async query(sql: string, values?: unknown[]) {
    this.queries.push({ sql, values });
    const failure = this.failures.get(sql);
    if (failure) throw failure;
    return { rows: sql.startsWith("SELECT") ? this.rows : [] };
  }

  release(discard?: boolean | Error) {
    this.releases.push(discard);
  }
}

function databaseFixture() {
  const client = new FakeClient();
  let acquisitions = 0;
  const pool = {
    async connect() {
      acquisitions += 1;
      return client;
    },
  } as unknown as pg.Pool;
  return {
    client,
    database: new PostgresReadDatabase(pool),
    acquisitions: () => acquisitions,
  };
}

test("read executes one read-only transaction, copies parameters, commits and releases the client", async () => {
  const { client, database, acquisitions } = databaseFixture();
  const sql =
    "SELECT course_id AS courseId FROM lms.vw_student_courses WHERE student_code = $1";
  const values = Object.freeze(["SV001"]);
  assert.deepEqual(await database.read(sql, values), [{ courseId: "1" }]);
  assert.equal(acquisitions(), 1);
  assert.deepEqual(
    client.queries.map(({ sql: statement }) => statement),
    ["BEGIN READ ONLY", "SET LOCAL statement_timeout = '10s'", sql, "COMMIT"],
  );
  assert.deepEqual(client.queries[2]!.values, ["SV001"]);
  assert.notEqual(client.queries[2]!.values, values);
  assert.deepEqual(client.releases, [false]);
});

test("query failure rolls back, preserves the original error and releases once", async () => {
  const { client, database } = databaseFixture();
  const sql = "SELECT 1";
  const failure = new Error("test_query_failure");
  client.failures.set(sql, failure);
  await assert.rejects(
    database.read(sql),
    (error: unknown) => error === failure,
  );
  assert.deepEqual(
    client.queries.map(({ sql: statement }) => statement),
    ["BEGIN READ ONLY", "SET LOCAL statement_timeout = '10s'", sql, "ROLLBACK"],
  );
  assert.deepEqual(client.releases, [false]);
});

test("rollback failure destroys the pooled client while retaining the original query error", async () => {
  const { client, database } = databaseFixture();
  const failure = new Error("test_original_query_failure");
  client.failures.set("SELECT 1", failure);
  client.failures.set("ROLLBACK", new Error("test_rollback_failure"));
  await assert.rejects(
    database.read("SELECT 1"),
    (error: unknown) => error === failure,
  );
  assert.equal(client.queries.at(-1)!.sql, "ROLLBACK");
  assert.deepEqual(client.releases, [true]);
});

test("transaction setup and commit failures also roll back and release", async () => {
  for (const failingStatement of [
    "BEGIN READ ONLY",
    "SET LOCAL statement_timeout = '10s'",
    "COMMIT",
  ]) {
    const { client, database } = databaseFixture();
    const failure = new Error("test_transaction_failure");
    client.failures.set(failingStatement, failure);
    await assert.rejects(
      database.read("SELECT 1"),
      (error: unknown) => error === failure,
    );
    assert.equal(client.queries.at(-1)!.sql, "ROLLBACK");
    assert.deepEqual(client.releases, [false]);
    if (failingStatement !== "COMMIT") {
      assert.equal(
        client.queries.some(({ sql }) => sql === "SELECT 1"),
        false,
      );
    }
  }
});

test("connection acquisition failure propagates without querying or releasing a nonexistent client", async () => {
  const client = new FakeClient();
  const failure = new Error("test_pool_acquisition_failure");
  let attempts = 0;
  const pool = {
    async connect() {
      attempts += 1;
      throw failure;
    },
  } as unknown as pg.Pool;
  await assert.rejects(
    new PostgresReadDatabase(pool).read("SELECT 1"),
    (error: unknown) => error === failure,
  );
  assert.equal(attempts, 1);
  assert.deepEqual(client.queries, []);
  assert.deepEqual(client.releases, []);
});

// This URL is a test fixture only. No connection is initiated, no .env is read,
// and no credential values or complete pool configuration are asserted/logged.
function fixtureUrl() {
  const url = new URL(
    "postgresql://ep-unit-test.neon.tech/lms_mobile_learning",
  );
  url.username = "unit_test_user";
  url.password = "not-a-real-credential";
  return url;
}

test("pool configuration rejects malformed URLs and unsupported database boundaries with a sanitized error", () => {
  const invalid: string[] = [
    "not a URL",
    "",
    "postgresql://%ZZ:invalid@ep-unit-test.neon.tech/lms_mobile_learning",
    fixtureUrl()
      .toString()
      .replace(/^postgresql:/, "https:"),
  ];
  const variants: ((url: URL) => void)[] = [
    (url) => {
      url.hostname = "localhost";
    },
    (url) => {
      url.hostname = "ep-unit-test.neon.tech.invalid";
    },
    (url) => {
      url.hostname = "neon.tech";
    },
    (url) => {
      url.pathname = "/unrelated_database";
    },
    (url) => {
      url.port = "6432";
    },
    (url) => {
      url.username = "";
    },
    (url) => {
      url.password = "";
    },
  ];
  for (const vary of variants) {
    const url = fixtureUrl();
    vary(url);
    invalid.push(url.toString());
  }
  for (const input of invalid) {
    assert.throws(() => createPool(input), {
      name: "Error",
      message: "CONFIG_DATABASE_INVALID",
    });
  }
});

test("URI query parameters cannot disable verified TLS or override connection and timeout limits", async () => {
  const url = fixtureUrl();
  url.search = new URLSearchParams({
    sslmode: "disable",
    ssl: "false",
    rejectUnauthorized: "false",
    host: "outside.invalid",
    database: "unrelated_database",
    max: "999",
    statement_timeout: "0",
    query_timeout: "0",
    connectionTimeoutMillis: "0",
    options: "-c default_transaction_read_only=off",
    application_name: "untrusted_uri_value",
  }).toString();
  const pool = createPool(url.toString());
  try {
    assert.deepEqual(pool.options.ssl, { rejectUnauthorized: true });
    assert.equal(pool.options.enableChannelBinding, true);
    assert.equal(pool.options.host, "ep-unit-test.neon.tech");
    assert.equal(pool.options.port, 5432);
    assert.equal(pool.options.database, "lms_mobile_learning");
    assert.equal(pool.options.max, 4);
    assert.equal(pool.options.idleTimeoutMillis, 10000);
    assert.equal(pool.options.connectionTimeoutMillis, 15000);
    assert.equal(pool.options.statement_timeout, 10000);
    assert.equal(pool.options.query_timeout, 12000);
    assert.equal(
      pool.options.application_name,
      "dlu-student-support-development",
    );
    assert.equal(pool.options.options, undefined);
    assert.equal(pool.options.connectionString, undefined);
    assert.equal(pool.totalCount, 0);
    assert.equal(pool.waitingCount, 0);
  } finally {
    await pool.end();
  }
});
