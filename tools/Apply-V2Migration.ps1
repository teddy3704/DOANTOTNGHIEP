[CmdletBinding()]
param(
    [string]$MigrationFile = (Join-Path (Split-Path $PSScriptRoot) 'database\migrations\2026-11-08_v2_features.sql'),
    # DOI_NGAY_DEMO: also build the separate demo copy with shifted Moodle dates.
    [switch]$CreateDemo,
    # Day the demo should look "current" (deadlines due in the following 1–7 days). Default: today.
    [string]$DemoTargetDate = (Get-Date -Format 'yyyy-MM-dd')
)
$ErrorActionPreference = 'Stop'
# Owner-run (normal PowerShell, not elevated). One hidden prompt for the postgres password, kept only
# in this process's environment. Prints exit codes, aggregate privilege tables and file paths only.
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$pgData = 'D:\DLU-LMS\PostgreSQL\data'
$pgLogs = 'D:\DLU-LMS\PostgreSQL\logs'
$backups = 'D:\DLU-LMS\Backups'
$root = Split-Path $PSScriptRoot
$grants = Join-Path $root 'database\grants_lms_group_app.sql'
$shiftSql = Join-Path $root 'database\demo\shift_demo_dates.sql'
$dump = Join-Path $root 'database\lms_mobile_learning_backup.sql'
$dumpSha256 = '936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4'
$devDb = 'lms_mobile_group_dev'
$demoDb = 'lms_mobile_group_demo'
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
$psql = Join-Path $pgBin 'psql.exe'
$pgDump = Join-Path $pgBin 'pg_dump.exe'
$conn = @('-X', '-h', '127.0.0.1', '-p', '55432', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $pgLogs "v2-migration-$stamp.log"

# ---------------------------------------------------------------- safety checks (no password yet)
if (((Get-PSDrive C).Free / 1GB) -lt 15) { throw 'STORAGE_BLOCKED: drive C has less than 15 GiB free.' }
if (-not (Test-Path -LiteralPath $MigrationFile)) { throw "Migration file not found: $MigrationFile" }
$pidFile = Get-Content (Join-Path $pgData 'postmaster.pid')
if ($pidFile[1] -ne 'D:/DLU-LMS/PostgreSQL/data' -or $pidFile[3] -ne '55432' -or $pidFile[5] -ne '127.0.0.1') {
    throw 'Cluster is not the verified D: instance on 127.0.0.1:55432.'
}
if ($CreateDemo) {
    if ($DemoTargetDate -notmatch '^\d{4}-\d{2}-\d{2}$') { throw 'DemoTargetDate must be yyyy-MM-dd.' }
    if ((Get-FileHash -LiteralPath $dump -Algorithm SHA256).Hash -ne $dumpSha256) { throw 'Dump SHA-256 mismatch; stopping.' }
}
New-Item -ItemType Directory -Force $backups | Out-Null

function Invoke-Psql([string[]]$Arguments, [string]$Label) {
    & $psql @conn @Arguments *>> $log
    Write-Output "$Label exit=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { throw "$Label failed; see $log (no retry, nothing dropped)." }
}

function Write-PrivilegeReport([string]$Database) {
    $report = @'
SELECT current_database() AS database;
SELECT rolsuper, rolcreatedb, rolcreaterole, rolreplication, rolbypassrls, rolcanlogin
FROM pg_roles WHERE rolname = 'lms_group_app';
SELECT table_schema, privilege_type, count(*) AS objects
FROM information_schema.role_table_grants WHERE grantee = 'lms_group_app'
GROUP BY 1, 2 ORDER BY 1, 2;
SELECT table_name, string_agg(privilege_type, ',' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE grantee = 'lms_group_app' AND table_schema = 'app'
GROUP BY 1 ORDER BY 1;
SELECT s.schemaname, s.sequencename,
       has_sequence_privilege('lms_group_app', format('%I.%I', s.schemaname, s.sequencename), 'USAGE') AS usage
FROM pg_sequences s WHERE s.schemaname = 'app' ORDER BY 2;
SELECT has_schema_privilege('lms_group_app', 'lms', 'CREATE') AS lms_create,
       has_schema_privilege('lms_group_app', 'app', 'CREATE') AS app_create,
       has_database_privilege('lms_group_app', current_database(), 'CREATE') AS db_create;
'@
    $out = Join-Path $pgLogs "v2-privileges-$Database-$stamp.txt"
    $report | & $psql @conn -d $Database -f - *> $out
    Write-Output "privilege report $Database exit=$LASTEXITCODE out=$out"
    Get-Content $out | Write-Output
}

$secure = Read-Host -AsSecureString 'Password for cluster role postgres'
$env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password
try {
    $exists = & $psql @conn -d postgres -tA -c "SELECT count(*) FROM pg_database WHERE datname = '$devDb'"
    if ($LASTEXITCODE -ne 0) { throw "Connection check failed (exit $LASTEXITCODE)." }
    if ($exists.Trim() -ne '1') { throw "$devDb does not exist; stopping." }

    # 1. Back up schema app of the dev database before any DDL.
    $backup = Join-Path $backups "app-before-v2-$stamp.sql"
    & $pgDump -h 127.0.0.1 -p 55432 -U postgres -d $devDb -n app -f $backup *>> $log
    Write-Output "pg_dump app exit=$LASTEXITCODE file=$backup"
    if ($LASTEXITCODE -ne 0) { throw 'Backup failed; migration not started.' }
    Write-Output ("backup sha256=" + (Get-FileHash -LiteralPath $backup).Hash)

    # 2. Migration in one transaction, then grants.
    Invoke-Psql @('-d', $devDb, '--single-transaction', '-f', $MigrationFile) "migration $devDb"
    Invoke-Psql @('-d', $devDb, '-f', $grants) "grants $devDb"
    Write-PrivilegeReport $devDb

    # 3. Optional demo copy with shifted dates (DOI_NGAY_DEMO=CO).
    if ($CreateDemo) {
        $demoExists = & $psql @conn -d postgres -tA -c "SELECT count(*) FROM pg_database WHERE datname = '$demoDb'"
        if ($demoExists.Trim() -ne '0') { throw "$demoDb already exists; stopping without changes to it." }
        Invoke-Psql @('-d', 'postgres', '-q', '-c', "CREATE DATABASE $demoDb OWNER postgres TEMPLATE template0 ENCODING 'UTF8'") "create $demoDb"
        $restoreLog = Join-Path $pgLogs "restore-demo-$stamp.log"
        & $psql @conn -d $demoDb --single-transaction -v VERBOSITY=sqlstate -v SHOW_CONTEXT=never -f $dump *> $restoreLog
        Write-Output "restore $demoDb exit=$LASTEXITCODE log=$restoreLog"
        if ($LASTEXITCODE -ne 0) { throw 'Demo restore failed; transaction rolled back. No retry, no DROP.' }
        $shiftOut = Join-Path $pgLogs "demo-shift-$stamp.txt"
        & $psql @conn -d $demoDb --single-transaction -v "target_date=$DemoTargetDate" -f $shiftSql *> $shiftOut
        Write-Output "date shift $demoDb exit=$LASTEXITCODE out=$shiftOut"
        if ($LASTEXITCODE -ne 0) { throw 'Date shift failed; rolled back.' }
        Get-Content $shiftOut | Write-Output
        Invoke-Psql @('-d', $demoDb, '--single-transaction', '-f', $MigrationFile) "migration $demoDb"
        Invoke-Psql @('-d', $demoDb, '-f', $grants) "grants $demoDb"
        Write-PrivilegeReport $demoDb
    }
    Write-Output "log=$log"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $secure.Dispose()
}
