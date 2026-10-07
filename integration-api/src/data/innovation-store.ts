import { randomUUID } from "node:crypto";
import type pg from "pg";
import type { QueryResultRow } from "pg";
import type {
  Attention,
  FollowupCreate,
  InnovationStore,
  Intervention,
  InterventionCreate,
  InterventionPatch,
  PlanCreate,
  PlanItem,
  PlanPatch,
  Recommendation,
  Snapshot,
} from "../domain/innovation.ts";
import { snapshotOf } from "../domain/innovation.ts";
import {
  studentIds,
  studentScope,
  teacherIds,
  teacherScope,
  visibleAssign,
} from "./group-scope.ts";

// Separate writer from PostgresReadDatabase: only reviewed statements owned by
// this module run here. No HTTP input can provide table names or SQL fragments.
export interface AppDatabase {
  transaction<T>(operation: (client: AppQuery) => Promise<T>): Promise<T>;
}
export interface AppQuery {
  query<T extends QueryResultRow>(
    sql: string,
    values?: readonly unknown[],
  ): Promise<T[]>;
}
export class PostgresAppDatabase implements AppDatabase {
  private readonly pool: pg.Pool;
  constructor(pool: pg.Pool) {
    this.pool = pool;
  }
  async transaction<T>(
    operation: (client: AppQuery) => Promise<T>,
  ): Promise<T> {
    const client = await this.pool.connect();
    let discard = false;
    try {
      await client.query("BEGIN");
      await client.query("SET LOCAL statement_timeout = '10s'");
      await client.query("SET LOCAL lock_timeout = '5s'");
      const result = await operation({
        query: async <R extends QueryResultRow>(
          sql: string,
          values: readonly unknown[] = [],
        ) => (await client.query<R>(sql, [...values])).rows,
      });
      await client.query("COMMIT");
      return result;
    } catch (error) {
      await client.query("ROLLBACK").catch(() => {
        discard = true;
      });
      throw error;
    } finally {
      client.release(discard);
    }
  }
}
const planProjection = `p.id::text AS id,p.assignment_id::text AS "assignmentId",p.assignment_code AS "assignmentCode",p.course_id::text AS "courseId",
p.course_name AS "courseName",p.title,p.due_at AS "dueAt",p.priority_score AS "priorityScore",p.priority,p.reasons,
p.scheduled_start_at AS "scheduledStartAt",p.estimated_minutes AS "estimatedMinutes",p.notes,p.status,p.created_at AS "createdAt",p.updated_at AS "updatedAt"`;
const planAccess = `p.owner_user_id=$1::bigint AND EXISTS(SELECT 1 FROM scoped_courses c JOIN lms.assign a ON a.course=c.id WHERE a.id=p.assignment_id AND a.course=p.course_id AND ${visibleAssign})`;
// Course permission alone is insufficient: current active student enrolment and
// course-level student role are required for every teacher read/write.
export const interventionAccess = `i.owner_teacher_id=$1::bigint AND EXISTS(
 SELECT 1 FROM scoped_courses c JOIN lms."user" u ON u.id=i.student_id AND u.deleted=0 AND u.suspended=0
 JOIN lms.user_enrolments ue ON ue.userid=u.id AND ue.status=0
 JOIN lms.enrol e ON e.id=ue.enrolid AND e.status=0 AND e.courseid=c.id
 JOIN lms.context ctx ON ctx.contextlevel=50 AND ctx.instanceid=c.id
 JOIN lms.role_assignments ra ON ra.userid=u.id AND ra.contextid=ctx.id
 JOIN lms.role r ON r.id=ra.roleid AND (r.shortname='student' OR r.archetype='student')
 WHERE c.id=i.course_id AND (ue.timestart=0 OR ue.timestart<=extract(epoch FROM now()))
 AND (ue.timeend=0 OR ue.timeend>extract(epoch FROM now())))`;
const interventionProjection = `i.id::text AS id,i.course_id::text AS "courseId",i.student_id::text AS "studentId",i.student_name AS "studentName",i.course_name AS "courseName",
i.title,i.note,i.action_type AS "actionType",i.status,i.follow_up_at AS "followUpAt",i.created_at AS "createdAt",i.updated_at AS "updatedAt",i.reasons,i.baseline,i.baseline AS current,
coalesce((SELECT jsonb_agg(jsonb_build_object('id',f.id::text,'note',f.note,'createdAt',f.created_at,'outcomeStatus',f.outcome_status,'progressPercent',f.progress_percent,'pendingTasks',f.pending_tasks,'overdueTasks',f.overdue_tasks) ORDER BY f.created_at,f.id)
FROM app.intervention_followups f WHERE f.intervention_id=i.id),'[]'::jsonb) AS followups`;
const normalize = <T>(row: QueryResultRow): T =>
  Object.fromEntries(
    Object.entries(row).map(([k, v]) => [
      k,
      v instanceof Date ? v.toISOString() : v,
    ]),
  ) as T;
const first = <T>(rows: QueryResultRow[]): T | null =>
  rows[0] ? normalize<T>(rows[0]) : null;
export class PostgresInnovationStore implements InnovationStore {
  private readonly db: AppDatabase;
  constructor(db: AppDatabase) {
    this.db = db;
  }
  async plans(code: string): Promise<PlanItem[]> {
    if (!studentIds[code]) return [];
    return this.db.transaction(async (q) =>
      (
        await q.query(
          studentScope +
            ` SELECT ${planProjection} FROM app.study_plan_items p WHERE ${planAccess} ORDER BY p.scheduled_start_at,p.id`,
          [studentIds[code]],
        )
      ).map(normalize<PlanItem>),
    );
  }
  async createPlan(
    code: string,
    r: Recommendation,
    input: PlanCreate,
  ): Promise<PlanItem | null> {
    if (!studentIds[code]) return null;
    return this.db.transaction(async (q) =>
      first<PlanItem>(
        await q.query(
          studentScope +
            `
      INSERT INTO app.study_plan_items AS p(id,owner_user_id,assignment_id,course_id,assignment_code,course_name,title,due_at,priority_score,priority,reasons,scheduled_start_at,estimated_minutes,notes)
      SELECT $2::uuid,$1::bigint,a.id,c.id,$4,$5,$6,$7::timestamptz,$8,$9,$10::jsonb,$11::timestamptz,$12,$13
      FROM scoped_courses c JOIN lms.assign a ON a.course=c.id WHERE a.id=$3::bigint AND ${visibleAssign}
      ON CONFLICT(owner_user_id,assignment_id) DO NOTHING RETURNING ${planProjection}`,
          [
            studentIds[code],
            randomUUID(),
            r.assignmentId,
            r.assignmentCode,
            r.courseName,
            r.assignmentName,
            r.dueAt,
            r.priorityScore,
            r.priority,
            JSON.stringify(r.reasons),
            input.scheduledStartAt,
            input.estimatedMinutes ?? r.recommendedDurationMinutes,
            input.notes ?? "",
          ],
        ),
      ),
    );
  }
  async updatePlan(
    code: string,
    id: string,
    patch: PlanPatch,
  ): Promise<PlanItem | null> {
    if (!studentIds[code]) return null;
    return this.db.transaction(async (q) =>
      first<PlanItem>(
        await q.query(
          studentScope +
            ` UPDATE app.study_plan_items p SET scheduled_start_at=coalesce($3::timestamptz,p.scheduled_start_at),estimated_minutes=coalesce($4::integer,p.estimated_minutes),notes=coalesce($5::text,p.notes),status=coalesce($6::text,p.status),updated_at=now() WHERE p.id=$2::uuid AND ${planAccess}
            AND NOT(p.status='handled' AND ($3::timestamptz IS NOT NULL OR $4::integer IS NOT NULL OR coalesce($6::text,p.status)='planned')) RETURNING ${planProjection}`,
          [
            studentIds[code],
            id,
            patch.scheduledStartAt ?? null,
            patch.estimatedMinutes ?? null,
            patch.notes ?? null,
            patch.status ?? null,
          ],
        ),
      ),
    );
  }
  async deletePlan(code: string, id: string): Promise<boolean> {
    if (!studentIds[code]) return false;
    return this.db.transaction(
      async (q) =>
        (
          await q.query(
            studentScope +
              ` DELETE FROM app.study_plan_items p WHERE p.id=$2::uuid AND ${planAccess} RETURNING p.id`,
            [studentIds[code], id],
          )
        ).length === 1,
    );
  }
  private async record(
    q: AppQuery,
    teacherId: string,
    id: string,
  ): Promise<Intervention | null> {
    return first<Intervention>(
      await q.query(
        teacherScope +
          ` SELECT ${interventionProjection} FROM app.teacher_interventions i WHERE i.id=$2::uuid AND ${interventionAccess}`,
        [teacherId, id],
      ),
    );
  }
  async interventions(code: string): Promise<Intervention[]> {
    if (!teacherIds[code]) return [];
    return this.db.transaction(async (q) =>
      (
        await q.query(
          teacherScope +
            ` SELECT ${interventionProjection} FROM app.teacher_interventions i WHERE ${interventionAccess} ORDER BY i.created_at DESC,i.id`,
          [teacherIds[code]],
        )
      ).map(normalize<Intervention>),
    );
  }
  async createIntervention(
    code: string,
    a: Attention,
    input: InterventionCreate,
  ): Promise<Intervention | null> {
    const teacherId = teacherIds[code];
    if (!teacherId) return null;
    return this.db.transaction(async (q) => {
      const id = randomUUID();
      // Serialize per-owner creation so the storage bound also holds under races.
      await q.query("SELECT pg_advisory_xact_lock(7361,$1::integer)", [
        teacherId,
      ]);
      // The proposed row is scoped exactly like an existing row before INSERT.
      const rows = await q.query(
        teacherScope +
          `, proposed AS (SELECT $1::bigint AS owner_teacher_id,$3::bigint AS student_id,$4::bigint AS course_id)
      INSERT INTO app.teacher_interventions(id,owner_teacher_id,student_id,course_id,student_name,course_name,title,note,action_type,follow_up_at,reasons,baseline)
      SELECT $2::uuid,i.owner_teacher_id,i.student_id,i.course_id,$5,$6,$7,$8,$9,$10::timestamptz,$11::jsonb,$12::jsonb FROM proposed i WHERE ${interventionAccess}
      AND (SELECT count(*) FROM app.teacher_interventions WHERE owner_teacher_id=$1::bigint)<200
      ON CONFLICT DO NOTHING RETURNING id`,
        [
          teacherId,
          id,
          a.studentId,
          a.courseId,
          a.studentName,
          a.courseName,
          input.title.trim(),
          input.note.trim(),
          input.actionType,
          input.followUpAt,
          JSON.stringify(a.reasons),
          JSON.stringify(snapshotOf(a)),
        ],
      );
      return rows.length ? this.record(q, teacherId, id) : null;
    });
  }
  async updateIntervention(
    code: string,
    id: string,
    patch: InterventionPatch,
  ): Promise<Intervention | null> {
    const teacherId = teacherIds[code];
    if (!teacherId) return null;
    return this.db.transaction(async (q) => {
      const rows = await q.query(
        teacherScope +
          ` UPDATE app.teacher_interventions i SET title=coalesce($3::text,i.title),note=coalesce($4::text,i.note),action_type=coalesce($5::text,i.action_type),status=coalesce($6::text,i.status),follow_up_at=CASE WHEN coalesce($6::text,i.status)='resolved' THEN NULL WHEN $7::boolean THEN $8::timestamptz ELSE i.follow_up_at END,updated_at=now() WHERE i.id=$2::uuid AND ${interventionAccess}
          AND i.status<>'resolved' AND NOT(i.status='following_up' AND coalesce($6::text,i.status)='open') RETURNING i.id`,
        [
          teacherId,
          id,
          patch.title?.trim() ?? null,
          patch.note?.trim() ?? null,
          patch.actionType ?? null,
          patch.status ?? null,
          Object.hasOwn(patch, "followUpAt"),
          patch.followUpAt ?? null,
        ],
      );
      return rows.length ? this.record(q, teacherId, id) : null;
    });
  }
  async addFollowup(
    code: string,
    id: string,
    snapshot: Snapshot,
    input: FollowupCreate,
  ): Promise<Intervention | null> {
    const teacherId = teacherIds[code];
    if (!teacherId) return null;
    return this.db.transaction(async (q) => {
      const rows = await q.query(
        teacherScope +
          ` SELECT i.id FROM app.teacher_interventions i WHERE i.id=$2::uuid AND i.status<>'resolved' AND ${interventionAccess} FOR UPDATE OF i`,
        [teacherId, id],
      );
      if (!rows.length) return null;
      // Serialize on the parent first. A rapid identical retry should return the
      // existing state, not append duplicate history. Distinct notes, outcomes,
      // snapshots or next dates still constitute a genuine new follow-up.
      const duplicate = await q.query(
        `SELECT f.id FROM app.intervention_followups f JOIN app.teacher_interventions i ON i.id=f.intervention_id
        WHERE f.intervention_id=$2::uuid AND i.owner_teacher_id=$1::bigint AND f.note=$3 AND f.outcome_status=$4
        AND f.progress_percent=$5 AND f.pending_tasks=$6 AND f.overdue_tasks=$7
        AND f.created_at>=now()-interval '5 seconds'
        AND (NOT $8::boolean OR i.follow_up_at IS NOT DISTINCT FROM $9::timestamptz) LIMIT 1`,
        [
          teacherId,
          id,
          input.note.trim(),
          input.outcomeStatus,
          snapshot.progressPercent,
          snapshot.pendingTasks,
          snapshot.overdueTasks,
          Object.hasOwn(input, "nextFollowUpAt"),
          input.nextFollowUpAt ?? null,
        ],
      );
      if (duplicate.length) return this.record(q, teacherId, id);
      const inserted = await q.query(
        `INSERT INTO app.intervention_followups(id,intervention_id,note,outcome_status,progress_percent,pending_tasks,overdue_tasks) SELECT $1::uuid,$2::uuid,$3,$4,$5,$6,$7 WHERE (SELECT count(*) FROM app.intervention_followups WHERE intervention_id=$2::uuid)<100 RETURNING id`,
        [
          randomUUID(),
          id,
          input.note.trim(),
          input.outcomeStatus,
          snapshot.progressPercent,
          snapshot.pendingTasks,
          snapshot.overdueTasks,
        ],
      );
      if (!inserted.length) return null;
      await q.query(
        `UPDATE app.teacher_interventions SET status=$3,follow_up_at=CASE WHEN $3='resolved' THEN NULL WHEN $4::boolean THEN $5::timestamptz ELSE follow_up_at END,updated_at=now() WHERE id=$2::uuid AND owner_teacher_id=$1::bigint`,
        [
          teacherId,
          id,
          input.outcomeStatus,
          Object.hasOwn(input, "nextFollowUpAt"),
          input.nextFollowUpAt ?? null,
        ],
      );
      return this.record(q, teacherId, id);
    });
  }
}
