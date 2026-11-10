[CmdletBinding()]
param([switch]$BuildApk)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Use-LocalToolchain.ps1')
Push-Location (Join-Path (Split-Path $PSScriptRoot) 'frontend')
try {
    & $groupDart format .
    if ($LASTEXITCODE -ne 0) { throw 'Format failed.' }
    & $groupFlutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Analyze failed.' }
    & $groupFlutter test
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
    if ($BuildApk) {
        if (((Get-PSDrive C).Free / 1GB) -lt 15) { throw 'STORAGE_BLOCKED' }
        & $groupFlutter build apk --debug '--dart-define=LOCAL_DEVELOPMENT=true' '--dart-define=API_BASE_URL=http://127.0.0.1:8081/api/v1'
        if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
        Write-Output 'Local APK uses adb reverse tcp:8081 tcp:8081. Database/API runtime still requires verification.'
    }
} finally { Pop-Location }
