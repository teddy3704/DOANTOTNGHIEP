[CmdletBinding()]
param([int]$DemoStudentId = 205, [int]$DemoTeacherId = 102)
$ErrorActionPreference = 'Stop'
# Owner-run: writes the git-ignored .local\backend.json for Start-LocalBackend.ps1.
# Asks for the lms_group_app password at a hidden prompt, generates a random JWT secret, prints no values,
# and restricts the file ACL to the current user before any secret is written.
$root = Split-Path $PSScriptRoot
$dir = Join-Path $root '.local'
$path = Join-Path $dir 'backend.json'
if (Test-Path -LiteralPath $path) { throw "$path already exists; not overwriting." }
Push-Location $root
try {
    git check-ignore -q '.local/backend.json'
    if ($LASTEXITCODE -ne 0) { throw '.local/backend.json is not git-ignored; stopping.' }
} finally { Pop-Location }

New-Item -ItemType Directory -Force $dir | Out-Null
New-Item -ItemType File $path | Out-Null
$user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls $path /inheritance:r /grant:r "${user}:(F)" | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not restrict the file ACL.' }

$secure = Read-Host -AsSecureString 'Password for lms_group_app'
$bytes = [byte[]]::new(48)
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$config = [ordered]@{
    DB_URL          = 'jdbc:postgresql://127.0.0.1:55432/lms_mobile_group_dev'
    DB_USERNAME     = 'lms_group_app'
    DB_PASSWORD     = [Net.NetworkCredential]::new('', $secure).Password
    JWT_SECRET      = [Convert]::ToBase64String($bytes)
    DEMO_STUDENT_ID = "$DemoStudentId"
    DEMO_TEACHER_ID = "$DemoTeacherId"
}
try {
    [IO.File]::WriteAllText($path, ($config | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
} finally {
    $config.DB_PASSWORD = $null
    $config.JWT_SECRET = $null
    [Array]::Clear($bytes, 0, $bytes.Length)
    $secure.Dispose()
}
$acl = (Get-Acl $path).Access | ForEach-Object { "$($_.IdentityReference):$($_.FileSystemRights)" }
Write-Output "Wrote $path (values withheld). ACL: $($acl -join '; ')"
