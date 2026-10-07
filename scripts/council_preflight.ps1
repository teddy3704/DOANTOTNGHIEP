param(
    [string]$ApkPath = 'D:\DLU-LMS\Artifacts\DLU_LMS_Support_Perfection_Final_Debug.apk',
    [switch]$AllowDirty
)

# Read-only council checks. Never reads .env, database credentials or raw logs.
# Existing public synthetic staging only; academic and workflow writes are absent.
$ErrorActionPreference = 'Stop'
$preflightRoot = Split-Path -Parent $PSScriptRoot
$preflightOrigin = 'https://dlu-lms-student-support-staging.onrender.com'
$preflightAdb = 'D:\DLU-LMS\Android\Sdk\platform-tools\adb.exe'
$preflightResults = [System.Collections.Generic.List[object]]::new()

function Add-PreflightResult {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    $label = if ($Passed) { 'PASS' } else { 'FAIL' }
    $preflightResults.Add([pscustomobject]@{ Name = $Name; Passed = $Passed })
    Write-Host ('[{0}] {1}{2}' -f $label, $Name, $(if ($Detail) { ' - ' + $Detail } else { '' }))
}

function Test-PublicApi {
    param([string]$Name, [string]$Path, [hashtable]$Headers = @{}, [int]$ExpectedStatus = 200, [switch]$Collection)
    $elapsed = [Diagnostics.Stopwatch]::StartNew()
    $response = $null
    try {
        # Bounded wait accommodates Render Free cold starts; never follows redirects.
        $response = Invoke-WebRequest -Uri ($preflightOrigin + $Path) -Headers $Headers -UseBasicParsing -TimeoutSec 65 -MaximumRedirection 0
        $status = [int]$response.StatusCode
        $content = [string]$response.Content
    }
    catch {
        # Expected 401 is still a successful negative check. Do not print exceptions,
        # response bodies, URLs, headers, account names or remote diagnostics.
        $status = 0
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = 0 }
        }
        if ($ExpectedStatus -ne 200 -and $status -eq $ExpectedStatus) {
            Add-PreflightResult $Name $true ($elapsed.ElapsedMilliseconds.ToString() + ' ms')
            return $null
        }
        Add-PreflightResult $Name $false 'unavailable; check network and retry after cold start'
        return $null
    }
    try {
        if ($content.Length -gt 1048576 -or $content -match 'postgres(?:ql)?://|-----BEGIN (?:RSA |EC )?PRIVATE KEY-----') {
            throw 'UNSAFE_RESPONSE'
        }
        $data = $content | ConvertFrom-Json
        $valid = $status -eq $ExpectedStatus
        if ($Collection) {
            $valid = $valid -and $null -ne $data.meta -and $null -ne $data.data -and @($data.data).Count -eq [int]$data.meta.count
        }
        Add-PreflightResult $Name $valid ($elapsed.ElapsedMilliseconds.ToString() + ' ms')
        return $data
    }
    catch {
        Add-PreflightResult $Name $false 'unexpected or unsafe contract; no response content printed'
        return $null
    }
}

Write-Host 'DLU LMS SUPPORT - COUNCIL PREFLIGHT'
Write-Host 'Read-only synthetic staging checks; not verified DLU authentication.'

try {
    Push-Location -LiteralPath $preflightRoot
    try {
        $branch = (& git branch --show-current 2>$null).Trim()
        Add-PreflightResult 'Git branch' ($branch -eq 'innovation-perfection-hardening')
        $dirty = @(& git status --porcelain 2>$null).Count -gt 0
        Add-PreflightResult 'Working tree' (-not $dirty) $(if ($dirty) { 'uncommitted work retained; not frozen' } else { '' })
        $mainRef = (& git rev-parse main 2>$null).Trim()
        Add-PreflightResult 'Main preserved' ($mainRef -eq 'c773b7e5ccff7b4acdc66630b86471a0f1aba2e6')
    }
    finally { Pop-Location }

    $health = Test-PublicApi 'Backend health' '/health'
    Add-PreflightResult 'Database readiness through API' ($null -ne $health -and $health.status -eq 'ok' -and $health.database -eq 'reachable')
    $studentHeaders = @{ 'X-Demo-Student-Code' = 'SV001' }
    $teacherHeaders = @{ 'X-Demo-Teacher-Code' = 'GV001' }
    $null = Test-PublicApi 'Student profile API' '/api/v1/me' $studentHeaders
    $null = Test-PublicApi 'Recommendation API' '/api/v1/me/recommendations' $studentHeaders -Collection
    $null = Test-PublicApi 'Study Plan API' '/api/v1/me/study-plan' $studentHeaders -Collection
    $null = Test-PublicApi 'Teacher API' '/api/v1/me/teacher/overview' $teacherHeaders
    $null = Test-PublicApi 'Attention API' '/api/v1/me/teacher/attention' $teacherHeaders -Collection
    $null = Test-PublicApi 'Intervention API' '/api/v1/me/teacher/interventions' $teacherHeaders -Collection
    $null = Test-PublicApi 'Follow-up API' '/api/v1/me/teacher/followups' $teacherHeaders -Collection
    $null = Test-PublicApi 'Missing identity rejected' '/api/v1/me' -ExpectedStatus 401
    $null = Test-PublicApi 'Mixed role identity rejected' '/api/v1/me' @{ 'X-Demo-Student-Code' = 'SV001'; 'X-Demo-Teacher-Code' = 'GV001' } -ExpectedStatus 401

    $devices = (& $preflightAdb devices 2>$null) -join "`n"
    Add-PreflightResult 'Existing Flutter emulator' ($devices -match '(?m)^emulator-5554\s+device\s*$')
    $apkPresent = Test-Path -LiteralPath $ApkPath -PathType Leaf
    $artifactManifestPath = Join-Path $preflightRoot 'evidence\perfection\apk.json'
    $artifactVerified = $false
    if ($apkPresent) {
        # APK digest is public artifact metadata, never a secret or signing key.
        $apkDigest = (Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256).Hash
        Write-Host ('APK SHA256: ' + $apkDigest)
        if (Test-Path -LiteralPath $artifactManifestPath -PathType Leaf) {
            $artifactManifest = Get-Content -LiteralPath $artifactManifestPath -Raw | ConvertFrom-Json
            $artifactVerified = $artifactManifest.sha256 -match '^[A-Fa-f0-9]{64}$' -and
                $apkDigest -eq $artifactManifest.sha256 -and
                $artifactManifest.packageId -eq 'vn.edu.dlu.lmsmobile' -and
                [IO.Path]::GetFileName($ApkPath) -eq 'DLU_LMS_Support_Perfection_Final_Debug.apk'
        }
    }
    Add-PreflightResult 'Final APK matches reviewed artifact' $artifactVerified
}
catch { Add-PreflightResult 'Preflight execution' $false 'safe check could not complete; no diagnostic payload printed' }

$failed = @($preflightResults | Where-Object { -not $_.Passed })
if ($failed.Count -eq 0) {
    Write-Host 'READY FOR DEMO - staging product scope only'
    exit 0
}
Write-Host 'NOT READY - resolve failed checks; no state or credentials were changed'
if ($AllowDirty -and @($failed | Where-Object { $_.Name -ne 'Working tree' }).Count -eq 0) {
    Write-Host 'Diagnostic mode complete; working tree still needs review/commit.'
    exit 0
}
exit 1
