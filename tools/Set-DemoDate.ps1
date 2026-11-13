[CmdletBinding()]
param(
    # Day the demo should look "current": the latest deadline lands on TargetDate + 5 days (whole-day
    # shift, so its time of day is kept).
    [Parameter(Mandatory)][string]$TargetDate
)
$ErrorActionPreference = 'Stop'
# A Windows PowerShell 5.1 window opened from pwsh inherits PowerShell 7's PSModulePath, so 5.1 modules
# (Microsoft.PowerShell.Utility: Get-FileHash, ...) may fail to load. Rebuild the 5.1 default for this process.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $env:PSModulePath = (@((Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'),
            (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules'),
            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')) | Where-Object { $_ }) -join ';'
}
# SHIFT-1113. Owner-run (normal PowerShell, not elevated), with the backend STOPPED.
# Re-shifts the Moodle dates of the demo copy lms_mobile_group_demo ONLY (never the dev database), on the
# verified cluster 127.0.0.1:55432. Steps: checks -> full pg_dump of the demo DB (stops on any error)
# -> database\demo\shift_demo_dates.sql in one transaction. Schema app (cards, plans, notes) is untouched.
# One hidden prompt for the postgres password, kept only in this process's environment and removed in
# finally. Prints exit codes, shift_days, the new latest deadline, aggregate counts and file paths only.
# Example: .\tools\Set-DemoDate.ps1 -TargetDate 2026-11-13   (back to the defence date: -TargetDate 2026-11-20)
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$pgData = 'D:\DLU-LMS\PostgreSQL\data'
$pgLogs = 'D:\DLU-LMS\PostgreSQL\logs'
$backups = 'D:\DLU-LMS\Backups'
$root = Split-Path $PSScriptRoot
$shiftSql = Join-Path $root 'database\demo\shift_demo_dates.sql'
$demoDb = 'lms_mobile_group_demo'
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
$psql = Join-Path $pgBin 'psql.exe'
$pgDump = Join-Path $pgBin 'pg_dump.exe'
$conn = @('-X', '-h', '127.0.0.1', '-p', '55432', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $pgLogs "demo-date-$stamp.log"

# SHA-256 and port checks with .NET only (no module dependency).
function Get-Sha256([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { return (-join ($sha.ComputeHash($stream) | ForEach-Object { $_.ToString('X2') })) }
    finally { $stream.Dispose(); $sha.Dispose() }
}
function Test-Listening([int]$Port) {
    $client = New-Object Net.Sockets.TcpClient
    try { return ($client.ConnectAsync('127.0.0.1', $Port).Wait(1000) -and $client.Connected) } catch { return $false }
    finally { $client.Dispose() }
}

# ---------------------------------------------------------------- safety checks (no password yet)
if ($TargetDate -notmatch '^\d{4}-\d{2}-\d{2}$') { throw 'TargetDate must be yyyy-MM-dd.' }
$parsed = [datetime]::MinValue
if (-not [datetime]::TryParseExact($TargetDate, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$parsed)) { throw "TargetDate '$TargetDate' is not a real date." }
if (((Get-PSDrive C).Free / 1GB) -lt 15) { throw 'STORAGE_BLOCKED: drive C has less than 15 GiB free.' }
if (-not (Test-Path -LiteralPath $shiftSql)) { throw "Shift script not found: $shiftSql" }
foreach ($exe in $psql, $pgDump) { if (-not (Test-Path -LiteralPath $exe)) { throw "Not found: $exe" } }

$backend = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
    Where-Object { $_.CommandLine -match 'LmsMobileBackendApplication|spring-boot:run|lms_mobile_backend' }
if ($backend -or (Test-Listening 8081)) {
    throw 'Backend is running (java / port 8081). Stop it first: .\tools\Stop-Demo.ps1 -KeepPostgres'
}

if (-not (Test-Listening 55432)) {
    # Own window (like Start-Demo), so the server does not die when THIS window is closed.
    Write-Output "PostgreSQL not running; starting it in its own window 'DLU Demo - PostgreSQL'."
    $pgStart = "`$Host.UI.RawUI.WindowTitle = 'DLU Demo - PostgreSQL'; & '" + (Join-Path $PSScriptRoot 'Use-LocalPostgres.ps1') + "' -Action Start"
    Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -WindowStyle Minimized `
        -ArgumentList @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $pgStart) | Out-Null
    for ($i = 0; $i -lt 60 -and -not (Test-Listening 55432); $i++) { Start-Sleep 1 }
    if (-not (Test-Listening 55432)) { throw "PostgreSQL did not start within 60 s; see $pgLogs\pg_ctl.log" }
}
$pidFile = Get-Content (Join-Path $pgData 'postmaster.pid')
if ($pidFile[1] -ne 'D:/DLU-LMS/PostgreSQL/data' -or $pidFile[3] -ne '55432' -or $pidFile[5] -ne '127.0.0.1') {
    throw 'Cluster is not the verified D: instance on 127.0.0.1:55432.'
}
New-Item -ItemType Directory -Force $backups, $pgLogs | Out-Null

# Windows PowerShell 5.1 turns ANY stderr line of a redirected native command into a terminating error
# when ErrorActionPreference is Stop (pg_dump/psql notices). Native calls therefore run with 'Continue'
# and are judged by their exit code only.
function Invoke-Native([string]$Exe, [string[]]$Arguments, [string]$OutFile, [switch]$Append) {
    $ErrorActionPreference = 'Continue'
    if ($Append) { & $Exe @Arguments *>> $OutFile } else { & $Exe @Arguments *> $OutFile }
    return $LASTEXITCODE
}
function Get-NativeText([string]$Exe, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $text = & $Exe @Arguments 2>> $log
    return [pscustomobject]@{ Exit = $LASTEXITCODE; Text = ("$text").Trim() }
}

$secure = Read-Host -AsSecureString 'Password for cluster role postgres'
$env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password
try {
    $exists = Get-NativeText $psql ($conn + @('-d', 'postgres', '-tA', '-c', "SELECT count(*) FROM pg_database WHERE datname = '$demoDb'"))
    if ($exists.Exit -ne 0) { throw "Connection check failed (exit $($exists.Exit)); see $log" }
    if ($exists.Text -ne '1') { throw "$demoDb does not exist; stopping." }

    # 1. Full backup of the demo database. Any failure stops here, before the shift.
    $backup = Join-Path $backups "demo-before-shift-$TargetDate-$stamp.sql"
    $dumpExit = Invoke-Native $pgDump @('-h', '127.0.0.1', '-p', '55432', '-U', 'postgres', '-d', $demoDb, '-f', $backup) $log -Append
    Write-Output "pg_dump $demoDb exit=$dumpExit file=$backup"
    if ($dumpExit -ne 0 -or -not (Test-Path -LiteralPath $backup) -or (Get-Item -LiteralPath $backup).Length -eq 0) {
        throw "Backup failed; date shift NOT started. See $log"
    }
    Write-Output ("backup sha256=" + (Get-Sha256 $backup))
    Write-Output ("backup size MiB=" + [math]::Round((Get-Item -LiteralPath $backup).Length / 1MB, 1))

    # 2. Date shift in one transaction (the SQL itself refuses any database other than the demo copy).
    $shiftOut = Join-Path $pgLogs "demo-shift-$TargetDate-$stamp.txt"
    $shiftExit = Invoke-Native $psql ($conn + @('-d', $demoDb, '--single-transaction', '-v', "target_date=$TargetDate", '-f', $shiftSql)) $shiftOut
    Write-Output "date shift $demoDb exit=$shiftExit out=$shiftOut"
    Get-Content -LiteralPath $shiftOut | Write-Output
    if ($shiftExit -ne 0) { throw "Date shift failed; transaction rolled back. Backup kept: $backup" }

    # 3. Read back after commit: latest deadline must now be TargetDate + 5 days.
    $check = "SELECT to_char(to_timestamp(greatest((SELECT max(duedate) FROM lms.assign WHERE duedate > 0)," +
             " (SELECT max(timeclose) FROM lms.quiz WHERE timeclose > 0))) AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI')"
    $latest = Get-NativeText $psql ($conn + @('-d', $demoDb, '-tA', '-c', $check))
    if ($latest.Exit -ne 0) { throw "Read-back failed (exit $($latest.Exit)); see $log" }
    $expected = $parsed.AddDays(5).ToString('yyyy-MM-dd')
    Write-Output "new latest deadline (+07) = $($latest.Text) (expected day $expected)"
    if (-not $latest.Text.StartsWith($expected)) { Write-Warning 'Latest deadline is not on the expected day; check the output above.' }
    Write-Output "log=$log"
    Write-Output 'Done. Start the demo with .\tools\Start-Demo.ps1'
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $secure.Dispose()
}
