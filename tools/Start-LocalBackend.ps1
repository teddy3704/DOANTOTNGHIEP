[CmdletBinding()]
param([string]$ConfigPath = (Join-Path (Split-Path $PSScriptRoot) '.local\backend.json'))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Use-LocalToolchain.ps1')
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw 'LOCAL_DATABASE_CONFIGURATION_REQUIRED. See docs/LOCAL_RUNBOOK.md; never send credentials in chat.'
}
try { $config = [IO.File]::ReadAllText($ConfigPath) | ConvertFrom-Json } catch { throw 'Local configuration is not valid JSON. Contents withheld.' }
$keys = @('DB_URL','DB_USERNAME','DB_PASSWORD','JWT_SECRET','DEMO_STUDENT_ID','DEMO_TEACHER_ID')
foreach ($key in $keys) {
    if ([string]::IsNullOrWhiteSpace([string]$config.$key)) { throw "Missing required local configuration key: $key" }
}
if ($config.DB_URL -notmatch '^jdbc:postgresql://(?:localhost|127\.0\.0\.1):[0-9]+/lms_mobile_group_(?:dev|demo)(?:\?|$)') {
    throw 'Only the local lms_mobile_group_dev or lms_mobile_group_demo targets are allowed by this launcher. Remote cutover requires separate approval.'
}
if ([Text.Encoding]::UTF8.GetByteCount([string]$config.JWT_SECRET) -lt 32) { throw 'JWT_SECRET must be at least 32 bytes.' }
$prior = @{}
$allKeys = $keys + @('SPRING_PROFILES_ACTIVE','DEMO_AUTH_ENABLED','SERVER_ADDRESS','SERVER_PORT','SPRING_APPLICATION_JSON')
# V3: optional PORTAL block (tools\Set-PortalConfig.ps1) -> app.portal.* via SPRING_APPLICATION_JSON.
# Its key and every mapped MSSV join the redaction list for console output.
$redact = @([string]$config.DB_URL, [string]$config.DB_USERNAME, [string]$config.DB_PASSWORD, [string]$config.JWT_SECRET)
$portalJson = $null
$app = @{}
if ($config.PORTAL) { $app.portal = $config.PORTAL }
# LOGIN: optional AUTH block (tools\Set-DemoPasswords.ps1) -> app.auth.local.* (login, userId, role, BCrypt hash only).
if ($config.AUTH -and $config.AUTH.users) {
    $app.auth = @{ local = @{ enabled = $true; users = @($config.AUTH.users) } }
    foreach ($u in $config.AUTH.users) { $redact += [string]$u.bcrypt }
}
if ($app.Count -gt 0) { $portalJson = @{ app = $app } | ConvertTo-Json -Depth 10 -Compress }
if ($config.PORTAL) {
    $redact += [string]$config.PORTAL.apiKey
    if ($config.PORTAL.students) {
        foreach ($p in $config.PORTAL.students.PSObject.Properties) { $redact += [string]$p.Value.studentId }
    }
    if ($config.PORTAL.lmsStudentLinks) {
        foreach ($p in $config.PORTAL.lmsStudentLinks.PSObject.Properties) { $redact += [string]$p.Value }
    }
}
# Substring redaction of very short values would mangle every log line (and reveal the value by
# where it bites); Spring never logs them anyway. Warn instead.
if ($redact | Where-Object { $_ -and $_.Length -lt 6 }) {
    Write-Output 'WARNING: a configured secret is very short; consider a stronger lms_group_app password (owner action).'
}
$redact = @($redact | Where-Object { $_ -and $_.Length -ge 6 })
foreach ($key in $allKeys) { $prior[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }
Push-Location (Join-Path (Split-Path $PSScriptRoot) 'backend')
try {
    foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key, [string]$config.$key, 'Process') }
    $env:SPRING_PROFILES_ACTIVE = 'local-development'
    $env:DEMO_AUTH_ENABLED = 'true'
    $env:SERVER_ADDRESS = '127.0.0.1'
    $env:SERVER_PORT = '8081'
    if ($portalJson) { $env:SPRING_APPLICATION_JSON = $portalJson }
    if ($config.AUTH -and $config.AUTH.users) {
        Write-Output "Login: $(@($config.AUTH.users).Count) local account(s) configured (hashes withheld)."
    } else {
        Write-Output 'Login: no local accounts (tools\Set-DemoPasswords.ps1); only the demo mode works.'
    }
    if ($config.PORTAL) {
        Write-Output 'Portal integration: configured (values withheld).'
    } else {
        Write-Output 'Portal integration: not configured (tools\Set-PortalConfig.ps1); Portal screens show "Chua ket noi".'
    }
    Write-Output 'Starting group backend on loopback:8081. Do not expose this development authentication service publicly.'
    & $groupMaven $groupMavenCache -B -ntp spring-boot:run 2>&1 | ForEach-Object {
        $safeLine = $_.ToString()
        foreach ($secret in $redact) { $safeLine = $safeLine.Replace($secret, '[REDACTED]') }
        $safeLine = [regex]::Replace($safeLine, '(?i)(?:jdbc:)?postgres(?:ql)?://\S+', '[REDACTED_CONNECTION]')
        Write-Output $safeLine
    }
    if ($LASTEXITCODE -ne 0) { throw 'Local backend exited with an error. Credentials were withheld.' }
} finally {
    Pop-Location
    foreach ($key in $allKeys) { [Environment]::SetEnvironmentVariable($key, $prior[$key], 'Process') }
    $portalJson = $null
    $redact = $null
}
