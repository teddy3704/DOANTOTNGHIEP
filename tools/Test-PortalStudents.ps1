[CmdletBinding()]
param(
    # Only the group's own student codes (REAL-DATA-1). Do not pass anyone else's.
    [string[]]$StudentIds = @('2212472', '2212496', '2212412')
)
$ErrorActionPreference = 'Stop'
# REAL-DATA-1: does the Portal API have data for these student codes? Uses the PORTAL block of the
# git-ignored .local\backend.json in-process (key never printed). Tries every study program and class
# already configured there. Prints only: found / not found, record counts, the program/class code that matched.
$allowed = @('2212472', '2212496', '2212412')
foreach ($s in $StudentIds) { if ($s -notin $allowed) { throw "Only the group's student codes are allowed ($($allowed -join ', '))." } }
$path = Join-Path (Split-Path $PSScriptRoot) '.local\backend.json'
$cfg = [IO.File]::ReadAllText($path) | ConvertFrom-Json
if (-not $cfg.PORTAL -or -not $cfg.PORTAL.baseUrl) { throw 'PORTAL block missing in backend.json.' }
$base = ([string]$cfg.PORTAL.baseUrl).TrimEnd('/')
$headers = @{ 'X-API-KEY' = [string]$cfg.PORTAL.apiKey }
$programs = @(); $classes = @()
if ($cfg.PORTAL.students) {
    foreach ($p in $cfg.PORTAL.students.PSObject.Properties) { $programs += [string]$p.Value.studyProgramId; $classes += [string]$p.Value.classId }
}
if ($cfg.PORTAL.advisors) {
    foreach ($p in $cfg.PORTAL.advisors.PSObject.Properties) { $classes += @($p.Value | ForEach-Object { [string]$_ }) }
}
$programs = @($programs | Where-Object { $_ } | Sort-Object -Unique)
$classes = @($classes | Where-Object { $_ } | ForEach-Object { $_.Trim().ToUpper() } | Sort-Object -Unique)
$cfg = $null

function Call([string]$endpoint, [hashtable]$body) {
    try {
        $r = Invoke-RestMethod -Method Post -Uri "$base$endpoint" -Headers $headers -ContentType 'application/json' `
            -Body ($body | ConvertTo-Json -Compress) -TimeoutSec 20
        $data = if ($null -ne $r.data) { $r.data } else { $r }
        return [pscustomobject]@{ ok = $true; count = @($data).Count; json = ($data | ConvertTo-Json -Depth 8 -Compress) }
    } catch {
        $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 'IO' }
        return [pscustomobject]@{ ok = $false; count = 0; json = ''; code = $code }
    }
}

Write-Output "Portal: $($programs.Count) program code(s), $($classes.Count) class code(s) configured to try."
$classLists = @{}
foreach ($c in $classes) { $classLists[$c] = Call '/api/v1/LayDanhSachSinhVienTheoLop' @{ Id = $c } }
$okClasses = @($classes | Where-Object { $classLists[$_].ok }).Count
Write-Output "Kiểm tra Portal: $okClasses/$($classes.Count) lớp đã cấu hình trả lời OK (Portal hoạt động)."
foreach ($sid in $StudentIds) {
    $inClass = @($classes | Where-Object { $classLists[$_].ok -and $classLists[$_].json -match "\b$sid\b" })
    $dec = Call '/api/v1/LayDanhSachQuyetDinh' @{ p1 = $sid }
    $best = $null
    foreach ($p in $programs) {
        $t = Call '/api/v1/LayBangDiemSinhVien' @{ p1 = $sid; p2 = $p; p3 = 'ALL'; p4 = 'ALL' }
        if ($t.ok -and $t.count -gt 0 -and (-not $best -or $t.count -gt $best.count)) { $best = [pscustomobject]@{ program = $p; count = $t.count } }
    }
    $line = "{0}: lớp chứa MSSV = {1}; bảng điểm = {2}; quyết định = {3}" -f $sid,
        $(if ($inClass) { $inClass -join ',' } else { 'không' }),
        $(if ($best) { "$($best.count) bản ghi (CTĐT $($best.program))" } else { 'không có' }),
        $(if ($dec.ok) { "$($dec.count) bản ghi" } else { "lỗi $($dec.code)" })
    Write-Output $line
}
$headers = $null
