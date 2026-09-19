import test from "node:test";
import assert from "node:assert/strict";
import { GroupStudentDataSource } from "../src/data/group-student-data-source.ts";
import { GroupTeacherDataSource } from "../src/data/group-teacher-data-source.ts";
import {
  studentScope,
  teacherScope,
  studentIds,
  teacherIds,
} from "../src/data/group-scope.ts";
import { createPool } from "../src/data/database.ts";
import { loadConfig } from "../src/config.ts";

test("group identities are a fixed alias allowlist, never arbitrary user IDs", async () => {
  const db = {
    read: async () => {
      throw new Error("QUERY_MUST_NOT_RUN");
    },
  };
  const student = new GroupStudentDataSource(db);
  const teacher = new GroupTeacherDataSource(db);
  for (const code of ["201", "SV999", "GV001", "sv001"])
    assert.equal(await student.student(code), null);
  for (const code of ["101", "GV999", "SV001", "gv001"])
    assert.equal(await teacher.teacher(code), null);
  assert.deepEqual(await student.courses("201"), []);
  assert.deepEqual(await teacher.courses("101"), []);
  assert.equal(studentIds.SV001, "201");
  assert.equal(teacherIds.GV002, "102");
});
test("group scope includes active identity, enrolment, role/course context and visibility", () => {
  for (const scope of [studentScope, teacherScope]) {
    assert.match(scope, /u\.deleted=0 AND u\.suspended=0/);
    assert.match(scope, /contextlevel=50/);
    assert.match(scope, /c\.visible=1/);
    assert.match(scope, /role_assignments/);
    assert.match(scope, /\$1::bigint/);
  }
  assert.match(studentScope, /ue\.status=0/);
  assert.match(studentScope, /ue\.timeend/);
});
test("candidate pool is opt-in and rejects a different endpoint or legacy database", async () => {
  const url = new URL(
    "postgresql://ep-soft-waterfall-b32kjeu0.test.neon.tech/lms_mobile_learning_candidate",
  );
  url.username = "unit_test";
  url.password = "not-a-real-credential";
  assert.throws(() => createPool(url.toString()), /CONFIG_DATABASE_INVALID/);
  const pool = createPool(url.toString(), "group_39_20");
  assert.equal(pool.options.database, "lms_mobile_learning_candidate");
  assert.deepEqual(pool.options.ssl, { rejectUnauthorized: true });
  await pool.end();
  url.hostname = "ep-other.test.neon.tech";
  assert.throws(
    () => createPool(url.toString(), "group_39_20"),
    /CONFIG_DATABASE_INVALID/,
  );
});
test("legacy is the default model; unknown model never silently selects candidate", () => {
  const env = {
    APP_ENV: "development",
    DATABASE_URL: "unused-test-value",
    DEMO_AUTH_ENABLED: "true",
  };
  assert.equal(loadConfig(env).databaseModel, "current_22_10");
  assert.throws(
    () => loadConfig({ ...env, DATABASE_MODEL: "unknown" }),
    /CONFIG_DATABASE_MODEL_INVALID/,
  );
});
