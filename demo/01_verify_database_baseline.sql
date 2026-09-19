-- Read-only. Counts are observations, not hard-coded assertions.
-- Scope: the project's lms/app/derived schemas, not PostgreSQL system schemas.
WITH physical AS (
  SELECT c.oid, n.nspname
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname IN ('lms', 'app', 'derived') AND c.relkind IN ('r', 'p')
)
SELECT current_database() AS database_name,
  (SELECT count(*) FROM pg_catalog.pg_namespace
   WHERE nspname IN ('lms', 'app', 'derived')) AS schemas,
  (SELECT count(*) FROM physical) AS physical_tables,
  (SELECT count(*) FROM physical WHERE nspname = 'lms') AS lms_tables,
  (SELECT count(*) FROM physical WHERE nspname = 'app') AS app_tables,
  (SELECT count(*) FROM pg_catalog.pg_class c
   JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'derived' AND c.relkind = 'v') AS derived_views,
  (SELECT count(*) FROM pg_catalog.pg_class c
   JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'lms' AND c.relkind = 'v') AS lms_views,
  (SELECT count(*) FROM pg_catalog.pg_constraint
   WHERE conrelid IN (SELECT oid FROM physical) AND contype = 'p') AS primary_keys,
  (SELECT count(*) FROM pg_catalog.pg_constraint
   WHERE conrelid IN (SELECT oid FROM physical) AND contype = 'f') AS physical_foreign_keys,
  (SELECT count(*) FROM pg_catalog.pg_attribute
   WHERE attrelid IN (SELECT oid FROM physical)
     AND attnum > 0 AND NOT attisdropped) AS physical_columns;
