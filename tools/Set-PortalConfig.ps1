[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
# V3-P0, owner-run. Merges the DLU training-portal settings into the git-ignored .local\backend.json:
#   - API key from thầy Hiếu: hidden prompt, never printed (only its last 4 characters).
#   - Demo mapping, decided by the server, never by app users: the LMS demo student (DEMO_STUDENT_ID)
#     -> MSSV + CTĐT + class of ONE consenting team member; the demo teacher (DEMO_TEACHER_ID) ->
#     advisor class codes.
# Do NOT paste the public mk_dev_... key shown on the API docs page. Re-run to change values; press
# Enter at the key prompt to keep the stored key. Restart the backend afterwards.
$root = Split-Path $PSScriptRoot
$path = Join-Path $root '.local\backend.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'LOCAL_DATABASE_CONFIGURATION_REQUIRED (run tools\New-LocalBackendConfig.ps1 first).' }
Push-Location $root
try {
    git check-ignore -q '.local/backend.json'
    if ($LASTEXITCODE -ne 0) { throw '.local/backend.json is not git-ignored; stopping.' }
} finally { Pop-Location }

function Get-Masked([string]$id) {
    if (-not $id) { return '' }
    -join (0..($id.Length - 1) | ForEach-Object { if ($_ % 4 -lt 2) { $id[$_] } else { '*' } })
}
function Read-Checked([string]$prompt, [string]$pattern, [string]$current) {
    while ($true) {
        $suffix = if ($current) { " [Enter = giữ $(Get-Masked $current)]" } else { '' }
        $value = (Read-Host "$prompt$suffix").Trim()
        if (-not $value -and $current) { return $current }
        if ($value -match $pattern) { return $value.ToUpperInvariant() }
        Write-Host "  Giá trị không hợp lệ (mẫu: $pattern)."
    }
}

$config = [IO.File]::ReadAllText($path) | ConvertFrom-Json
$old = $config.PORTAL
$studentUser = [string]$config.DEMO_STUDENT_ID
$teacherUser = [string]$config.DEMO_TEACHER_ID
if (-not $studentUser -or -not $teacherUser) { throw 'DEMO_STUDENT_ID / DEMO_TEACHER_ID missing in backend.json.' }

$secure = Read-Host -AsSecureString 'API key Portal (X-API-KEY) do thầy Hiếu cấp [Enter = giữ key cũ]'
$key = [Net.NetworkCredential]::new('', $secure).Password.Trim()
$secure.Dispose()
if (-not $key) {
    if (-not $old -or -not $old.apiKey) { throw 'No API key entered and none stored; nothing written.' }
    $key = [string]$old.apiKey
}
if ($key -like 'mk_dev_*') {
    Write-Warning 'Key có dạng mk_dev_… (key công khai trên trang docs). Chỉ dùng nếu thầy Hiếu xác nhận đây là key cấp cho nhóm.'
}

$oldStudent = if ($old -and $old.students) { $old.students.$studentUser } else { $null }
Write-Output "Ánh xạ cho sinh viên demo userId=$studentUser (thành viên nhóm ĐÃ ĐỒNG Ý cho dùng dữ liệu của mình):"
$mssv = Read-Checked '  MSSV' '^[A-Za-z0-9]{6,12}$' ([string]$oldStudent.studentId)
$program = Read-Checked '  Mã CTĐT (vd CQ23CT-PM)' '^(?i)CQ\d{2}CT(-PM|-MMT)?$' ([string]$oldStudent.studyProgramId)
$class = Read-Checked '  Mã lớp (vd ITK47C)' '^(?i)ITK\d{2}[A-Z]$' ([string]$oldStudent.classId)
$oldAdvisors = if ($old -and $old.advisors -and $old.advisors.$teacherUser) { ($old.advisors.$teacherUser -join ',') } else { '' }
$advisorText = Read-Checked "Mã lớp cố vấn của giảng viên demo userId=$teacherUser (cách nhau dấu phẩy)" '^(?i)ITK\d{2}[A-Z](\s*,\s*ITK\d{2}[A-Z])*$' $oldAdvisors
$advisorClasses = @($advisorText -split '\s*,\s*' | ForEach-Object { $_.ToUpperInvariant() } | Select-Object -Unique)

$portal = [ordered]@{
    enabled          = $true
    baseUrl          = 'https://quan-ly-dao-tao-api.nguyentronghieu.io.vn'
    apiKey           = $key
    presentationMask = $true
    students         = [ordered]@{ $studentUser = [ordered]@{ studentId = $mssv; studyProgramId = $program; classId = $class } }
    advisors         = [ordered]@{ $teacherUser = $advisorClasses }
}
if ($old -and $old.courseMap) { $portal.courseMap = $old.courseMap }
$config | Add-Member -NotePropertyName PORTAL -NotePropertyValue $portal -Force
try {
    # WriteAllText keeps the existing file and therefore its restricted ACL. Depth: PORTAL is nested 4 levels.
    [IO.File]::WriteAllText($path, ($config | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
} finally {
    $portal.apiKey = $null
    $config = $null
}

# Connectivity only: /health takes no key and returns no personal data.
$health = try {
    (Invoke-RestMethod -Uri 'https://quan-ly-dao-tao-api.nguyentronghieu.io.vn/health' -TimeoutSec 10).app
} catch { 'unreachable' }

Write-Output ''
Write-Output "Đã ghi PORTAL vào $path (ACL giữ nguyên)."
Write-Output "  key       : ****$($key.Substring([Math]::Max(0, $key.Length - 4)))"
Write-Output "  sinh viên : userId $studentUser -> MSSV $(Get-Masked $mssv), CTĐT $program, lớp $class"
Write-Output "  cố vấn    : userId $teacherUser -> $($advisorClasses -join ', ')"
Write-Output "  ẩn danh trình chiếu: BẬT; Portal /health: $health"
Write-Output 'Khởi động lại backend: .\tools\Start-LocalBackend.ps1'
$key = $null
