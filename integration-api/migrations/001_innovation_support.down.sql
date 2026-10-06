-- Explicit rollback is safe only before any app-owned records exist.
-- Export/review records and obtain user approval before any data-bearing rollback.
BEGIN;
SET LOCAL lock_timeout = '5s';
-- Exclude concurrent API inserts before checking emptiness; never lose a write
-- that races between the guard and DROP.
LOCK TABLE app.study_plan_items, app.teacher_interventions, app.intervention_followups IN ACCESS EXCLUSIVE MODE;
DO $$ BEGIN
  IF current_database() <> 'lms_mobile_learning_candidate' THEN
    RAISE EXCEPTION 'CANDIDATE_DATABASE_REQUIRED';
  END IF;
  IF EXISTS(SELECT 1 FROM app.study_plan_items)
     OR EXISTS(SELECT 1 FROM app.teacher_interventions)
     OR EXISTS(SELECT 1 FROM app.intervention_followups) THEN
    RAISE EXCEPTION 'ROLLBACK_BLOCKED_NONEMPTY_APP_DATA';
  END IF;
END $$;
DROP TABLE app.intervention_followups;
DROP TABLE app.teacher_interventions;
DROP TABLE app.study_plan_items;
COMMIT;
