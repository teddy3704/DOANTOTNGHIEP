[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
# Owner-run restore of the approved dump into a NEW database on the group cluster (D:, 127.0.0.1:55432),
# then read-only T08 catalog verification and E4 demo-ID aggregates on fresh connections.
# The postgres password is typed once at a hidden prompt and kept only in this process's environment.
# Nothing is printed except exit codes and output file paths; logs stay on D.
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$pgData = 'D:\DLU-LMS\PostgreSQL\data'
$pgLogs = 'D:\DLU-LMS\PostgreSQL\logs'
$dump = 'D:\DLU-LMS-Group\database\lms_mobile_learning_backup.sql'
$dumpSha256 = '936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4'
$database = 'lms_mobile_group_dev'
$verifySql = Join-Path (Split-Path $PSScriptRoot) 'database\verify_group_catalog.sql'
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
$psql = Join-Path $pgBin 'psql.exe'
$conn = @('-X', '-h', '127.0.0.1', '-p', '55432', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if (((Get-PSDrive C).Free / 1GB) -lt 15) { throw 'STORAGE_BLOCKED' }
if ((Get-FileHash -LiteralPath $dump -Algorithm SHA256).Hash -ne $dumpSha256) { throw 'Dump SHA-256 mismatch; stopping.' }
$pidFile = Get-Content (Join-Path $pgData 'postmaster.pid')
if ($pidFile[1] -ne 'D:/DLU-LMS/PostgreSQL/data' -or $pidFile[3] -ne '55432' -or $pidFile[5] -ne '127.0.0.1') { throw 'Cluster is not the verified D: instance on 127.0.0.1:55432.' }

$secure = Read-Host -AsSecureString 'Password for cluster role postgres'
$env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password
try {
    $exists = & $psql @conn -d postgres -tA -c "SELECT count(*) FROM pg_database WHERE datname = '$database'"
    if ($LASTEXITCODE -ne 0) { throw "Connection check failed (exit $LASTEXITCODE)." }
    if ($exists.Trim() -ne '0') { throw "$database already exists; stopping without changes." }

    & $psql @conn -d postgres -q -c "CREATE DATABASE $database OWNER postgres TEMPLATE template0 ENCODING 'UTF8'"
    Write-Output "create_database exit=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { throw 'CREATE DATABASE failed.' }

    # Approved restore command; VERBOSITY/SHOW_CONTEXT only keep row values out of error text.
    $restoreLog = Join-Path $pgLogs "restore-$stamp.log"
    & $psql @conn -d $database --single-transaction -v VERBOSITY=sqlstate -v SHOW_CONTEXT=never -f $dump *> $restoreLog
    $restoreExit = $LASTEXITCODE
    Write-Output "restore exit=$restoreExit log=$restoreLog"
    if ($restoreExit -ne 0) {
        Select-String -LiteralPath $restoreLog -Pattern '^psql:.*?:(\d+): ERROR:\s+(\w+)' | ForEach-Object {
            Write-Output "error at SQL line $($_.Matches[0].Groups[1].Value), SQLSTATE $($_.Matches[0].Groups[2].Value)"
        }
        throw 'Restore failed; transaction rolled back. No retry, no DROP.'
    }

    $verifyOut = Join-Path $pgLogs "t08-verify-$stamp.txt"
    & $psql @conn -d $database -v "expected_database=$database" -f $verifySql *> $verifyOut
    Write-Output "t08_verify exit=$LASTEXITCODE out=$verifyOut"

    $demoOut = Join-Path $pgLogs "e4-demo-ids-$stamp.txt"
    $demoSql = @'
BEGIN READ ONLY;
SELECT 'student' AS kind, userid AS id, count(DISTINCT courseid) AS courses
FROM derived.student_course_progress GROUP BY userid
ORDER BY (userid = 205) DESC, count(DISTINCT courseid) DESC, userid LIMIT 3;
SELECT 'teacher' AS kind, teacherid AS id, count(DISTINCT courseid) AS courses
FROM derived.teacher_course_overview GROUP BY teacherid
ORDER BY (teacherid = 102) DESC, count(DISTINCT courseid) DESC, teacherid LIMIT 3;
ROLLBACK;
'@
    $demoSql | & $psql @conn -d $database -f - *> $demoOut
    Write-Output "e4_demo_ids exit=$LASTEXITCODE out=$demoOut"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $secure.Dispose()
}
