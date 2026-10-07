-- Candidate-only follow-up to the corrected assignment task-state join.
-- A completed official task must not be the next learning item solely because
-- its independent completion tracker has not been updated. Resources/folders
-- still use tracker/view semantics; NULL source state is not inferred complete.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';
DO $$ BEGIN
  IF current_database() <> 'lms_mobile_learning_candidate' THEN
    RAISE EXCEPTION 'CANDIDATE_DATABASE_REQUIRED';
  END IF;
  IF to_regclass('derived.student_course_learning_items') IS NULL THEN
    RAISE EXCEPTION 'GROUP_MODEL_REQUIRED';
  END IF;
END $$;
CREATE OR REPLACE VIEW derived.student_continue_learning AS
WITH candidates AS (
  SELECT li.userid, li.courseid, li.course_name, li.section_id,
    li.section_number, li.section_name, li.coursemoduleid, li.activity_type,
    li.source_id, li.activity_name, li.due_time, li.completionstate,
    li.viewed, li.task_status,
    row_number() OVER (
      PARTITION BY li.userid, li.courseid
      ORDER BY li.section_number, li.coursemoduleid
    ) AS recommendation_rank
  FROM derived.student_course_learning_items li
  WHERE li.activity_type IN ('resource', 'folder', 'assign', 'quiz')
    AND (
      (li.completion_tracking <> 0 AND li.completionstate NOT IN (1, 2, 3))
      OR (li.completion_tracking = 0 AND li.activity_type IN ('resource', 'folder'))
    )
    AND (li.activity_type NOT IN ('assign', 'quiz')
      OR li.task_status IS DISTINCT FROM 'completed')
)
SELECT userid, courseid, course_name, section_id, section_number, section_name,
  coursemoduleid, activity_type, source_id, activity_name, due_time,
  completionstate, viewed, task_status,
  'next_learning_item'::text AS recommendation_basis
FROM candidates
WHERE recommendation_rank = 1;
COMMIT;
