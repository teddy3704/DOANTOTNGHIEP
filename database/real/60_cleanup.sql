-- REAL-DATA-1 stage 6: drop the staging copy of the export (university-wide rows, not needed after
-- the load). realimport keeps only counts and notes. Guarded to lms_mobile_group_real.
\set ON_ERROR_STOP on
DO $$
BEGIN
    IF current_database() <> 'lms_mobile_group_real' THEN
        RAISE EXCEPTION 'GUARD: cleanup only on lms_mobile_group_real';
    END IF;
    DROP SCHEMA IF EXISTS stg CASCADE;
END
$$;
VACUUM ANALYZE;
