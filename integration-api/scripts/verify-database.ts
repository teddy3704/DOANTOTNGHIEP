import { createPool, PostgresReadDatabase } from "../src/data/database.ts";
import { loadConfig } from "../src/config.ts";
let pool: ReturnType<typeof createPool> | undefined;
try {
  pool = createPool(loadConfig().databaseUrl);
  const db = new PostgresReadDatabase(pool);
  const [identity] = await db.read<{
    database: string;
    schema: string;
    read_only: string;
  }>(
    "SELECT current_database() AS database, 'lms' AS schema, current_setting('transaction_read_only') AS read_only",
  );
  const [counts] = await db.read<{
    tables: number;
    views: number;
    foreign_keys: number;
  }>(`
    SELECT (SELECT count(*)::int FROM information_schema.tables WHERE table_schema='lms' AND table_type='BASE TABLE') AS tables,
      (SELECT count(*)::int FROM information_schema.views WHERE table_schema='lms') AS views,
      (SELECT count(*)::int FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname='lms' AND c.contype='f') AS foreign_keys`);
  const views = await db.read<{ name: string; columns: string[] }>(`
    SELECT c.table_name AS name, array_agg(c.column_name::text ORDER BY c.ordinal_position) AS columns
    FROM information_schema.columns c JOIN information_schema.views v USING (table_schema,table_name)
    WHERE c.table_schema='lms' GROUP BY c.table_name ORDER BY c.table_name`);
  const students = await db.read<{
    student_code: string;
    course_ids: string[];
  }>(`
    SELECT student_code, array_agg(course_id::text ORDER BY course_id) AS course_ids
    FROM lms.vw_student_courses GROUP BY student_code ORDER BY student_code LIMIT 3`);
  const required = [
    "vw_student_courses",
    "vw_course_content",
    "vw_student_resources",
    "vw_student_assignments",
    "vw_assignment_status",
    "vw_student_grade_overview",
    "vw_student_progress",
    "vw_upcoming_deadlines",
  ];
  if (
    identity?.database !== "lms_mobile_learning" ||
    identity.read_only !== "on" ||
    counts?.tables !== 22 ||
    counts.views !== 10 ||
    counts.foreign_keys !== 35 ||
    !required.every((v) => views.some((row) => row.name === v)) ||
    !students.some((s) => s.student_code === "SV001")
  ) {
    throw new Error("DATABASE_BASELINE_MISMATCH");
  }
  console.log(
    JSON.stringify(
      {
        DATABASE_CONNECTION: "PASS",
        DATABASE: identity.database,
        SCHEMA: identity.schema,
        READ_ONLY: identity.read_only,
        counts,
        views,
        syntheticStudents: students,
      },
      null,
      2,
    ),
  );
} catch {
  // Never serialize error objects, stacks or configuration.
  console.log("DATABASE_CONNECTION=FAIL");
  process.exitCode = 1;
} finally {
  await pool?.end();
}
