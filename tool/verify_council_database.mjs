// Node 24. Use an existing API workspace and its configured env file.
// This prints only catalog metadata, never connection settings or raw errors.
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

let pool;
try {
  const apiRoot = resolve(process.argv[2] ?? 'integration-api');
  const { createPool, PostgresReadDatabase } = await import(
    pathToFileURL(resolve(apiRoot, 'src/data/database.ts')).href
  );
  pool = createPool(process.env.DATABASE_URL ?? '');
  const db = new PostgresReadDatabase(pool);
  const baseline = await db.read(await readFile(
    new URL('../demo/01_verify_database_baseline.sql', import.meta.url), 'utf8'));
  const relations = await db.read(`
    SELECT table_schema, table_name, table_type
    FROM information_schema.tables
    WHERE table_schema IN ('lms','app','derived')
    ORDER BY table_schema, table_type, table_name`);
  const columns = await db.read(`
    SELECT table_schema, table_name,
      json_agg(json_build_object('name',column_name,'type',data_type,
        'nullable',is_nullable) ORDER BY ordinal_position) AS columns
    FROM information_schema.columns
    WHERE table_schema IN ('lms','app','derived')
      AND (table_name IN ('user','users','role','roles','role_assignments',
        'context','contexts','enrol','user_enrolments','course','courses',
        'course_sections','course_modules','modules')
        OR table_name LIKE '%teacher%' OR table_name LIKE '%progress%'
        OR table_name LIKE '%task%' OR table_name = 'vw_student_courses')
    GROUP BY table_schema,table_name ORDER BY table_schema,table_name`);
  console.log(JSON.stringify({ baseline: baseline[0], relations, columns }, null, 2));
} catch {
  console.log('DATABASE_CATALOG_VERIFICATION=FAIL (details suppressed)');
  process.exitCode = 1;
} finally {
  await pool?.end();
}
