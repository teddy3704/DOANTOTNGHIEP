[CmdletBinding()]
param([ValidateRange(24, 64)][int]$Length = 32)
$ErrorActionPreference = 'Stop'
# FINAL-F6 — owner-run, one time: rotate the password of the backend runtime role lms_group_app.
#   1. Hidden prompt for the postgres password (never printed, never on a command line).
#   2. Random password ($Length chars, CSPRNG) -> ALTER ROLE lms_group_app (cluster-level: one change covers dev and demo).
#   3. Writes DB_PASSWORD into the git-ignored .local\backend.json without printing it.
#   4. Verifies: psql login as lms_group_app, then the BACKEND itself: restarts it and requires /health database = CONNECTED.
# Steps 1-3 and the psql check (with rollback on failure) are done by tools\Set-RuntimeRolePassword.ps1.
# Run from the owner's own PowerShell; Claude must not run it (needs the postgres password).

$tools = $PSScriptRoot
# Set-RuntimeRolePassword needs .NET (Core) APIs: rerun under PowerShell 7 when started from Windows PowerShell 5.
if ($PSVersionTable.PSEdition -ne 'Core') {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { Write-Host 'Cần PowerShell 7 (pwsh).' -ForegroundColor Red; exit 1 }
    & $pwsh -NoProfile -File $PSCommandPath -Length $Length
    exit $LASTEXITCODE
}
$root = Split-Path $tools
$api = 'http://127.0.0.1:8081/api/v1'

function Test-Port([int]$port) {
    $client = [Net.Sockets.TcpClient]::new()
    try { return $client.ConnectAsync('127.0.0.1', $port).Wait(1000) -and $client.Connected } catch { return $false } finally { $client.Dispose() }
}
function Get-Health {
    try {
        $login = Invoke-RestMethod -Method Post -Uri "$api/auth/demo-login" -ContentType 'application/json' -Body '{"role":"STUDENT"}' -TimeoutSec 5
        return Invoke-RestMethod -Uri "$api/health" -Headers @{ Authorization = "Bearer $($login.token)" } -TimeoutSec 10
    } catch { return $null }
}

if (-not (Test-Port 55432)) {
    Write-Host 'PostgreSQL chưa chạy. Chạy .\tools\Start-Demo.ps1 -NoEmulator trước, rồi chạy lại script này.' -ForegroundColor Yellow
    exit 1
}

Write-Host '[1-3] Đổi mật khẩu role lms_group_app (nhập mật khẩu postgres ở ô ẩn)' -ForegroundColor Cyan
& (Join-Path $tools 'Set-RuntimeRolePassword.ps1') -Length $Length
if (-not $?) { exit 1 }

Write-Host '[4] Kiểm tra backend đăng nhập DB bằng mật khẩu mới' -ForegroundColor Cyan
# The running backend still holds pooled connections opened with the old password: restart it.
& (Join-Path $tools 'Stop-Demo.ps1') -KeepPostgres | Out-Null
$demo = Start-Process (Get-Process -Id $PID).Path -ArgumentList '-NoProfile', '-File', (Join-Path $tools 'Start-Demo.ps1'), '-NoEmulator' -Wait -PassThru -NoNewWindow
if ($demo.ExitCode -ne 0) { Write-Host 'Start-Demo -NoEmulator lỗi: xem cửa sổ "DLU Demo - Backend".' -ForegroundColor Red; exit 1 }
$health = Get-Health
if ($health -and $health.status -eq 'UP' -and $health.database -eq 'CONNECTED') {
    Write-Host 'OK  backend UP, database CONNECTED với mật khẩu mới. Mật khẩu không được in ra.' -ForegroundColor Green
    Write-Host 'Tắt khi xong: .\tools\Stop-Demo.ps1'
} else {
    Write-Host "LỖI backend chưa kết nối được DB (status=$($health.status), database=$($health.database))." -ForegroundColor Red
    Write-Host 'Mật khẩu role đã đổi và đã ghi vào .local\backend.json; xem cửa sổ "DLU Demo - Backend".' -ForegroundColor Yellow
    exit 1
}
