-- REAL-DATA-1 stage 1: load the Moodle CSV export (no header, MySQL quoting, NULL unquoted)
-- into schema stg, every column text. Run by tools/Import-RealData.ps1 as postgres:
--   psql -v ON_ERROR_STOP=1 -v datadir=D:/.../Data_11-2026 -v userfile=D:/.../dlu_user_noemail.csv -f 10_stage.sql
-- userfile = dlu_user.csv with the email column removed by tools/real-import/strip_user_email.py:
-- the email column never reaches PostgreSQL.
-- Server-side COPY (the cluster runs as the owner's Windows user on this machine).
-- Contains no data. Only touches lms_mobile_group_real.
\set ON_ERROR_STOP on
SELECT set_config('realimport.datadir', :'datadir', false);
SELECT set_config('realimport.userfile', :'userfile', false);

DO $$
BEGIN
    IF current_database() <> 'lms_mobile_group_real' THEN
        RAISE EXCEPTION 'GUARD: stage only runs on lms_mobile_group_real, not %', current_database();
    END IF;
END
$$;

DO $$
BEGIN
    IF current_database() = 'lms_mobile_group_real' THEN
        DROP SCHEMA IF EXISTS stg CASCADE;
    END IF;
END
$$;
CREATE SCHEMA stg;
REVOKE ALL ON SCHEMA stg FROM PUBLIC;
-- Import bookkeeping kept after stg is dropped (counts and notes only, no personal data).
DO $$
BEGIN
    IF current_database() = 'lms_mobile_group_real' THEN
        DROP SCHEMA IF EXISTS realimport CASCADE;
    END IF;
END
$$;
CREATE SCHEMA realimport;
REVOKE ALL ON SCHEMA realimport FROM PUBLIC;

-- name, file, expected column count (MOODLE_401_STABLE install.xml order; verified on the export).
CREATE TABLE stg.manifest (name text PRIMARY KEY, file text NOT NULL, ncols int NOT NULL, optional boolean NOT NULL DEFAULT false);
INSERT INTO stg.manifest VALUES
    ('course',             'dlu_course_cntt.csv',             36, false),
    ('course_categories',  'dlu_course_categories_cntt.csv',  14, false),
    ('course_sections',    'dlu_course_sections.csv',         10, false),
    ('course_modules',     'dlu_course_modules_cntt.csv',     21, false),
    ('modules',            'dlu_modules.csv',                  6, false),
    ('assign',             'dlu_assign.csv',                  30, false),
    ('assign_submission',  'dlu_assign_submission.csv',        9, false),
    ('assign_grades',      'dlu_assign_grades.csv',            8, false),
    ('grade_items',        'dlu_grade_items.csv',             31, false),
    ('grade_grades',       'dlu_grade_grades.csv',            23, false),
    ('quiz_attempts',      'dlu_quiz_attempts_cntt.csv',      15, false),
    ('quiz_grades',        'dlu_quiz_grades_cntt.csv',         5, false),
    ('enrol',              'dlu_enrol.csv',                   35, false),
    ('user_enrolments',    'dlu_user_enrolments.csv',          9, false),
    ('role',               'dlu_role.csv',                     6, false),
    ('role_assignments',   'dlu_role_assignments.csv',         9, false),
    ('context',            'dlu_context.csv',                  6, false),
    ('user',               '<userfile>',                       4, false),
    -- Supplied later (dlu_quiz_cntt.csv, 42 columns, Moodle 4.x). Used instead of the grade_items
    -- reconstruction when present; the first existing name wins.
    ('quiz',               'dlu_quiz_cntt.csv|dlu_quiz.csv',  -1, true);

CREATE TABLE realimport.load_log (name text PRIMARY KEY, rows bigint, seconds numeric);
CREATE TABLE realimport.import_notes (note text PRIMARY KEY, value bigint);

DO $$
DECLARE
    m record;
    dir text := rtrim(replace(current_setting('realimport.datadir'), '\', '/'), '/');
    path text;
    cols text;
    n int;
    t0 timestamptz;
    rc bigint;
BEGIN
    FOR m IN SELECT * FROM stg.manifest ORDER BY name LOOP
        path := CASE WHEN m.file = '<userfile>' THEN replace(current_setting('realimport.userfile'), '', '/')
                     ELSE dir || '/' || m.file END;
        IF m.optional THEN
            -- Alternative names separated by '|'; pg_stat_file(..., true) returns NULL when missing.
            path := NULL;
            FOREACH cols IN ARRAY string_to_array(m.file, '|') LOOP
                IF path IS NULL AND (SELECT size FROM pg_stat_file(dir || '/' || cols, true)) IS NOT NULL THEN
                    path := dir || '/' || cols;
                    INSERT INTO realimport.import_notes VALUES ('quiz file: ' || cols, 1);
                END IF;
            END LOOP;
            IF path IS NULL THEN
                RAISE NOTICE 'optional file % not present', m.file;
                CONTINUE;
            END IF;
            -- dlu_quiz.csv: column count differs between Moodle 3.x/4.x; only id(0), course(1),
            -- name(2), timeopen(5), timeclose(6), timelimit(7) are read, which are stable. Try counts.
            n := NULL;
            FOR i IN REVERSE 45..36 LOOP
                BEGIN
                    SELECT string_agg(format('c%s text', k), ', ' ORDER BY k) INTO cols FROM generate_series(0, i - 1) k;
                    EXECUTE format('CREATE TABLE stg.%I (%s)', m.name, cols);
                    EXECUTE format($f$COPY stg.%I FROM %L WITH (FORMAT csv, NULL 'NULL', ENCODING 'UTF8')$f$, m.name, path);
                    GET DIAGNOSTICS rc = ROW_COUNT;
                    n := i;
                    EXIT;
                EXCEPTION WHEN OTHERS THEN
                    NULL;  -- subtransaction rolled back (table gone); try the next count
                END;
            END LOOP;
            IF n IS NULL THEN RAISE EXCEPTION 'dlu_quiz.csv present but not readable as 36..45 columns'; END IF;
            UPDATE stg.manifest SET ncols = n WHERE name = m.name;
            INSERT INTO realimport.load_log VALUES (m.name, rc, NULL);
            CONTINUE;
        ELSE
            n := m.ncols;
        END IF;
        SELECT string_agg(format('c%s text', i), ', ' ORDER BY i) INTO cols FROM generate_series(0, n - 1) i;
        EXECUTE format('CREATE TABLE stg.%I (%s)', m.name, cols);
        t0 := clock_timestamp();
        -- CSV: "" escapes a quote, quoted NULL stays the string 'NULL', unquoted NULL becomes SQL NULL,
        -- ,, stays the empty string. A row with the wrong column count aborts the import.
        EXECUTE format($f$COPY stg.%I FROM %L WITH (FORMAT csv, NULL 'NULL', ENCODING 'UTF8')$f$, m.name, path);
        GET DIAGNOSTICS rc = ROW_COUNT;
        INSERT INTO realimport.load_log VALUES (m.name, rc, round(extract(epoch FROM clock_timestamp() - t0)::numeric, 1));
    END LOOP;
END
$$;

-- dlu_course_categories_cntt.csv starts with a UTF-8 BOM, so its first field arrives as <BOM>"7".
UPDATE stg.course_categories SET c0 = btrim(replace(c0, chr(65279), ''), '"') WHERE c0 LIKE chr(65279) || '%';

-- Casting helpers (empty string = no value).
CREATE FUNCTION stg.b(v text) RETURNS bigint LANGUAGE sql IMMUTABLE AS $$ SELECT NULLIF(btrim(v), '')::numeric::bigint $$;
CREATE FUNCTION stg.n(v text) RETURNS numeric LANGUAGE sql IMMUTABLE AS $$ SELECT NULLIF(btrim(v), '')::numeric $$;

CREATE INDEX ON stg.grade_grades (c1);
CREATE INDEX ON stg.assign_submission (c1);
CREATE INDEX ON stg.assign_grades (c1);
CREATE INDEX ON stg.user_enrolments (c2);
CREATE INDEX ON stg.role_assignments (c2);
ANALYZE stg.grade_grades;

SELECT name, rows, seconds FROM realimport.load_log ORDER BY name;
