[CmdletBinding()]
param(
    [ValidateSet('demo', 'dev')][string]$Database = 'demo',
    [string]$Avd = 'DLU_LMS_Pixel',
    # Installed only when the app is missing on the device; default = latest archived debug APK.
    [string]$Apk = '',
    [switch]$NoEmulator,
    # FINAL-F2: demo on a real phone over USB instead of the emulator. The backend still listens on
    # 127.0.0.1 only; the phone reaches it through `adb reverse`.
    [switch]$PhysicalDevice
)
$ErrorActionPreference = 'Stop'
# V2-O1 demo launcher. Every long-running service gets its OWN PowerShell window (Start-Process), so
# nothing depends on the console or Claude session that ran this script. Order:
#   0 checks -> 1 PostgreSQL -> 2 wait 55432 -> 3 backend -> 4 wait /health UP -> 5 emulator (C >= 15 GiB)
#   -> 6 wait boot -> 7 adb reverse -> 8 open the app.
# -PhysicalDevice: step 5 waits for a USB phone instead of starting the emulator; step 8 installs the
# final APK when the phone does not have it yet.
# Steps already running are reused. No secret or row data is printed. Stop with tools\Stop-Demo.ps1.

$root = Split-Path $PSScriptRoot
$tools = $PSScriptRoot
$sdk = 'D:\DLU-LMS\Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulatorExe = Join-Path $sdk 'emulator\emulator.exe'
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$api = 'http://127.0.0.1:8081/api/v1'
$package = 'com.example.lms_mobile_app'
$pidFile = Join-Path $root '.local\demo-pids.json'
$shell = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $shell) { $shell = (Get-Command powershell).Source }

function Step([string]$n, [string]$text) { Write-Host "[$n] $text" -ForegroundColor Cyan }
function Ok([string]$text) { Write-Host "      OK  $text" -ForegroundColor Green }
function Fail([string]$text, [string]$hint) {
    Write-Host "      LỖI $text" -ForegroundColor Red
    Write-Host "      Cách xử lý: $hint" -ForegroundColor Yellow
    exit 1
}
function FreeC { [math]::Round((Get-PSDrive C).Free / 1GB, 1) }

function Save-Pid([string]$name, [int]$id) {
    $map = @{}
    if (Test-Path -LiteralPath $pidFile) {
        try { (Get-Content -Raw -LiteralPath $pidFile | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $map[$_.Name] = $_.Value } } catch { }
    }
    $map[$name] = $id
    $map | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding utf8
}

# Opens a separate, persistent PowerShell window running $command; returns the window process.
function Open-Window([string]$title, [string]$command) {
    $full = "`$Host.UI.RawUI.WindowTitle = '$title'; $command"
    Start-Process -FilePath $shell -ArgumentList @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $full) -PassThru
}

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

# Serial of the target device (emulator or USB phone), or $null.
function Get-Serial {
    $pattern = if ($PhysicalDevice) { '^(?!emulator-)(\S+)\s+device$' } else { '^(emulator-\d+)\s+device$' }
    $m = (& $adb devices 2>$null) | Select-String $pattern | Select-Object -First 1
    if ($m) { $m.Matches[0].Groups[1].Value } else { $null }
}
function Get-Devices { Get-Serial }
function Adb { & $adb -s $script:serial @args }

$finalApk = 'D:\DLU-LMS\Artifacts\final\dlu-lms-group-final-debug.apk'
$deviceName = 'chưa có'

# ---------------------------------------------------------------- 0. checks
Step '0/8' "Kiểm tra cấu hình (DB $Database, Portal, ổ C)"
if ((FreeC) -lt 15) { Fail "Ổ C còn $(FreeC) GiB (< 15)" 'Dọn ổ C (Thùng rác, %TEMP%, bản tải về) rồi chạy lại.' }
if ((FreeC) -lt 22) { Write-Host "      CẢNH BÁO ổ C còn $(FreeC) GiB (< 22): emulator có thể làm pagefile tăng ~6 GiB. Nên dọn trước buổi bảo vệ." -ForegroundColor Yellow }
$config = Join-Path $root '.local\backend.json'
if (-not (Test-Path -LiteralPath $config)) { Fail 'Thiếu .local\backend.json' 'Chạy tools\New-LocalBackendConfig.ps1 (owner).' }
& (Join-Path $tools 'Set-LocalBackendDatabase.ps1') -Target $Database | Out-Null
$cfg = [IO.File]::ReadAllText($config) | ConvertFrom-Json
$portalOn = $cfg.PORTAL -and $cfg.PORTAL.enabled -eq $true
$cfg = $null
Ok "backend.json -> lms_mobile_group_$Database; Portal: $(if ($portalOn) { 'bật' } else { 'TẮT (màn Học vụ sẽ báo chưa kết nối)' })"
if ($PhysicalDevice -and $NoEmulator) { Fail '-PhysicalDevice và -NoEmulator không dùng chung' 'Chọn một trong hai.' }
if (-not (Test-Path $adb) -and -not $NoEmulator) { Fail "Không thấy adb ở $adb" 'Kiểm tra Android SDK tại D:\DLU-LMS\Android\Sdk.' }

# ---------------------------------------------------------------- 1-2. PostgreSQL
Step '1/8' 'PostgreSQL 127.0.0.1:55432'
if (Test-Port 55432) {
    Ok 'đang chạy, dùng lại'
} else {
    if ((FreeC) -lt 15) { Fail "Ổ C còn $(FreeC) GiB (< 15)" 'Dọn ổ C (Thùng rác, %TEMP%, bản tải về) rồi chạy lại.' }
    $p = Open-Window 'DLU Demo - PostgreSQL' "& '$tools\Use-LocalPostgres.ps1' -Action Start"
    Save-Pid 'postgresWindow' $p.Id
    Ok "mở cửa sổ PostgreSQL (PID $($p.Id))"
}
Step '2/8' 'Chờ PostgreSQL nhận kết nối'
$ready = $false
for ($i = 0; $i -lt 60 -and -not $ready; $i++) {
    & (Join-Path $pgBin 'pg_isready.exe') -h 127.0.0.1 -p 55432 -q
    if ($LASTEXITCODE -eq 0) { $ready = $true } else { Start-Sleep 1 }
}
if (-not $ready) { Fail 'PostgreSQL không sẵn sàng sau 60 s' "Xem cửa sổ 'DLU Demo - PostgreSQL' và D:\DLU-LMS\PostgreSQL\logs\pg_ctl.log; nếu báo cổng bận: Stop-Demo.ps1 rồi chạy lại." }
Ok 'accepting connections'

# ---------------------------------------------------------------- 3-4. backend
Step '3/8' 'Backend 127.0.0.1:8081'
if (Test-Port 8081) {
    Ok 'cổng 8081 đã có tiến trình, dùng lại (nếu là bản cũ: Stop-Demo.ps1 rồi chạy lại)'
} else {
    $p = Open-Window 'DLU Demo - Backend' "& '$tools\Start-LocalBackend.ps1'"
    Save-Pid 'backendWindow' $p.Id
    Ok "mở cửa sổ Backend (PID $($p.Id)); lần đầu Maven có thể mất 1-2 phút"
}
Step '4/8' 'Chờ /api/v1/health = UP'
$health = $null
for ($i = 0; $i -lt 90 -and -not ($health -and $health.status -eq 'UP'); $i++) { Start-Sleep 2; $health = Get-Health }
if (-not ($health -and $health.status -eq 'UP')) { Fail 'Backend chưa UP sau 180 s' "Xem cửa sổ 'DLU Demo - Backend' (lỗi DB/mật khẩu sẽ in ở đó)." }
Ok "status UP, database $($health.database), portal $($health.portal)"
if ($portalOn -and $health.portal -ne 'UP') { Write-Host "      CẢNH BÁO Portal = $($health.portal): màn Học vụ sẽ báo chưa kết nối; phần LMS vẫn chạy." -ForegroundColor Yellow }

$portalState = if (-not $portalOn) { 'TẮT' } elseif ($health.portal -eq 'UP') { 'UP' } else { "DOWN ($($health.portal))" }
function Summary {
    Write-Host ''
    Write-Host '==== Tóm tắt demo ====' -ForegroundColor Green
    Write-Host "  Database : lms_mobile_group_$Database"
    Write-Host "  Portal   : $portalState$(if ($portalState -ne 'UP') { ' -> bỏ qua đoạn Học vụ trong DEMO_SCRIPT' })"
    Write-Host "  Thiết bị : $deviceName"
    Write-Host "  Ổ C      : $(FreeC) GiB"
    Write-Host '  Tắt      : tools\Stop-Demo.ps1'
}
if ($NoEmulator) { $deviceName = 'không (-NoEmulator)'; Summary; exit 0 }

# ---------------------------------------------------------------- 5-6. emulator
if ($PhysicalDevice) {
    Step '5/8' 'Điện thoại thật qua USB'
    for ($i = 0; $i -lt 60 -and -not (Get-Serial); $i++) {
        if ($i -eq 0) { Write-Host '      Cắm cáp USB, bật "Gỡ lỗi USB" và bấm "Cho phép" trên điện thoại...' -ForegroundColor Yellow }
        Start-Sleep 2
    }
    if (-not (Get-Serial)) { Fail 'Không thấy điện thoại sau 120 s' 'Kiểm tra cáp, bật Tùy chọn nhà phát triển > Gỡ lỗi USB, chấp nhận khóa RSA; "adb devices" phải ghi "device" (không phải "unauthorized").' }
    Ok "thấy máy $(Get-Serial)"
} elseif (Get-Devices) {
    Ok 'đã có emulator đang chạy, dùng lại'
} else {
    if ((FreeC) -lt 15) { Fail "Ổ C còn $(FreeC) GiB (< 15), không bật emulator" 'Dọn ổ C rồi chạy lại; backend vẫn đang chạy.' }
    # Measured 2026-11-10: booting the emulator took ~6 GiB of C (Windows pagefile grows).
    if ((FreeC) -lt 22) { Write-Host "      CẢNH BÁO C còn $(FreeC) GiB; emulator làm pagefile trên C tăng ~6 GiB khi khởi động. Nên dọn C trước buổi bảo vệ." -ForegroundColor Yellow }
    $cmd = "`$env:ANDROID_SDK_ROOT='$sdk'; `$env:ANDROID_EMULATOR_HOME='D:\DLU-LMS\Android\EmulatorHome'; " +
        "`$env:TEMP='D:\DLU-LMS\Temp'; `$env:TMP=`$env:TEMP; & '$emulatorExe' -avd $Avd -no-snapshot-save -no-audio"
    $p = Open-Window 'DLU Demo - Emulator' $cmd
    Save-Pid 'emulatorWindow' $p.Id
    Ok "mở cửa sổ Emulator (PID $($p.Id)), C còn $(FreeC) GiB"
}
Step '6/8' 'Chờ Android khởi động xong (sys.boot_completed = 1)'
$booted = $false
for ($i = 0; $i -lt 120 -and -not $booted; $i++) {
    $script:serial = Get-Serial
    if ($script:serial -and ((Adb shell getprop sys.boot_completed 2>$null) -join '').Trim() -eq '1') { $booted = $true } else { Start-Sleep 2 }
}
if (-not $booted) { Fail 'Emulator chưa khởi động xong sau 240 s' "Đóng cửa sổ Emulator, chạy: & '$emulatorExe' -avd $Avd -no-snapshot-load (cold boot), rồi chạy lại script." }
Ok 'boot_completed'
$model = ((Adb shell getprop ro.product.model 2>$null) -join '').Trim()
$deviceName = "$($script:serial) ($model)"

# ---------------------------------------------------------------- 7-8. adb reverse + app
Step '7/8' 'adb reverse tcp:8081 tcp:8081'
Adb reverse tcp:8081 tcp:8081 | Out-Null
if ($LASTEXITCODE -ne 0) { Fail 'adb reverse lỗi' 'Chạy: adb kill-server; adb start-server; rồi chạy lại script.' }
Ok ((Adb reverse --list) -join '; ')

Step '8/8' 'Mở ứng dụng'
if (-not $Apk) {
    $Apk = if (Test-Path -LiteralPath $finalApk) { $finalApk } else {
        Get-ChildItem 'D:\DLU-LMS\Artifacts\dlu-lms-group-*.apk' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
}
$installed = (Adb shell pm list packages $package) -match $package
# Which APK this script last installed on this device (by SHA-256); a phone may still carry an older build.
$marker = Join-Path $root ".local\device-apk-$($script:serial -replace '[^\w.-]', '_').txt"
$apkHash = if ($Apk -and (Test-Path -LiteralPath $Apk)) { (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash } else { $null }
$stale = $PhysicalDevice -and $apkHash -and (-not (Test-Path -LiteralPath $marker) -or (Get-Content -Raw -LiteralPath $marker).Trim() -ne $apkHash)
if (-not $installed -or $stale) {
    if (-not $apkHash) { Fail 'Ứng dụng chưa cài và không tìm thấy APK' 'Truyền -Apk <đường dẫn .apk>.' }
    Adb install -r -t $Apk | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail 'Cài APK lỗi' 'Kiểm tra dung lượng máy hoặc gỡ app cũ: adb uninstall com.example.lms_mobile_app (khác chữ ký thì phải gỡ).' }
    Set-Content -LiteralPath $marker -Value $apkHash -Encoding ascii
    Ok "đã cài $(Split-Path $Apk -Leaf) (SHA-256 $($apkHash.Substring(0, 12))…)"
} else {
    Ok 'ứng dụng đã có trên máy'
}
Adb shell monkey -p $package -c android.intent.category.LAUNCHER 1 2>$null | Out-Null
Ok 'đã mở ứng dụng'
Summary
