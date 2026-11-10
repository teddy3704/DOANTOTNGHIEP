[CmdletBinding()]
param([switch]$ReportOnly)
$ErrorActionPreference = 'Stop'
# Owner-run: create the least-privilege backend role, let the owner set its password with psql's
# \password prompt, apply database/grants_lms_group_app.sql, print an aggregate privilege summary and
# run a BEGIN/ROLLBACK smoke test as that role. The postgres password is typed once (hidden prompt).
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$pgLogs = 'D:\DLU-LMS\PostgreSQL\logs'
$database = 'lms_mobile_group_dev'
$grants = Join-Path (Split-Path $PSScriptRoot) 'database\grants_lms_group_app.sql'
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
$psql = Join-Path $pgBin 'psql.exe'
$conn = @('-X', '-h', '127.0.0.1', '-p', '55432', '-U', 'postgres', '-d', $database, '-v', 'ON_ERROR_STOP=1')
$out = Join-Path $pgLogs ("runtime-role-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

$secure = Read-Host -AsSecureString 'Password for cluster role postgres'
$env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password
try {
    $exists = & $psql @conn -tA -c "SELECT count(*) FROM pg_roles WHERE rolname = 'lms_group_app'"
    if ($LASTEXITCODE -ne 0) { throw "Connection failed (exit $LASTEXITCODE)." }
    if ($ReportOnly) {
        if ($exists.Trim() -ne '1') { throw 'Role lms_group_app does not exist.' }
    } else {
        if ($exists.Trim() -ne '0') { throw 'Role lms_group_app already exists; stopping without changes.' }

        & $psql @conn -q -c 'CREATE ROLE lms_group_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
        if ($LASTEXITCODE -ne 0) { throw 'CREATE ROLE failed.' }
        Write-Output 'Set the lms_group_app password (typed twice, hidden; do not reuse the postgres password):'
        & $psql @conn -c '\password lms_group_app'
        if ($LASTEXITCODE -ne 0) { throw '\password failed.' }

        & $psql @conn -q -f $grants
        Write-Output "grants exit=$LASTEXITCODE"
        if ($LASTEXITCODE -ne 0) { throw 'Applying grants failed.' }
    }

    $report = @'
SELECT rolsuper, rolcreatedb, rolcreaterole, rolreplication, rolbypassrls, rolcanlogin,
       rolpassword IS NOT NULL AS has_password
FROM pg_authid WHERE rolname = 'lms_group_app';
SELECT table_schema, privilege_type, count(*) AS objects
FROM information_schema.role_table_grants WHERE grantee = 'lms_group_app'
GROUP BY 1, 2 ORDER BY 1, 2;
SELECT s.schemaname AS schema, s.sequencename AS sequence,
       has_sequence_privilege('lms_group_app', format('%I.%I', s.schemaname, s.sequencename), 'USAGE') AS usage,
       has_sequence_privilege('lms_group_app', format('%I.%I', s.schemaname, s.sequencename), 'UPDATE') AS update_priv
FROM pg_sequences s WHERE s.schemaname IN ('lms', 'app') ORDER BY 1, 2;
SELECT has_database_privilege('lms_group_app', current_database(), 'CREATE') AS db_create,
       has_database_privilege('lms_group_app', current_database(), 'TEMP') AS db_temp,
       has_schema_privilege('lms_group_app', 'lms', 'CREATE') AS lms_create,
       has_schema_privilege('lms_group_app', 'app', 'CREATE') AS app_create,
       has_schema_privilege('lms_group_app', 'public', 'CREATE') AS public_create;
\set ON_ERROR_STOP off
BEGIN;
SET LOCAL ROLE lms_group_app;
SELECT 'smoke_read_derived' AS check, count(*) >= 0 AS ok FROM derived.student_dashboard;
SAVEPOINT s1;
INSERT INTO lms.course (id) VALUES (-1);
ROLLBACK TO SAVEPOINT s1;
SAVEPOINT s2;
DELETE FROM app.notifications WHERE false;
ROLLBACK TO SAVEPOINT s2;
ROLLBACK;
'@
    $report | & $psql @conn -v VERBOSITY=terse -f - *> $out
    Write-Output "report exit=$LASTEXITCODE out=$out"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $secure.Dispose()
}
