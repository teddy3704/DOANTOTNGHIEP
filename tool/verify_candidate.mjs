import { connectCandidate, safeFailure } from './candidate_database.mjs';

let client;
try {
  client = await connectCandidate();
  await client.query('BEGIN READ ONLY');
  const { rows: [counts] } = await client.query(`WITH ns AS (
    SELECT oid,nspname FROM pg_namespace WHERE nspname IN ('lms','app','derived')
  ), tbl AS (SELECT c.oid,n.nspname FROM pg_class c JOIN ns n ON n.oid=c.relnamespace WHERE c.relkind='r')
  SELECT (SELECT count(*)::int FROM ns) AS schemas,
    (SELECT count(*)::int FROM tbl) AS physical_tables,
    (SELECT count(*)::int FROM tbl WHERE nspname='lms') AS lms_tables,
    (SELECT count(*)::int FROM tbl WHERE nspname='app') AS app_tables,
    (SELECT count(*)::int FROM pg_class c JOIN ns n ON n.oid=c.relnamespace WHERE c.relkind='v' AND n.nspname='derived') AS derived_views,
    (SELECT count(*)::int FROM pg_constraint WHERE conrelid IN (SELECT oid FROM tbl) AND contype='p') AS pk,
    (SELECT count(*)::int FROM pg_constraint WHERE conrelid IN (SELECT oid FROM tbl) AND contype='f') AS fk,
    (SELECT count(*)::int FROM pg_attribute WHERE attrelid IN (SELECT oid FROM tbl) AND attnum>0 AND NOT attisdropped) AS columns`);
  const expected = {schemas:3,physical_tables:39,lms_tables:35,app_tables:4,derived_views:20,pk:39,fk:38,columns:548};
  console.log(JSON.stringify({ catalog: counts, pass: Object.entries(expected).every(([k,v]) => counts[k]===v) }));
  const views = (await client.query(`SELECT table_name, array_agg(column_name ORDER BY ordinal_position) AS columns
    FROM information_schema.columns WHERE table_schema='derived' GROUP BY table_name ORDER BY table_name`)).rows;
  for (const view of views) {
    if (!/^[a-z_]+$/.test(view.table_name)) throw new Error('UNEXPECTED_VIEW_NAME');
    const { rows: [count] } = await client.query(`SELECT count(*)::int AS rows FROM derived.${view.table_name}`);
    console.log(JSON.stringify({view:view.table_name,...count,columns:view.columns}));
  }
  for (const table of ['learning_reminders','notifications','notification_preferences','learning_goals']) {
    const {rows:[count]} = await client.query(`SELECT count(*)::int AS rows FROM app.${table}`);
    console.log(JSON.stringify({app:table,...count}));
  }
  console.log(JSON.stringify({authFields:(await client.query(`SELECT
    (SELECT count(*)::int FROM lms."user" WHERE password IS NOT NULL OR secret IS NOT NULL) AS user_nonnull,
    (SELECT count(*)::int FROM lms.enrol WHERE password IS NOT NULL) AS enrol_nonnull`)).rows[0]}));
  await client.query('COMMIT');
  if (!Object.entries(expected).every(([k,v]) => counts[k]===v)) process.exitCode=1;
} catch(error) {
  await client?.query('ROLLBACK').catch(()=>{});
  console.log(JSON.stringify(safeFailure(error))); process.exitCode=1;
} finally { await client?.end().catch(()=>{}); }
