-- Reviewed hardening of the isolated synthetic candidate only.
-- No lms table/data changes, no new tables, no column/type/contract changes.
-- Rehearse inside a transaction and ROLLBACK before approving the application.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';
DO $$
DECLARE
  definition text;
BEGIN
  IF current_database() <> 'lms_mobile_learning_candidate' THEN
    RAISE EXCEPTION 'CANDIDATE_DATABASE_REQUIRED';
  END IF;

  definition := pg_get_viewdef('derived.student_course_learning_items'::regclass, true);
  IF strpos(definition, 'ut.task_type::text = m.name::text') = 0 THEN
    RAISE EXCEPTION 'LEARNING_VIEW_BASELINE_REVIEW_REQUIRED';
  END IF;
  definition := replace(definition,
    'ut.task_type::text = m.name::text',
    'ut.task_type::text = CASE WHEN m.name::text = ''assign'' THEN ''assignment'' ELSE m.name::text END');
  EXECUTE 'CREATE OR REPLACE VIEW derived.student_course_learning_items AS ' || definition;

  definition := pg_get_viewdef('derived.student_risk_indicator'::regclass, true);
  IF strpos(definition, 'COALESCE(e.days_since_last_activity, 999)') = 0
    OR strpos(definition, 'p.progress_percentage < 30::numeric') = 0
    OR strpos(definition, 'p.progress_percentage < 60::numeric') = 0 THEN
    RAISE EXCEPTION 'SUPPORT_VIEW_BASELINE_REVIEW_REQUIRED';
  END IF;
  -- Unknown last-activity is not 999 days of inactivity.
  definition := replace(definition, 'COALESCE(e.days_since_last_activity, 999)',
    'e.days_since_last_activity');
  -- The legacy numeric zero for a course with no tracked modules is not a signal.
  definition := replace(definition, 'p.progress_percentage < 30::numeric',
    'p.total_tracked_activities > 0 AND p.progress_percentage < 30::numeric');
  definition := replace(definition, 'p.progress_percentage < 60::numeric',
    'p.total_tracked_activities > 0 AND p.progress_percentage < 60::numeric');
  EXECUTE 'CREATE OR REPLACE VIEW derived.student_risk_indicator AS ' || definition;
END $$;

ALTER TABLE app.study_plan_items
  ADD CONSTRAINT study_plan_title_nonblank_ck CHECK (length(trim(title)) > 0),
  ADD CONSTRAINT study_plan_timestamp_order_ck CHECK (updated_at >= created_at);
ALTER TABLE app.teacher_interventions
  ADD CONSTRAINT teacher_intervention_timestamp_order_ck CHECK (updated_at >= created_at),
  ADD CONSTRAINT teacher_intervention_followup_order_ck
    CHECK (follow_up_at IS NULL OR follow_up_at >= created_at),
  ADD CONSTRAINT teacher_intervention_resolved_followup_ck
    CHECK (status <> 'resolved' OR follow_up_at IS NULL);
COMMIT;
