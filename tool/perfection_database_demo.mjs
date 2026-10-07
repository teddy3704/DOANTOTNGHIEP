// Verify the exact council SQL on the candidate without exporting row values.
import { readFile,writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { connectCandidate,safeFailure } from './candidate_database.mjs';
let db;
try{
  const sql=await readFile(new URL('../database/council_pgadmin_demo.sql',import.meta.url),'utf8');
  const statements=sql.replace(/--[^\n]*/g,'');
  if(!/\bBEGIN\s+READ\s+ONLY\s*;/i.test(statements)
    ||! /\bROLLBACK\s*;\s*$/i.test(statements)
    ||/\b(?:INSERT|UPDATE|DELETE|ALTER|DROP|CREATE|TRUNCATE|GRANT|REVOKE|COMMIT)\b/i.test(statements)){
    throw new Error('READ_ONLY_COUNCIL_SQL_REQUIRED');
  }
  db=await connectCandidate();
  const results=await db.query(sql);
  const result={auditDate:'2026-10-07',councilSql:'PASS',access:'READ ONLY; ROLLBACK',
    sqlSHA256:createHash('sha256').update(sql).digest('hex'),statements:results.length,
    resultSets:results.filter(r=>r.command==='SELECT').map(r=>({columns:r.fields.map(f=>f.name),rowCount:r.rowCount})),
    exportedRowValues:false,pgAdminVisibleWorkspace:'NOT_VERIFIED_BY_SQL_RUNNER'};
  await writeFile(new URL('../evidence/database/perfection-final/council-sql-verification.json',import.meta.url),JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result));
}catch(error){if(db)await db.query('ROLLBACK').catch(()=>{});console.log(JSON.stringify(safeFailure(error)));process.exitCode=1;}
finally{if(db)await db.end().catch(()=>{});}
