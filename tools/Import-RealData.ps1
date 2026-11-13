[CmdletBinding()]
param(
    # Folder holding the dlu_*.csv export. Must be OUTSIDE the repository.
    [string]$DataDir = 'D:\DLU-LMS\RealData\Data_11-2026\Data_11-2026',
    # Drop and rebuild lms_mobile_group_real (only that database; name is a constant below).
    [switch]$Recreate,
    # Database whose schema (DDL + grants, no rows) is copied. Read-only use (pg_dump --schema-only).
    [string]$SchemaFrom = 'lms_mobile_group_demo',
    # Agent test runs only: a throwaway trust-auth cluster on another port. The group cluster is 55432.
    [int]$Port = 55432,
    [switch]$NoPasswordPrompt
)
$ErrorActionPreference = 'Stop'
# REAL-DATA-1 — owner-run import of the real Moodle export (Khoa CNTT) into lms_mobile_group_real.
# The postgres password is typed once at a hidden prompt (SecureString) and kept only in this process.
# Never touches lms_mobile_group_demo / lms_mobile_group_dev except a read-only schema dump of $SchemaFrom.
# No row data is printed: only counts. Report: D:\DLU-LMS\RealData\import-report-<time>.txt (outside the repo).
$database = 'lms_mobile_group_real'          # constant: every DROP below is limited to this name
$root = Split-Path $PSScriptRoot
$sqlDir = Join-Path $root 'database\real'
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$psql = Join-Path $pgBin 'psql.exe'
$pgDump = Join-Path $pgBin 'pg_dump.exe'
$workDir = 'D:\DLU-LMS\RealData\work'
$reportDir = 'D:\DLU-LMS\RealData'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$env:TEMP = 'D:\DLU-LMS\Temp'; $env:TMP = $env:TEMP
$conn = @('-X', '-h', '127.0.0.1', '-p', "$Port", '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=terse', '-v', 'SHOW_CONTEXT=never')

function Step([string]$text) { Write-Host "[$(Get-Date -Format HH:mm:ss)] $text" -ForegroundColor Cyan }
function Fail([string]$text) { Write-Host "LỖI: $text" -ForegroundColor Red; exit 1 }
# Native tools write notices to stderr; under PS 5.1 + Stop that would abort, so judge by exit code only.
function Invoke-Native([string]$exe, [string[]]$arguments, [string]$log) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { & $exe @arguments *> $log } finally { $ErrorActionPreference = $old }
    return $LASTEXITCODE
}
function Show-Errors([string]$log) {
    Select-String -LiteralPath $log -Pattern 'ERROR|FATAL|LỖI|GUARD' | Select-Object -First 5 | ForEach-Object { Write-Host "  $($_.Line)" -ForegroundColor Yellow }
}

# ---------------------------------------------------------------- checks (no password needed)
if ($database -ne 'lms_mobile_group_real') { Fail 'database constant changed; stopping.' }
if ($SchemaFrom -notin @('lms_mobile_group_demo', 'lms_mobile_group_dev', 'schema_src')) { Fail "SchemaFrom '$SchemaFrom' not allowed." }
if ($NoPasswordPrompt -and $Port -eq 55432) { Fail '-NoPasswordPrompt is only for a throwaway test cluster, not 55432.' }
$full = [IO.Path]::GetFullPath($DataDir)
if ($full.StartsWith([IO.Path]::GetFullPath($root), [StringComparison]::OrdinalIgnoreCase)) { Fail 'DataDir is inside the repository; move it out first (step 0).' }
foreach ($f in 'dlu_course_cntt.csv', 'dlu_user.csv', 'dlu_grade_grades.csv', 'dlu_grade_items.csv') {
    if (-not (Test-Path -LiteralPath (Join-Path $full $f))) { Fail "missing $f in $full" }
}
if (((Get-PSDrive C).Free / 1GB) -lt 15) { Fail 'C: has < 15 GiB free.' }
if (((Get-PSDrive D).Free / 1GB) -lt 6) { Fail 'D: has < 6 GiB free (import needs ~3 GiB temporarily).' }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { Fail 'python not found on PATH.' }
New-Item -ItemType Directory -Force $workDir | Out-Null
$client = [Net.Sockets.TcpClient]::new()
try { $up = $client.ConnectAsync('127.0.0.1', $Port).Wait(1500) -and $client.Connected } catch { $up = $false } finally { $client.Dispose() }
if (-not $up) { Fail "PostgreSQL is not listening on 127.0.0.1:$Port. Start it first: .\tools\Use-LocalPostgres.ps1 -Action Start (own window)." }

$t0 = Get-Date
Step 'Bỏ cột email khỏi dlu_user.csv (email không bao giờ vào CSDL)'
$userFile = Join-Path $workDir 'dlu_user_noemail.csv'
$code = Invoke-Native $python @('-I', (Join-Path $PSScriptRoot 'real-import\strip_user_email.py'), (Join-Path $full 'dlu_user.csv'), $userFile) (Join-Path $workDir "strip-$stamp.log")
if ($code -ne 0) { Fail "strip_user_email.py exit $code" }
Get-Content (Join-Path $workDir "strip-$stamp.log")

$secure = $null
if (-not $NoPasswordPrompt) { $secure = Read-Host -AsSecureString 'Mật khẩu role postgres (cụm 127.0.0.1:55432)' }
if ($secure) { $env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password }
try {
    $logBase = Join-Path $workDir "import-$stamp"
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $exists = (& $psql @conn -d postgres -tA -c "SELECT count(*) FROM pg_database WHERE datname = '$database'" 2>$null)
    $ErrorActionPreference = $old
    if ($LASTEXITCODE -ne 0) { Fail 'Không kết nối được (sai mật khẩu?). Không thay đổi gì.' }
    if ("$exists".Trim() -ne '0') {
        if (-not $Recreate) { Fail "$database đã tồn tại. Chạy lại với -Recreate để dựng lại (chỉ xóa $database)." }
        Step "Xóa $database (-Recreate)"
        # Guard: the statement is built from the constant only; demo/dev are never named here.
        $code = Invoke-Native $psql ($conn + @('-d', 'postgres', '-c', "DROP DATABASE IF EXISTS lms_mobile_group_real")) "$logBase-drop.log"
        if ($code -ne 0) { Show-Errors "$logBase-drop.log"; Fail 'DROP lỗi (backend còn kết nối? chạy tools\Stop-Demo.ps1 trước).' }
    }

    Step "Tạo $database"
    $code = Invoke-Native $psql ($conn + @('-d', 'postgres', '-c', "CREATE DATABASE lms_mobile_group_real OWNER postgres TEMPLATE template0 ENCODING 'UTF8'")) "$logBase-create.log"
    if ($code -ne 0) { Show-Errors "$logBase-create.log"; Fail 'CREATE DATABASE lỗi.' }

    Step "Chép schema (không dữ liệu) từ $SchemaFrom"
    $schemaFile = Join-Path $workDir "schema-$stamp.sql"
    $code = Invoke-Native $pgDump @('-h', '127.0.0.1', '-p', "$Port", '-U', 'postgres', '-d', $SchemaFrom, '--schema-only', '-f', $schemaFile) "$logBase-dump.log"
    if ($code -ne 0) { Show-Errors "$logBase-dump.log"; Fail 'pg_dump --schema-only lỗi.' }
    $code = Invoke-Native $psql ($conn + @('-d', $database, '--single-transaction', '-f', $schemaFile)) "$logBase-schema.log"
    if ($code -ne 0) { Show-Errors "$logBase-schema.log"; Fail 'Áp schema lỗi.' }
    $code = Invoke-Native $psql ($conn + @('-d', $database, '-f', (Join-Path $root 'database\grants_lms_group_app.sql'))) "$logBase-grants.log"
    if ($code -ne 0) { Show-Errors "$logBase-grants.log"; Fail 'Cấp quyền lms_group_app lỗi.' }

    $dataArg = $full -replace '\\', '/'
    $userArg = $userFile -replace '\\', '/'
    foreach ($stage in '10_stage', '20_load_lms', '30_substitutes', '40_views') {
        Step "SQL $stage"
        $code = Invoke-Native $psql ($conn + @('-d', $database, '-v', "datadir=$dataArg", '-v', "userfile=$userArg", '-f', (Join-Path $sqlDir "$stage.sql"))) "$logBase-$stage.log"
        if ($code -ne 0) { Show-Errors "$logBase-$stage.log"; Fail "$stage lỗi (exit $code). Sửa rồi chạy lại với -Recreate." }
    }
    # Views added for real only must be readable by the runtime role as well.
    $code = Invoke-Native $psql ($conn + @('-d', $database, '-c', 'GRANT SELECT ON derived.real_student_enrolments, derived.real_graded_modules, derived.real_courses_in_progress TO lms_group_app')) "$logBase-grants2.log"
    if ($code -ne 0) { Show-Errors "$logBase-grants2.log"; Fail 'GRANT view real lỗi.' }

    Step 'Báo cáo (chỉ số tổng hợp)'
    $report = Join-Path $reportDir "import-report-$stamp.txt"
    $code = Invoke-Native $psql ($conn + @('-d', $database, '-f', (Join-Path $sqlDir '50_report.sql'))) $report
    if ($code -ne 0) { Show-Errors $report; Fail 'Báo cáo lỗi.' }
    Step 'Xóa bản staging (stg) + VACUUM ANALYZE'
    $code = Invoke-Native $psql ($conn + @('-d', $database, '-f', (Join-Path $sqlDir '60_cleanup.sql'))) "$logBase-cleanup.log"
    if ($code -ne 0) { Show-Errors "$logBase-cleanup.log"; Fail 'Cleanup lỗi.' }
    Remove-Item -LiteralPath $userFile -ErrorAction SilentlyContinue

    $elapsed = [math]::Round(((Get-Date) - $t0).TotalSeconds)
    Add-Content -LiteralPath $report -Value "`n== Thời gian chạy: $elapsed s ($stamp)"
    Get-Content -LiteralPath $report
    Write-Host ''
    Write-Host "XONG: $database, $elapsed s. Báo cáo: $report" -ForegroundColor Green
    Write-Host 'Tiếp: .\tools\Set-DemoPasswords.ps1 -Database real  rồi  .\tools\Start-Demo.ps1 -Database real' -ForegroundColor Green
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    if ($secure) { $secure.Dispose() }
}
