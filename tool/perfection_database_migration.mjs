// Candidate-only migration gate. Default rehearse ALWAYS rolls back.
// apply requires explicit review of the emitted safe rehearsal and patch first.
import { readFile,writeFile,mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { connectCandidate,safeFailure } from './candidate_database.mjs';
const evidence=new URL('../evidence/database/perfection-final/',import.meta.url);
const identifier = value => {
  if(!/^[a-z_][a-z0-9_]*$/.test(value))throw new Error('INVALID_CATALOG_IDENTIFIER');
  return '"'+value+'"';
};
async function signature(db){
  return (await db.query(`SELECT table_schema,table_name,column_name,data_type,udt_name
    FROM information_schema.columns WHERE table_schema IN ('lms','app','derived')
    ORDER BY table_schema,table_name,ordinal_position`)).rows;
}
async function rowDigests(db){
  const tables=(await db.query(`SELECT table_schema AS schema,table_name AS name
    FROM information_schema.tables WHERE table_schema IN('lms','app') AND table_type='BASE TABLE' ORDER BY 1,2`)).rows;
  const results=[];
  for(const t of tables){
    const r=(await db.query(`SELECT count(*)::int AS rows,
      md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) AS digest
      FROM ${identifier(t.schema)}.${identifier(t.name)} t`)).rows[0];
    results.push({...t,...r});
  }
  return results;
}
async function lostAssignmentStates(db){
  return (await db.query(`SELECT count(*) FILTER(WHERE li.task_status IS NULL AND ut.task_status IS NOT NULL)::int AS lost_task_states,
    count(*)::int AS assignment_rows FROM derived.student_course_learning_items li
    JOIN derived.unified_tasks ut ON ut.userid=li.userid AND ut.courseid=li.courseid
    AND ut.task_type='assignment' AND ut.source_id=li.source_id WHERE li.activity_type='assign'`)).rows[0];
}
async function completedNextItems(db){
  return (await db.query(`SELECT count(*)::int AS invalid FROM derived.student_continue_learning
    WHERE activity_type IN('assign','quiz') AND task_status='completed'`)).rows[0].invalid;
}
let db;
try{
  const mode=process.argv[2]??'rehearse';
  if(!['rehearse','apply'].includes(mode))throw new Error('MODE_NOT_SUPPORTED');
  const number=process.argv[3]??'002';
  if(!['002','003'].includes(number))throw new Error('MIGRATION_NOT_SUPPORTED');
  const migration=new URL('../integration-api/migrations/'+(number==='002'?
    '002_perfection_integrity.up.sql':'003_continue_learning_semantics.up.sql'),import.meta.url);
  const sql=await readFile(migration,'utf8');
  if(/\b(?:INSERT|UPDATE|DELETE|TRUNCATE|DROP)\b/i.test(sql))throw new Error('DATA_OR_DESTRUCTIVE_SQL_REJECTED');
  const migrationHash=createHash('sha256').update(sql).digest('hex');
  const reviewedHashes={
    '002':'0c5db104c1677377016c03af7475bec0a2ec054822d1be2e5f6862204b519213',
    '003':'3278c0857b813627de5724002d10b0306660cb5f8b6316182eb02ded2261ea66',
  };
  if(mode==='apply'&&migrationHash!==reviewedHashes[number]){
    throw new Error('REVIEWED_MIGRATION_HASH_REQUIRED');
  }
  db=await connectCandidate();
  await db.query('BEGIN ISOLATION LEVEL REPEATABLE READ');
  await db.query("SET LOCAL lock_timeout='5s'");
  await db.query('SELECT pg_advisory_xact_lock(39201007)');
  const preColumns=await signature(db),preRows=await rowDigests(db),before=await lostAssignmentStates(db);
  const continueBefore=await completedNextItems(db);
  if(mode==='apply'){
    const definitions=(await db.query(`SELECT viewname,definition FROM pg_views
      WHERE schemaname='derived' ORDER BY viewname`)).rows;
    const directory='D:/DLU-LMS/Backups/perfection-2026-10-07';
    await mkdir(directory,{recursive:true});
    await writeFile(directory+'/'+(number==='002'?'before-views.json':'before-003-views.json'),JSON.stringify({definitions,columns:preColumns,rows:preRows},null,2)+'\n',{flag:'wx'});
  }
  await db.query(sql.replace(/^BEGIN;\s*$/m,'').replace(/^COMMIT;\s*$/m,''));
  const postColumns=await signature(db),postRows=await rowDigests(db),after=await lostAssignmentStates(db);
  const continueAfter=await completedNextItems(db);
  const checks=(await db.query(`SELECT conname AS name,convalidated AS validated FROM pg_constraint
    WHERE conname IN('study_plan_title_nonblank_ck','study_plan_timestamp_order_ck',
    'teacher_intervention_timestamp_order_ck','teacher_intervention_followup_order_ck',
    'teacher_intervention_resolved_followup_ck') ORDER BY 1`)).rows;
  const risk=(await db.query(`SELECT pg_get_viewdef('derived.student_risk_indicator'::regclass,true) AS definition`)).rows[0].definition;
  const tableRowsUnchanged=JSON.stringify(preRows)===JSON.stringify(postRows);
  const allColumnSignaturesUnchanged=JSON.stringify(preColumns)===JSON.stringify(postColumns);
  if(!tableRowsUnchanged||!allColumnSignaturesUnchanged||after.lost_task_states!==0||checks.length!==5||risk.includes('999')
    ||(number==='003'&&continueAfter!==0)){
    throw new Error('MIGRATION_VERIFICATION_FAILED');
  }
  await db.query(mode==='apply'?'COMMIT':'ROLLBACK');
  const result={migration:number,mode,status:'PASS',transaction:mode==='apply'?'COMMITTED':'ROLLED_BACK',
    migrationSHA256:migrationHash,before,after,
    allColumnSignaturesUnchanged,tableRowsUnchanged,tablesChecked:preRows.length,
    constraints:checks,unknownInactivityPenaltyRemoved:!risk.includes('999'),
    noTrackedActivityGuardPresent:risk.includes('total_tracked_activities > 0'),
    continueLearningBefore:continueBefore,continueLearningAfter:continueAfter};
  await writeFile(new URL((number==='003'?'003-':'')+(mode==='apply'?'migration-applied.json':'migration-rehearsal.json'),evidence),JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result));
}catch(error){if(db)await db.query('ROLLBACK').catch(()=>{});console.log(JSON.stringify(safeFailure(error)));process.exitCode=1;}
finally{if(db)await db.end().catch(()=>{});}
