-- Incremental application-owned data. Never alter the verified lms/derived model.
-- Execute only against the approved candidate; API startup does not migrate.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';
DO $$ BEGIN
  IF current_database() <> 'lms_mobile_learning_candidate' THEN
    RAISE EXCEPTION 'CANDIDATE_DATABASE_REQUIRED';
  END IF;
  IF to_regclass('lms."user"') IS NULL OR to_regclass('lms.assign') IS NULL
     OR to_regclass('derived.teacher_student_monitoring') IS NULL THEN
    RAISE EXCEPTION 'GROUP_MODEL_REQUIRED';
  END IF;
END $$;
CREATE TABLE app.study_plan_items (
  id uuid PRIMARY KEY,
  owner_user_id bigint NOT NULL REFERENCES lms."user"(id) ON DELETE RESTRICT,
  assignment_id bigint NOT NULL REFERENCES lms.assign(id) ON DELETE RESTRICT,
  course_id bigint NOT NULL REFERENCES lms.course(id) ON DELETE RESTRICT,
  assignment_code text NOT NULL,
  course_name text NOT NULL,
  title text NOT NULL,
  due_at timestamptz NOT NULL,
  priority_score integer NOT NULL CHECK (priority_score BETWEEN 0 AND 100),
  priority text NOT NULL CHECK (priority IN ('low','medium','high')),
  reasons jsonb NOT NULL CHECK (jsonb_typeof(reasons)='array'),
  scheduled_start_at timestamptz NOT NULL,
  estimated_minutes integer NOT NULL CHECK (estimated_minutes BETWEEN 5 AND 480),
  notes varchar(500) NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','handled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(owner_user_id,assignment_id)
);
CREATE INDEX study_plan_owner_schedule_idx ON app.study_plan_items(owner_user_id,scheduled_start_at,id);
CREATE INDEX study_plan_assignment_idx ON app.study_plan_items(assignment_id);
CREATE INDEX study_plan_course_idx ON app.study_plan_items(course_id);
CREATE TABLE app.teacher_interventions (
  id uuid PRIMARY KEY,
  owner_teacher_id bigint NOT NULL REFERENCES lms."user"(id) ON DELETE RESTRICT,
  student_id bigint NOT NULL REFERENCES lms."user"(id) ON DELETE RESTRICT,
  course_id bigint NOT NULL REFERENCES lms.course(id) ON DELETE RESTRICT,
  student_name text NOT NULL,
  course_name text NOT NULL,
  title varchar(120) NOT NULL CHECK (length(trim(title)) > 0),
  note varchar(500) NOT NULL CHECK (length(trim(note)) > 0),
  action_type text NOT NULL CHECK (action_type IN ('contacted','monitoring')),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','following_up','resolved')),
  follow_up_at timestamptz,
  reasons jsonb NOT NULL CHECK (jsonb_typeof(reasons)='array'),
  baseline jsonb NOT NULL CHECK (jsonb_typeof(baseline)='object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX teacher_intervention_owner_due_idx ON app.teacher_interventions(owner_teacher_id,status,follow_up_at,id);
CREATE INDEX teacher_intervention_student_idx ON app.teacher_interventions(student_id);
CREATE INDEX teacher_intervention_course_idx ON app.teacher_interventions(course_id);
CREATE UNIQUE INDEX teacher_intervention_active_scope_idx ON app.teacher_interventions(owner_teacher_id,course_id,student_id) WHERE status<>'resolved';
CREATE TABLE app.intervention_followups (
  id uuid PRIMARY KEY,
  intervention_id uuid NOT NULL REFERENCES app.teacher_interventions(id) ON DELETE RESTRICT,
  note varchar(500) NOT NULL CHECK (length(trim(note)) > 0),
  outcome_status text NOT NULL CHECK (outcome_status IN ('following_up','resolved')),
  progress_percent double precision NOT NULL CHECK (progress_percent BETWEEN 0 AND 100),
  pending_tasks integer NOT NULL CHECK (pending_tasks >= 0),
  overdue_tasks integer NOT NULL CHECK (overdue_tasks >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX intervention_followup_history_idx ON app.intervention_followups(intervention_id,created_at,id);
COMMENT ON TABLE app.study_plan_items IS 'App-only personal planning; handled does not mean submitted on LMS.';
COMMENT ON TABLE app.teacher_interventions IS 'Teacher-owned support notes; not official grades, messages, or LMS interventions.';
COMMENT ON TABLE app.intervention_followups IS 'Append-only followup history with actual scoped activity snapshots; not causal assessment.';
COMMIT;
