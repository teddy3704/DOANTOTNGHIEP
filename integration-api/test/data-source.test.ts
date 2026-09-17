import assert from "node:assert/strict";
import test from "node:test";
import type { QueryResultRow } from "pg";
import type { ReadDatabase } from "../src/data/database.ts";
import { PostgresDevelopmentDataSource } from "../src/data/postgres-development-data-source.ts";

class CapturingDatabase implements ReadDatabase {
  calls: { sql: string; values: readonly unknown[] }[] = [];
  results: QueryResultRow[][] = [];
  failure: Error | undefined;

  async read<T extends QueryResultRow>(
    sql: string,
    values: readonly unknown[] = [],
  ): Promise<T[]> {
    this.calls.push({ sql, values });
    if (this.failure) throw this.failure;
    return (this.results.shift() ?? []) as T[];
  }
}

function setup() {
  const db = new CapturingDatabase();
  return { db, source: new PostgresDevelopmentDataSource(db) };
}

test("student identity requires an active synthetic account and a real course-context student role", async () => {
  const { db, source } = setup();
  const profile = {
    studentCode: "SV001",
    fullName: "Sinh viên Một",
    email: "sv001@example.test",
    department: "Công nghệ thông tin",
    role: "student",
  };
  db.results.push([profile]);
  assert.deepEqual(await source.student("SV001"), profile);
  const call = db.calls[0]!;
  assert.deepEqual(call.values, ["SV001"]);
  assert.match(call.sql, /u\.user_code = \$1 AND u\.active/);
  assert.match(call.sql, /u\.email LIKE '%@example\.test'/);
  assert.match(call.sql, /r\.shortname = 'student'/);
  assert.match(call.sql, /ctx\.context_level = 50/);
  assert.match(call.sql, /c\.id = ctx\.instance_id/);
  assert.match(call.sql, /ra\.user_id = u\.id/);
  assert.equal(await source.student("SV002"), null);
});

test("teacher identities, malformed identifiers and injection strings cannot become a student principal", async () => {
  const { db, source } = setup();
  for (const code of [
    "GV001",
    "student",
    "SV001\n",
    "SV001' OR true --",
    "sv001",
    "SV0001",
  ]) {
    assert.equal(await source.student(code), null);
  }
  assert.equal(db.calls.length, 0);
});

test("all student list SQL binds the current code instead of interpolating it", async () => {
  const { db, source } = setup();
  const code = "SV001' OR true --";
  await source.courses(code);
  await source.resources(code);
  await source.assignments(code);
  await source.assignmentStatus(code);
  await source.grades(code);
  await source.progress(code);
  await source.deadlines(code);
  assert.equal(db.calls.length, 7);
  for (const call of db.calls) {
    assert.deepEqual(call.values, [code]);
    assert.match(call.sql, /WHERE v\.student_code = \$1/);
    assert.equal(call.sql.includes(code), false);
    assert.match(call.sql.trim(), /^SELECT\b/);
    assert.doesNotMatch(
      call.sql,
      /SELECT\s+(?:\w+\.)?\*|\b(?:INSERT|UPDATE|DELETE|CREATE|ALTER|DROP)\b/i,
    );
    assert.doesNotMatch(call.sql, /vw_teacher_|vw_student_assignment_status/);
  }
});

test("status, grades and deadlines additionally enforce assignment module/section visibility", async () => {
  const { db, source } = setup();
  await source.assignmentStatus("SV001");
  await source.grades("SV001");
  await source.deadlines("SV001");
  for (const { sql } of db.calls) {
    assert.match(sql, /AND EXISTS\s*\(/);
    assert.match(sql, /FROM lms\.vw_student_assignments visible_assignment/);
    for (const field of ["student_code", "course_code", "assignment_code"]) {
      assert.ok(sql.includes(`visible_assignment.${field} = v.${field}`));
    }
  }
});

test("inaccessible and nonexistent course content returns null without retrieving activities", async () => {
  const { db, source } = setup();
  assert.equal(await source.content("SV001", "3"), null);
  assert.equal(db.calls.length, 1);
  assert.deepEqual(db.calls[0]!.values, ["SV001", "3"]);
  assert.match(
    db.calls[0]!.sql,
    /sc\.student_code = \$1 AND sc\.course_id = \$2::bigint/,
  );
  assert.doesNotMatch(db.calls[0]!.sql, /vw_course_content/);
});

test("invalid and oversized course IDs are rejected without reaching PostgreSQL", async () => {
  const { db, source } = setup();
  for (const id of [
    "0",
    "-1",
    "01",
    "1; SELECT 1",
    "9223372036854775808",
    "999999999999999999999999",
  ]) {
    assert.equal(await source.content("SV001", id), null);
  }
  assert.equal(db.calls.length, 0);
});

test("accessible course with no visible activities returns an empty array and content retains membership guard", async () => {
  const { db, source } = setup();
  db.results.push([{ authorized: 1 }], []);
  assert.deepEqual(await source.content("SV001", "1"), []);
  assert.equal(db.calls.length, 2);
  assert.deepEqual(db.calls[1]!.values, ["SV001", "1"]);
  assert.match(db.calls[1]!.sql, /WHERE EXISTS\s*\(/);
  assert.match(
    db.calls[1]!.sql,
    /sc\.student_code = \$1 AND sc\.course_id = \$2::bigint/,
  );
  assert.match(db.calls[1]!.sql, /sc\.course_code = v\.course_code/);
});

test("DTO serialization preserves string identifiers, nulls and numbers while normalizing dates to ISO", async () => {
  const { db, source } = setup();
  const date = new Date("2026-09-20T03:15:00Z");
  db.results.push([
    {
      courseId: "9007199254740993",
      startsAt: date,
      endsAt: null,
      teacherNames: null,
    },
  ]);
  const courses = await source.courses("SV001");
  assert.equal(courses[0]!.courseId, "9007199254740993");
  assert.equal(courses[0]!.startsAt, "2026-09-20T03:15:00.000Z");
  assert.equal(courses[0]!.endsAt, null);
  db.results.push([
    { assignmentId: "11", opensAt: date, dueAt: date, maxGrade: 10 },
  ]);
  const assignments = await source.assignments("SV001");
  assert.equal(assignments[0]!.opensAt, date.toISOString());
  assert.equal(assignments[0]!.dueAt, date.toISOString());
  assert.equal(assignments[0]!.maxGrade, 10);
  assert.equal(assignments[0]!.deepLink, null);
  assert.equal(assignments[0]!.deepLinkStatus, "TO_VERIFY_DLU");
  assert.match(db.calls[0]!.sql, /course_id::text AS "courseId"/);
  assert.match(db.calls[1]!.sql, /assignment_id::text AS "assignmentId"/);
  assert.match(db.calls[1]!.sql, /max_grade::double precision AS "maxGrade"/);
});

test("resource metadata without a file remains nullable and never gains a fabricated link", async () => {
  const { db, source } = setup();
  db.results.push([
    { resourceId: "1", filename: null, fileSizeBytes: null, mimeType: null },
  ]);
  const rows = await source.resources("SV001");
  assert.deepEqual(rows, [
    {
      resourceId: "1",
      filename: null,
      fileSizeBytes: null,
      mimeType: null,
      deepLink: null,
      deepLinkStatus: "TO_VERIFY_DLU",
    },
  ]);
});

test("public SQL projections omit credentials, submission bodies, internal file paths and write controls", async () => {
  const { db, source } = setup();
  await source.student("SV001");
  await source.courses("SV001");
  await source.resources("SV001");
  await source.assignments("SV001");
  await source.assignmentStatus("SV001");
  await source.grades("SV001");
  await source.progress("SV001");
  await source.deadlines("SV001");
  for (const { sql } of db.calls) {
    assert.doesNotMatch(
      sql,
      /\b(?:password|username|access_token|refresh_token|text_response|file_path|owner_user_id|submission_id|max_files|max_file_size_bytes|allowed_extensions|allows_resubmission)\b/i,
    );
  }
});

test("health performs a trivial read and database failures propagate without fallback data", async () => {
  const { db, source } = setup();
  await source.health();
  assert.deepEqual(db.calls, [{ sql: "SELECT 1 AS healthy", values: [] }]);
  const error = new Error("test_database_unavailable");
  db.failure = error;
  await assert.rejects(
    source.courses("SV001"),
    (caught: unknown) => caught === error,
  );
  await assert.rejects(
    source.student("SV001"),
    (caught: unknown) => caught === error,
  );
  await assert.rejects(source.health(), (caught: unknown) => caught === error);
});
