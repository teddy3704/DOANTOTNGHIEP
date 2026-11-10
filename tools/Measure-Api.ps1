[CmdletBinding()]
param(
    [int]$Iterations = 200,
    [int]$Warmup = 10,
    [string]$BaseUrl = 'http://127.0.0.1:8081/api/v1',
    [int]$StudentCourse = 14,
    [int]$TeacherCourse = 14,
    [string]$OutDir = 'D:\DLU-LMS\Artifacts\v2'
)
$ErrorActionPreference = 'Stop'
# V2-E2: local API latency for the report (Chapter 5). GET requests only (no database writes).
# One demo login per role; tokens are never printed. Each endpoint: $Warmup untimed calls, then
# $Iterations timed calls, sequentially (1 user). Writes perf-<stamp>.csv + perf-<stamp>-machine.txt.
# Endpoints with p95 > 500 ms are listed with a note; no index is created anywhere.

$student = 205; $teacher = 102
$endpoints = @(
    @{ Name = 'dashboard';               Role = 'STUDENT'; Path = "/dev/students/$student/dashboard" },
    @{ Name = 'tasks';                   Role = 'STUDENT'; Path = "/dev/students/$student/tasks" },
    @{ Name = 'courses';                 Role = 'STUDENT'; Path = "/dev/students/$student/courses" },
    @{ Name = 'grades';                  Role = 'STUDENT'; Path = "/dev/students/$student/courses/$StudentCourse/grades" },
    @{ Name = 'grade-forecast';          Role = 'STUDENT'; Path = "/dev/students/$student/courses/$StudentCourse/grade-forecast" },
    @{ Name = 'study-recommendations';   Role = 'STUDENT'; Path = "/dev/students/$student/study-recommendations?limit=3" },
    @{ Name = 'learning-health';         Role = 'STUDENT'; Path = "/dev/students/$student/learning-health" },
    @{ Name = 'study-plan';              Role = 'STUDENT'; Path = "/dev/students/$student/study-plan" },
    @{ Name = 'flashcards/due';          Role = 'STUDENT'; Path = "/dev/students/$student/flashcards/due" },
    @{ Name = 'teacher courses';         Role = 'TEACHER'; Path = "/dev/teachers/$teacher/courses" },
    @{ Name = 'teacher grade-forecast';  Role = 'TEACHER'; Path = "/dev/teachers/$teacher/courses/$TeacherCourse/grade-forecast" },
    @{ Name = 'engagement-heatmap';      Role = 'TEACHER'; Path = "/dev/teachers/$teacher/courses/$TeacherCourse/engagement-heatmap?weeks=8" }
)

Add-Type -AssemblyName System.Net.Http
$client = [Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromSeconds(30)

function Get-Token([string]$role) {
    $body = [Net.Http.StringContent]::new("{`"role`":`"$role`"}", [Text.Encoding]::UTF8, 'application/json')
    $resp = $client.PostAsync("$BaseUrl/auth/demo-login", $body).GetAwaiter().GetResult()
    if (-not $resp.IsSuccessStatusCode) { throw "Đăng nhập demo $role lỗi HTTP $([int]$resp.StatusCode). Backend đã chạy chưa?" }
    ($resp.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json).token
}

function Invoke-Timed([string]$path, [string]$token) {
    $req = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get, "$BaseUrl$path")
    $req.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = $client.SendAsync($req).GetAwaiter().GetResult()
        [void]$resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()   # include body transfer
        $sw.Stop()
        return @{ Ms = $sw.Elapsed.TotalMilliseconds; Ok = $resp.IsSuccessStatusCode; Status = [int]$resp.StatusCode }
    } catch {
        $sw.Stop()
        return @{ Ms = $sw.Elapsed.TotalMilliseconds; Ok = $false; Status = 0 }
    } finally { $req.Dispose() }
}

# Nearest-rank percentile on a sorted array.
function Get-Pct([double[]]$sorted, [double]$p) {
    if ($sorted.Count -eq 0) { return $null }
    $rank = [math]::Ceiling($p / 100 * $sorted.Count)
    return $sorted[[math]::Max(0, $rank - 1)]
}

$tokens = @{ STUDENT = Get-Token 'STUDENT'; TEACHER = Get-Token 'TEACHER' }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$csv = Join-Path $OutDir "perf-$stamp.csv"
$rows = @()
foreach ($e in $endpoints) {
    $token = $tokens[$e.Role]
    for ($i = 0; $i -lt $Warmup; $i++) { [void](Invoke-Timed $e.Path $token) }
    $times = [Collections.Generic.List[double]]::new()
    $errors = 0; $statuses = @{}
    for ($i = 0; $i -lt $Iterations; $i++) {
        $r = Invoke-Timed $e.Path $token
        $times.Add($r.Ms)
        if (-not $r.Ok) { $errors++; $statuses[$r.Status] = 1 + [int]$statuses[$r.Status] }
    }
    $sorted = [double[]]($times | Sort-Object)
    $row = [pscustomobject]@{
        endpoint = $e.Name; role = $e.Role; path = $e.Path; n = $Iterations; errors = $errors
        p50_ms = [math]::Round((Get-Pct $sorted 50), 1)
        p95_ms = [math]::Round((Get-Pct $sorted 95), 1)
        max_ms = [math]::Round($sorted[-1], 1)
        mean_ms = [math]::Round(($times | Measure-Object -Average).Average, 1)
        error_statuses = (($statuses.GetEnumerator() | ForEach-Object { "$($_.Key)x$($_.Value)" }) -join ' ')
    }
    $rows += $row
    Write-Host ("{0,-24} p50 {1,7} ms  p95 {2,7} ms  max {3,7} ms  lỗi {4}" -f $row.endpoint, $row.p50_ms, $row.p95_ms, $row.max_ms, $row.errors)
}
$rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
$client.Dispose()
$tokens = $null

# Machine / setup note next to the CSV.
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$os = Get-CimInstance Win32_OperatingSystem
$health = $null
$slow = @($rows | Where-Object { $_.p95_ms -gt 500 })
$note = @(
    "Đo cục bộ, 1 người dùng, tuần tự; $Warmup lần khởi động không tính, $Iterations lần đo mỗi endpoint; chỉ GET (không ghi CSDL).",
    "Thời gian = gửi request đến khi nhận xong body (HttpClient trên cùng máy, 127.0.0.1).",
    "Máy: $($cpu.Name.Trim()), $($cpu.NumberOfCores) nhân / $($cpu.NumberOfLogicalProcessors) luồng, RAM $([math]::Round($os.TotalVisibleMemorySize / 1MB, 1)) GiB, $($os.Caption) $($os.Version).",
    "Backend: Spring Boot (mvn spring-boot:run), PostgreSQL 18 cục bộ 127.0.0.1:55432; DB theo .local\backend.json (Start-Demo mặc định lms_mobile_group_demo).",
    "SV $student, GV $teacher, khóa SV $StudentCourse, khóa GV $TeacherCourse. Portal không đo ở đây (số đo Portal xem HANDOFF V3).",
    $(if ($slow.Count -gt 0) { "p95 > 500 ms: $(($slow | ForEach-Object endpoint) -join ', ') — chỉ đề xuất index, không tự tạo." } else { 'Không endpoint nào có p95 > 500 ms.' })
)
$note | Set-Content -LiteralPath (Join-Path $OutDir "perf-$stamp-machine.txt") -Encoding utf8
Write-Host "CSV: $csv" -ForegroundColor Green
