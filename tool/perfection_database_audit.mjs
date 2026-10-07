// Candidate-only, secret-safe, READ ONLY forensic catalog audit.
// No row payloads, account credentials or database connection details are emitted.
import { mkdir, writeFile } from 'node:fs/promises';
import { connectCandidate, safeFailure } from './candidate_database.mjs';

const directory = new URL('../evidence/database/perfection-final/', import.meta.url);
const identifier = value => {
  if (!/^[a-z_][a-z0-9_]*$/.test(value)) throw new Error('INVALID_CATALOG_IDENTIFIER');
  return '"' + value + '"';
};
let db;
try {
  db = await connectCandidate();
  await db.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  await db.query("SET LOCAL statement_timeout='20s'");
  const schemas = (await db.query(`SELECT nspname AS name FROM pg_namespace
    WHERE nspname IN ('lms','app','derived') ORDER BY 1`)).rows;
  const tables = (await db.query(`SELECT table_schema AS schema,table_name AS name
    FROM information_schema.tables WHERE table_schema IN ('lms','app')
    AND table_type='BASE TABLE' ORDER BY 1,2`)).rows;
  const columns = (await db.query(`SELECT table_schema,table_name,column_name,data_type,
    udt_name,is_nullable,column_default FROM information_schema.columns
    WHERE table_schema IN ('lms','app','derived') ORDER BY 1,2,ordinal_position`)).rows;
  const constraints = (await db.query(`SELECT n.nspname AS schema,c.relname AS table_name,
    k.conname AS name,k.contype AS type,pg_get_constraintdef(k.oid) AS definition,
    k.convalidated AS validated FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('lms','app')
    ORDER BY 1,2,3`)).rows;
  const indexes = (await db.query(`SELECT schemaname AS schema,tablename AS table_name,
    indexname AS name,indexdef AS definition FROM pg_indexes
    WHERE schemaname IN ('lms','app') ORDER BY 1,2,3`)).rows;
  const foreignKeyIndexReview = (await db.query(`SELECT n.nspname AS schema,
    c.relname AS table_name,k.conname AS constraint_name,
    pg_get_constraintdef(k.oid) AS definition,
    EXISTS(SELECT 1 FROM pg_index i WHERE i.indrelid=k.conrelid AND i.indisvalid
      AND i.indpred IS NULL AND
      ARRAY(SELECT z FROM unnest(i.indkey::smallint[]) WITH ORDINALITY t(z,ord)
            WHERE ord<=array_length(k.conkey,1) ORDER BY ord)=k.conkey) AS indexed_leading_prefix
    FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace WHERE k.contype='f'
    AND n.nspname IN ('lms','app') ORDER BY 1,2,3`)).rows;
  const views = (await db.query(`SELECT schemaname AS schema,viewname AS name,
    definition FROM pg_views WHERE schemaname='derived' ORDER BY viewname`)).rows;
  const records = [];
  for (const table of tables) {
    const result = (await db.query(`SELECT count(*)::int AS count
      FROM ${identifier(table.schema)}.${identifier(table.name)}`)).rows[0];
    records.push({ ...table, ...result });
  }
  const privilegeSummary = (await db.query(`SELECT
    (SELECT rolsuper FROM pg_roles WHERE rolname=current_user) AS superuser,
    (SELECT rolbypassrls FROM pg_roles WHERE rolname=current_user) AS bypass_rls,
    count(*) FILTER(WHERE n.nspname='lms' AND has_table_privilege(c.oid,'INSERT,UPDATE,DELETE'))::int AS writable_lms_tables,
    count(*) FILTER(WHERE n.nspname='app' AND has_table_privilege(c.oid,'INSERT,UPDATE,DELETE'))::int AS writable_app_tables
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relkind='r' AND n.nspname IN ('lms','app')`)).rows[0];
  await db.query('ROLLBACK');
  const physicalColumns = columns.filter(c => c.table_schema !== 'derived');
  const summary = { auditDate: '2026-10-07', target: 'isolated synthetic candidate',
    accessMode: 'REPEATABLE READ READ ONLY; ROLLBACK', schemas: schemas.length,
    tables: tables.length,lmsTables: tables.filter(t=>t.schema==='lms').length,
    appTables: tables.filter(t=>t.schema==='app').length,views: views.length,
    physicalColumns: physicalColumns.length,
    primaryKeys: constraints.filter(c=>c.type==='p').length,
    foreignKeys: constraints.filter(c=>c.type==='f').length,
    uniqueConstraints: constraints.filter(c=>c.type==='u').length,
    checkConstraints: constraints.filter(c=>c.type==='c').length,indexes: indexes.length,
    foreignKeysWithoutLeadingIndex: foreignKeyIndexReview.filter(f=>!f.indexed_leading_prefix).length,
    privilegeSummary };
  await mkdir(directory,{recursive:true});
  await writeFile(new URL('catalog.json',directory),JSON.stringify({summary,schemas,tables,
    columns,constraints,indexes,foreignKeyIndexReview,views,records},null,2)+'\n');
  console.log(JSON.stringify(summary));
} catch (error) {
  if(db) await db.query('ROLLBACK').catch(()=>{});
  console.log(JSON.stringify(safeFailure(error)));process.exitCode=1;
} finally {if(db) await db.end().catch(()=>{});}
