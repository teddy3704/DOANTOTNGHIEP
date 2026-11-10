[CmdletBinding()]
param([switch]$KeepPostgres)
$ErrorActionPreference = 'Continue'
# V2-O1: stops the demo in reverse order of Start-Demo.ps1: app/emulator -> backend -> PostgreSQL,
# then closes the windows Start-Demo opened. Safe to run when some parts are already stopped.
# PostgreSQL is stopped with pg_ctl -m fast (clean shutdown, no data loss).

$root = Split-Path $PSScriptRoot
$adb = 'D:\DLU-LMS\Android\Sdk\platform-tools\adb.exe'
$pidFile = Join-Path $root '.local\demo-pids.json'
function Step([string]$text) { Write-Host "- $text" -ForegroundColor Cyan }

Step 'Emulator'
if ((Test-Path $adb) -and ((& $adb devices 2>$null) | Select-String '^emulator-\d+\s+device')) {
    & $adb reverse --remove-all 2>$null | Out-Null
    & $adb emu kill 2>$null | Out-Null
    for ($i = 0; $i -lt 30 -and (Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 1 }
    Write-Host '  đã tắt'
} else { Write-Host '  không chạy' }

Step 'Backend'
# spring-boot:run = a Maven JVM plus the application JVM; both are stopped.
$java = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
    Where-Object { $_.CommandLine -match 'LmsMobileBackendApplication|spring-boot:run|lms_mobile_backend' }
if ($java) {
    foreach ($p in $java) { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }
    Write-Host "  đã tắt $(@($java).Count) tiến trình Java"
} else { Write-Host '  không chạy' }

Step 'PostgreSQL'
if ($KeepPostgres) { Write-Host '  giữ nguyên (-KeepPostgres)' }
else {
    $status = & 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin\pg_ctl.exe' status -D 'D:\DLU-LMS\PostgreSQL\data' 2>$null
    if ($LASTEXITCODE -eq 0) {
        & (Join-Path $PSScriptRoot 'Use-LocalPostgres.ps1') -Action Stop | Out-Null
        Write-Host '  đã tắt (pg_ctl stop -m fast)'
    } else { Write-Host '  không chạy' }
}

Step 'Cửa sổ Start-Demo'
if (Test-Path -LiteralPath $pidFile) {
    $map = Get-Content -Raw -LiteralPath $pidFile | ConvertFrom-Json
    foreach ($entry in $map.PSObject.Properties) {
        if ($KeepPostgres -and $entry.Name -eq 'postgresWindow') { continue }
        $proc = Get-Process -Id $entry.Value -ErrorAction SilentlyContinue
        # Only close the window if it is still the PowerShell host Start-Demo opened (PIDs can be reused).
        if ($proc -and $proc.ProcessName -match '^(pwsh|powershell)$') { Stop-Process -Id $proc.Id -Force; Write-Host "  đóng $($entry.Name)" }
    }
    if (-not $KeepPostgres) { Remove-Item -LiteralPath $pidFile -Force }
} else { Write-Host '  không có' }
Write-Host 'Đã dừng demo.' -ForegroundColor Green
