// Candidate-only additive migration gate. No environment values in any output.
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { connectCandidate, safeFailure } from './candidate_database.mjs';

const output = 'D:/DLU-LMS/Backups/innovation-2026-10-03';
const identifier = value => {
  if (!/^[a-z_][a-z0-9_]*$/.test(value)) throw new Error('INVALID_CATALOG_IDENTIFIER');
  return '"' + value + '"';
};
async function catalog(db) {
  const tables = (await db.query(`SELECT table_schema AS schema,table_name AS name
    FROM information_schema.tables WHERE table_schema IN ('lms','app')
    AND table_type='BASE TABLE' ORDER BY 1,2`)).rows;
  const columns = (await db.query(`SELECT table_schema,table_name,column_name,data_type,is_nullable,column_default
    FROM information_schema.columns WHERE table_schema IN ('lms','app') ORDER BY 1,2,ordinal_position`)).rows;
  const constraints = (await db.query(`SELECT n.nspname AS schema,c.relname AS table_name,k.conname,k.contype,
    pg_get_constraintdef(k.oid) AS definition FROM pg_constraint k
    JOIN pg_class c ON c.oid=k.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('lms','app') ORDER BY 1,2,3`)).rows;
  const views = (await db.query(`SELECT schemaname,viewname,definition FROM pg_views
    WHERE schemaname='derived' ORDER BY viewname`)).rows;
  const records = [];
  const appBackup = {};
  for (const table of tables) {
    const name = `${identifier(table.schema)}.${identifier(table.name)}`;
    const row = (await db.query(`SELECT count(*)::int AS count,
      md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) AS digest FROM ${name} t`)).rows[0];
    records.push({ ...table, ...row });
    if (table.schema === 'app') appBackup[table.name] = (await db.query(`SELECT * FROM ${name}`)).rows;
  }
  return { tables, columns, constraints, views, records, appBackup };
}
let db;
try {
  db = await connectCandidate();
  await db.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  const state = await catalog(db);
  await db.query('COMMIT');
  const mode = process.argv[2] ?? 'inspect';
  if (mode === 'backup') {
    await mkdir(output, { recursive: true });
    const payload = JSON.stringify(state, null, 2);
    // Never overwrite the rollback reference after a migration has run.
    await writeFile(resolve(output, 'before.json'), payload, { flag: 'wx' });
    console.log(JSON.stringify({ backup: 'PASS', directory: output,
      sha256: createHash('sha256').update(payload).digest('hex') }));
  } else if (mode === 'rehearse' || mode === 'apply') {
    const before = JSON.parse(await readFile(resolve(output, 'before.json'), 'utf8'));
    if (!before.records.every(old => state.records.some(row =>
      row.schema === old.schema && row.name === old.name && row.count === old.count && row.digest === old.digest))) {
      throw new Error('BASELINE_CHANGED_REVIEW_REQUIRED');
    }
    if (state.tables.some(t => ['study_plan_items','teacher_interventions','intervention_followups'].includes(t.name))) {
      throw new Error('MIGRATION_ALREADY_PRESENT_REVIEW_REQUIRED');
    }
    const sql = await readFile(new URL('../integration-api/migrations/001_innovation_support.up.sql', import.meta.url), 'utf8');
    if (/\b(?:ALTER|DROP|TRUNCATE|DELETE|UPDATE|INSERT)\s+(?:TABLE\s+|INTO\s+|FROM\s+)?(?:lms|derived)\s*\./i.test(sql)) {
      throw new Error('ACADEMIC_MIGRATION_REJECTED');
    }
    await db.query('SELECT pg_advisory_lock(39201003)');
    if (mode === 'rehearse') {
      await db.query('BEGIN');
      await db.query(sql.replace(/^BEGIN;\s*$/m,'').replace(/^COMMIT;\s*$/m,''));
      const created = (await db.query(`SELECT count(*)::int AS count FROM information_schema.tables
        WHERE table_schema='app' AND table_name IN ('study_plan_items','teacher_interventions','intervention_followups')`)).rows[0].count;
      if (created !== 3) throw new Error('MIGRATION_CATALOG_INVALID');
      await db.query('ROLLBACK');
      console.log(JSON.stringify({ migrationRehearsal: 'PASS', transaction: 'ROLLED_BACK', tablesChecked: created }));
    } else {
      await db.query(sql);
      await writeFile(resolve(output,'applied-migration.sha256'),createHash('sha256').update(sql).digest('hex'),{flag:'wx'});
      console.log(JSON.stringify({ migration: 'APPLIED', schema: 'app', backup: output }));
    }
  } else if (mode === 'verify') {
    const before = JSON.parse(await readFile(resolve(output, 'before.json'), 'utf8'));
    const unchanged = before.records.every(old => state.records.some(row =>
      row.schema === old.schema && row.name === old.name && row.count === old.count && row.digest === old.digest));
    const sourceColumns = JSON.stringify(before.columns.filter(c=>c.table_schema==='lms')) ===
      JSON.stringify(state.columns.filter(c=>c.table_schema==='lms'));
    const sourceViews = JSON.stringify(before.views) === JSON.stringify(state.views);
    console.log(JSON.stringify({ existingRowsUnchanged: unchanged, lmsColumnsUnchanged: sourceColumns,
      derivedViewsUnchanged: sourceViews, addedTables: state.tables.length-before.tables.length }));
    if (!unchanged || !sourceColumns || !sourceViews) process.exitCode = 1;
  } else if (mode !== 'inspect') throw new Error('MODE_NOT_SUPPORTED');
  console.log(JSON.stringify({ tableCount: state.tables.length,
    lmsTables: state.tables.filter(t=>t.schema==='lms').length,
    appTables: state.tables.filter(t=>t.schema==='app').map(t=>t.name),
    viewCount: state.views.length, columnCount: state.columns.length,
    primaryKeys: state.constraints.filter(c=>c.contype==='p').length,
    foreignKeys: state.constraints.filter(c=>c.contype==='f').length }));
} catch(error) {
  if(db) await db.query('ROLLBACK').catch(()=>{});
  console.log(JSON.stringify(safeFailure(error))); process.exitCode=1;
}
finally { if(db) await db.end().catch(()=>{}); }
