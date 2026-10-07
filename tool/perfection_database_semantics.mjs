// Read-only candidate integrity/null/fan-out checks and bounded query plans.
import { readFile, writeFile } from 'node:fs/promises';
import { connectCandidate, safeFailure } from './candidate_database.mjs';
const output = new URL('../evidence/database/perfection-final/',import.meta.url);
const ident = value => {
  if(!/^[a-z_][a-z0-9_]*$/.test(value)) throw new Error('INVALID_CATALOG_IDENTIFIER');
  return '"'+value+'"';
};
const duplicateKeys = {
  student_attendance_summary:['userid','courseid','attendance_id'],
  student_continue_learning:['userid','courseid'],
  student_course_learning_items:['userid','courseid','coursemoduleid'],
  student_course_overview:['userid','courseid'],student_course_progress:['userid','courseid'],
  student_dashboard:['userid'],student_engagement:['userid','courseid'],
  student_grade_category_summary:['userid','courseid','category_id'],
  student_grade_overview:['userid','grade_item_id'],student_learning_analytics:['userid','courseid'],
  student_risk_indicator:['userid','courseid'],student_task_summary:['userid','courseid'],
  teacher_assignment_monitoring:['teacherid','courseid','assignment_id'],
  teacher_course_analytics:['teacherid','courseid'],teacher_course_overview:['teacherid','courseid'],
  teacher_dashboard:['teacherid'],teacher_grade_overview:['teacherid','courseid','studentid'],
  teacher_quiz_monitoring:['teacherid','courseid','quiz_id'],
  teacher_student_monitoring:['teacherid','courseid','studentid'],
  unified_tasks:['userid','courseid','task_type','source_id'],
};
const checks = {
  appUserOrphans:`SELECT 'learning_goals' AS table_name,count(*)::int AS invalid FROM app.learning_goals a LEFT JOIN lms."user" u ON u.id=a.user_id WHERE u.id IS NULL
    UNION ALL SELECT 'learning_reminders',count(*)::int FROM app.learning_reminders a LEFT JOIN lms."user" u ON u.id=a.user_id WHERE u.id IS NULL
    UNION ALL SELECT 'notifications',count(*)::int FROM app.notifications a LEFT JOIN lms."user" u ON u.id=a.user_id WHERE u.id IS NULL
    UNION ALL SELECT 'notification_preferences',count(*)::int FROM app.notification_preferences a LEFT JOIN lms."user" u ON u.id=a.user_id WHERE u.id IS NULL`,
  planIntegrity:`SELECT count(*) FILTER(WHERE length(trim(p.title))=0)::int AS blank_title,
    count(*) FILTER(WHERE a.course<>p.course_id)::int AS assignment_course_mismatch,
    count(*) FILTER(WHERE p.updated_at<p.created_at)::int AS reversed_timestamps
    FROM app.study_plan_items p JOIN lms.assign a ON a.id=p.assignment_id`,
  interventionIntegrity:`SELECT count(*) FILTER(WHERE i.follow_up_at<i.created_at)::int AS past_initial_followup,
    count(*) FILTER(WHERE i.status='resolved' AND i.follow_up_at IS NOT NULL)::int AS resolved_with_followup,
    count(*) FILTER(WHERE i.updated_at<i.created_at)::int AS reversed_timestamps,
    count(*) FILTER(WHERE NOT EXISTS(SELECT 1 FROM lms.role_assignments ra JOIN lms.context c ON c.id=ra.contextid
      JOIN lms.role r ON r.id=ra.roleid WHERE ra.userid=i.owner_teacher_id AND c.contextlevel=50
      AND c.instanceid=i.course_id AND (r.shortname IN ('teacher','editingteacher') OR r.archetype IN ('teacher','editingteacher'))))::int AS invalid_teacher_scope,
    count(*) FILTER(WHERE NOT EXISTS(SELECT 1 FROM lms.user_enrolments ue JOIN lms.enrol e ON e.id=ue.enrolid
      WHERE ue.userid=i.student_id AND e.courseid=i.course_id))::int AS student_never_enrolled
    FROM app.teacher_interventions i`,
  followupIntegrity:`SELECT count(*) FILTER(WHERE f.created_at<i.created_at)::int AS before_intervention,
    count(*) FILTER(WHERE f.overdue_tasks>f.pending_tasks)::int AS separate_overdue_bucket_exceeds_pending_bucket
    FROM app.intervention_followups f JOIN app.teacher_interventions i ON i.id=f.intervention_id`,
  reminderPolymorphism:`SELECT coalesce(source_type,'<none>') AS type,count(*)::int AS count,
    count(*) FILTER(WHERE (source_type IS NULL)<>(source_id IS NULL))::int AS incomplete_reference
    FROM app.learning_reminders GROUP BY 1 ORDER BY 1`,
  notificationPolymorphism:`SELECT coalesce(source_type,'<none>') AS type,count(*)::int AS count,
    count(*) FILTER(WHERE (source_type IS NULL)<>(source_id IS NULL))::int AS incomplete_reference
    FROM app.notifications GROUP BY 1 ORDER BY 1`,
  zeroNullGrades:`SELECT count(*) FILTER(WHERE finalgrade IS NULL)::int AS null_grade_rows,
    count(*) FILTER(WHERE finalgrade=0)::int AS zero_grade_rows,
    count(*) FILTER(WHERE finalgrade IS NULL AND grade_percentage IS NOT NULL)::int AS null_converted_to_grade,
    count(*) FILTER(WHERE finalgrade=0 AND grademax>0 AND grade_percentage<>0)::int AS zero_lost,
    count(*) FILTER(WHERE grademax=0 AND grade_percentage IS NOT NULL)::int AS zero_denominator_invalid
    FROM derived.student_grade_overview`,
  gradeRange:`SELECT count(*) FILTER(WHERE finalgrade<grademin OR finalgrade>grademax)::int AS out_of_range,
    count(*) FILTER(WHERE grademax<grademin)::int AS reversed_range
    FROM derived.student_grade_overview`,
  noTrackedActivity:`SELECT count(*) FILTER(WHERE total_tracked_activities=0)::int AS no_tracked_rows,
    count(*) FILTER(WHERE total_tracked_activities=0 AND progress_percentage=0)::int AS no_tracked_mapped_to_zero,
    count(*) FILTER(WHERE completed_activities>total_tracked_activities)::int AS impossible_completion
    FROM derived.student_course_progress`,
  unknownEngagement:`SELECT count(*) FILTER(WHERE e.days_since_last_activity IS NULL)::int AS unknown_activity_rows,
    count(*) FILTER(WHERE e.days_since_last_activity IS NULL AND r.risk_score>=40)::int AS unknown_with_inactivity_penalty
    FROM derived.student_engagement e JOIN derived.student_risk_indicator r USING(userid,courseid)`,
  enrolmentScope:`SELECT count(*) FILTER(WHERE NOT EXISTS(SELECT 1 FROM lms.user_enrolments ue
      JOIN lms.enrol e ON e.id=ue.enrolid JOIN lms."user" u ON u.id=ue.userid
      JOIN lms.context ctx ON ctx.contextlevel=50 AND ctx.instanceid=e.courseid
      JOIN lms.role_assignments ra ON ra.contextid=ctx.id AND ra.userid=ue.userid
      JOIN lms.role r ON r.id=ra.roleid AND (r.shortname='student' OR r.archetype='student')
      WHERE ue.userid=p.userid AND e.courseid=p.courseid AND ue.status=0 AND e.status=0
      AND u.deleted=0 AND u.suspended=0 AND (ue.timestart=0 OR ue.timestart<=extract(epoch FROM now()))
      AND (ue.timeend=0 OR ue.timeend>extract(epoch FROM now()))))::int AS source_rows_outside_current_student_scope
    FROM derived.student_course_progress p`,
  assignmentLearningState:`SELECT count(*)::int AS assignment_learning_rows,
    count(*) FILTER(WHERE li.task_status IS NULL AND ut.task_status IS NOT NULL)::int AS lost_task_status
    FROM derived.student_course_learning_items li JOIN derived.unified_tasks ut
    ON ut.userid=li.userid AND ut.courseid=li.courseid AND ut.task_type='assignment'
    AND ut.source_id=li.source_id WHERE li.activity_type='assign'`,
  sourceSubmissionSemantics:`SELECT count(*) FILTER(WHERE task_type='assignment' AND source_status='submitted')::int AS submitted_tasks,
    count(*) FILTER(WHERE task_type='assignment' AND source_status='submitted' AND task_status<>'completed')::int AS submitted_not_completed,
    count(*) FILTER(WHERE task_type='assignment' AND source_status IS NULL)::int AS no_submission_rows,
    count(*) FILTER(WHERE task_type='quiz' AND quiz_state IS NULL)::int AS no_quiz_attempt_rows,
    count(*) FILTER(WHERE source_status IS NULL AND task_status='completed')::int AS unknown_false_completed
    FROM derived.unified_tasks`,
  attendanceDenominator:`SELECT count(*)::int AS attendance_user_rows,
    count(*) FILTER(WHERE v.total_sessions<(SELECT count(*) FROM lms.attendance_sessions s WHERE s.attendanceid=v.attendance_id))::int AS only_marked_denominator
    FROM derived.student_attendance_summary v`,
  noAttendance:`SELECT count(*) FILTER(WHERE attendance_percentage IS NULL)::int AS unknown_rows,
    count(*) FILTER(WHERE attendance_sessions=0 AND attendance_percentage=0)::int AS unknown_converted_to_zero
    FROM derived.student_course_overview`,
  continuedSourceCompleted:`SELECT count(*) FILTER(WHERE activity_type IN('assign','quiz') AND task_status='completed')::int
    AS source_completed_but_completion_tracker_incomplete FROM derived.student_continue_learning`,
  sourcePolymorphicIntegrity:`SELECT count(*)::int AS module_rows,
    count(*) FILTER(WHERE m.name NOT IN('assign','quiz','resource','folder','forum','attendance'))::int AS unsupported_module_type,
    count(*) FILTER(WHERE (m.name='assign' AND NOT EXISTS(SELECT 1 FROM lms.assign a WHERE a.id=cm.instance AND a.course=cm.course))
      OR (m.name='quiz' AND NOT EXISTS(SELECT 1 FROM lms.quiz a WHERE a.id=cm.instance AND a.course=cm.course))
      OR (m.name='resource' AND NOT EXISTS(SELECT 1 FROM lms.resource a WHERE a.id=cm.instance AND a.course=cm.course))
      OR (m.name='folder' AND NOT EXISTS(SELECT 1 FROM lms.folder a WHERE a.id=cm.instance AND a.course=cm.course))
      OR (m.name='forum' AND NOT EXISTS(SELECT 1 FROM lms.forum a WHERE a.id=cm.instance AND a.course=cm.course))
      OR (m.name='attendance' AND NOT EXISTS(SELECT 1 FROM lms.attendance a WHERE a.id=cm.instance AND a.course=cm.course)))::int AS absent_or_course_mismatched_instance
    FROM lms.course_modules cm JOIN lms.modules m ON m.id=cm.module`,
  appCourseOrphans:`SELECT 'learning_goals' AS table_name,count(*)::int AS invalid FROM app.learning_goals a LEFT JOIN lms.course c ON c.id=a.course_id WHERE a.course_id IS NOT NULL AND c.id IS NULL
    UNION ALL SELECT 'learning_reminders',count(*)::int FROM app.learning_reminders a LEFT JOIN lms.course c ON c.id=a.course_id WHERE a.course_id IS NOT NULL AND c.id IS NULL`,
};
const planQueries = {
  studentRecommendationInputs:`SELECT a.id,a.duedate,ut.task_status,p.progress_percentage,p.total_tracked_activities
    FROM lms.assign a JOIN derived.unified_tasks ut ON ut.source_id=a.id AND ut.task_type='assignment'
    JOIN derived.student_course_progress p ON p.userid=ut.userid AND p.courseid=a.course
    WHERE ut.userid=201 ORDER BY a.duedate,a.id LIMIT 100`,
  studentPlan:`SELECT id,title,scheduled_start_at,status FROM app.study_plan_items
    WHERE owner_user_id=201 ORDER BY scheduled_start_at,id LIMIT 200`,
  teacherInboxInputs:`SELECT courseid,studentid,progress_percentage,total_tracked_activities,pending_tasks,overdue_tasks
    FROM derived.teacher_student_monitoring WHERE teacherid=101 ORDER BY courseid,studentid LIMIT 200`,
  teacherDueFollowups:`SELECT id,course_id,student_id,follow_up_at FROM app.teacher_interventions
    WHERE owner_teacher_id=101 AND status<>'resolved' AND follow_up_at<=now()
    ORDER BY follow_up_at,id LIMIT 200`,
  followupHistory:`SELECT f.outcome_status,f.progress_percent,f.pending_tasks,f.overdue_tasks,f.created_at
    FROM app.intervention_followups f JOIN app.teacher_interventions i ON i.id=f.intervention_id
    WHERE i.owner_teacher_id=101 ORDER BY f.intervention_id,f.created_at,f.id LIMIT 200`,
};
let db;
try {
  db=await connectCandidate();
  await db.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  await db.query("SET LOCAL statement_timeout='20s'");
  const catalog=JSON.parse(await readFile(new URL('catalog.json',output),'utf8'));
  const viewChecks=[];
  for(const v of catalog.views){
    const key=duplicateKeys[v.name].map(ident).join(',');
    const row=(await db.query(`SELECT count(*)::int AS rows FROM derived.${ident(v.name)}`)).rows[0];
    const duplicate=(await db.query(`SELECT count(*)::int AS duplicate_keys FROM
      (SELECT ${key} FROM derived.${ident(v.name)} GROUP BY ${key} HAVING count(*)>1) d`)).rows[0];
    viewChecks.push({name:v.name,...row,...duplicate});
  }
  const results={};
  for(const [name,sql] of Object.entries(checks)) results[name]=(await db.query(sql)).rows;
  const foreignKeys=(await db.query(`SELECT k.conname AS name,n.nspname AS schema_name,t.relname AS table_name,
    fn.nspname AS target_schema,ft.relname AS target_table,
    ARRAY(SELECT a.attname::text FROM unnest(k.conkey) WITH ORDINALITY x(attnum,ord)
      JOIN pg_attribute a ON a.attrelid=k.conrelid AND a.attnum=x.attnum ORDER BY ord) AS source_columns,
    ARRAY(SELECT a.attname::text FROM unnest(k.confkey) WITH ORDINALITY x(attnum,ord)
      JOIN pg_attribute a ON a.attrelid=k.confrelid AND a.attnum=x.attnum ORDER BY ord) AS target_columns
    FROM pg_constraint k JOIN pg_class t ON t.oid=k.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace
    JOIN pg_class ft ON ft.oid=k.confrelid JOIN pg_namespace fn ON fn.oid=ft.relnamespace
    WHERE k.contype='f' AND n.nspname IN('app','lms') ORDER BY 1`)).rows;
  const fkOrphans=[];
  for(const fk of foreignKeys){
    const condition=fk.source_columns.map((column,i)=>`target.${ident(fk.target_columns[i])}=source.${ident(column)}`).join(' AND ');
    const nonNull=fk.source_columns.map(c=>`source.${ident(c)} IS NOT NULL`).join(' AND ');
    const result=(await db.query(`SELECT count(*)::int AS orphans FROM ${ident(fk.schema_name)}.${ident(fk.table_name)} source
      WHERE ${nonNull} AND NOT EXISTS(SELECT 1 FROM ${ident(fk.target_schema)}.${ident(fk.target_table)} target WHERE ${condition})`)).rows[0];
    fkOrphans.push({name:fk.name,...result});
  }
  results.foreignKeyOrphans=fkOrphans;
  const queryPlans=[];
  for(const [name,sql] of Object.entries(planQueries)){
    const result=(await db.query('EXPLAIN(ANALYZE,BUFFERS,FORMAT JSON) '+sql)).rows[0]['QUERY PLAN'][0];
    queryPlans.push({name,sql,planningMs:result['Planning Time'],executionMs:result['Execution Time'],plan:result.Plan});
  }
  await db.query('ROLLBACK');
  await writeFile(new URL('semantics.json',output),JSON.stringify({auditDate:'2026-10-07',accessMode:'READ ONLY',viewChecks,checks:results},null,2)+'\n');
  await writeFile(new URL('query-plans.json',output),JSON.stringify({auditDate:'2026-10-07',scope:'Bounded SELECTs only, synthetic candidate, warm small data; not a production SLA',queryPlans},null,2)+'\n');
  console.log(JSON.stringify({viewChecks,checks:results,queryTiming:queryPlans.map(({name,planningMs,executionMs})=>({name,planningMs,executionMs}))}));
} catch(error){if(db)await db.query('ROLLBACK').catch(()=>{});console.log(JSON.stringify(safeFailure(error)));process.exitCode=1;}
finally{if(db)await db.end().catch(()=>{});}
