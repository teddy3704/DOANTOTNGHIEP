[CmdletBinding()]
param(
    # REAL-DATA-1: 'real' writes the separate AUTH_REAL block used when the backend reads lms_mobile_group_real.
    [ValidateSet('demo', 'real')][string]$Database = 'demo',
    # Real only: which group accounts get a password (ngaptt only after the supervisor agreed).
    [string[]]$Logins = @('2212472', '2212496', '2212412'),
    # Automation only (e.g. an agent's test session): one password per line, same order as the accounts.
    # The file must live outside the repository; the caller deletes it afterwards. Owners use the hidden prompts.
    [string]$PasswordFile = ''
)
$ErrorActionPreference = 'Stop'
# Needs .NET (Core) process APIs: rerun under PowerShell 7 when started from Windows PowerShell 5.
if ($PSVersionTable.PSEdition -ne 'Core') {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { Write-Host 'Cần PowerShell 7 (pwsh).' -ForegroundColor Red; exit 1 }
    $a = @('-NoProfile', '-File', $PSCommandPath, '-Database', $Database, '-Logins', ($Logins -join ','))
    if ($PasswordFile) { $a += @('-PasswordFile', $PasswordFile) }
    & $pwsh @a
    exit $LASTEXITCODE
}
# LOGIN — owner-run: set the demo sign-in passwords (student code / username + password).
#   SV 205 login 2312005 (STUDENT), SV 201 login 2212001 (STUDENT, to show that one student cannot read another),
#   GV 102 login teacher02 (TEACHER).
# Each password is read with Read-Host -AsSecureString and hashed with BCrypt cost 12 by the backend JAR itself
# (com.dlu.lmsmobile.tools.BcryptCli, Spring Security), via stdin — never on a command line, never printed.
# Only the hashes go into the git-ignored .local\backend.json (AUTH block). Restart the backend afterwards.
$root = Split-Path $PSScriptRoot
$path = Join-Path $root '.local\backend.json'
$accounts = @(
    [ordered]@{ login = '2312005'; userId = 205; role = 'STUDENT' },
    [ordered]@{ login = '2212001'; userId = 201; role = 'STUDENT' },
    [ordered]@{ login = 'teacher02'; userId = 102; role = 'TEACHER' }
)
$authKey = 'AUTH'
if ($Database -eq 'real') {
    # The group's own Moodle accounts in the real export (userid from dlu_user.csv). Nobody else.
    $known = @{
        '2212472' = [ordered]@{ login = '2212472'; userId = 21721; role = 'STUDENT' }
        '2212496' = [ordered]@{ login = '2212496'; userId = 21740; role = 'STUDENT' }
        '2212412' = [ordered]@{ login = '2212412'; userId = 21665; role = 'STUDENT' }
        'ngaptt'  = [ordered]@{ login = 'ngaptt'; userId = 120; role = 'TEACHER' }
    }
    $list = @($Logins | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($l in $list) { if (-not $known.ContainsKey($l)) { throw "Login '$l' không thuộc tài khoản nhóm (2212472, 2212496, 2212412, ngaptt)." } }
    if (@($list | Where-Object { $known[$_].role -eq 'STUDENT' }).Count -eq 0) { throw 'Cần ít nhất một tài khoản sinh viên.' }
    $accounts = @($list | ForEach-Object { $known[$_] })
    $authKey = 'AUTH_REAL'
}

. (Join-Path $PSScriptRoot 'Use-LocalToolchain.ps1') *> $null
if (-not (Test-Path -LiteralPath $path)) { throw 'LOCAL_DATABASE_CONFIGURATION_REQUIRED (.local\backend.json not found).' }
Push-Location $root
try {
    git check-ignore -q '.local/backend.json'
    if ($LASTEXITCODE -ne 0) { throw '.local/backend.json is not git-ignored; stopping.' }
} finally { Pop-Location }
$jar = Get-ChildItem (Join-Path $root 'backend\target') -Filter 'lms_mobile_backend-*.jar' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $jar) { throw 'Backend JAR not found: run .\tools\Test-Backend.ps1 -Package first.' }
$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\java.exe' } else { 'java' }

$passwords = @()
if ($PasswordFile) {
    $passwords = @([IO.File]::ReadAllLines($PasswordFile) | Where-Object { $_ -ne '' })
    if ($passwords.Count -ne $accounts.Count) { throw "PasswordFile must hold $($accounts.Count) non-empty lines." }
} else {
    foreach ($a in $accounts) {
        $s1 = Read-Host -AsSecureString "Mật khẩu cho $($a.login) ($($a.role))"
        $s2 = Read-Host -AsSecureString 'Nhập lại'
        $p1 = [Net.NetworkCredential]::new('', $s1).Password
        $p2 = [Net.NetworkCredential]::new('', $s2).Password
        $s1.Dispose(); $s2.Dispose()
        if ($p1 -ne $p2) { throw "Hai lần nhập không khớp cho $($a.login); không thay đổi gì." }
        if ($p1.Length -lt 8 -or $p1.Length -gt 128) { throw 'Mật khẩu cần 8–128 ký tự; không thay đổi gì.' }
        $passwords += $p1
    }
}

# Hash through the JAR: PropertiesLauncher runs the small CLI class with the JAR's own Spring Security.
$psi = [Diagnostics.ProcessStartInfo]::new($java)
foreach ($arg in @('-cp', $jar.FullName, '-Dloader.main=com.dlu.lmsmobile.tools.BcryptCli',
        'org.springframework.boot.loader.launch.PropertiesLauncher')) { $psi.ArgumentList.Add($arg) }
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$proc = [Diagnostics.Process]::Start($psi)
foreach ($p in $passwords) { $proc.StandardInput.WriteLine($p) }
$proc.StandardInput.Close()
$hashes = @($proc.StandardOutput.ReadToEnd() -split "`r?`n" | Where-Object { $_ -like '$2*' })
$proc.WaitForExit()
$passwords = $null
if ($proc.ExitCode -ne 0 -or $hashes.Count -ne $accounts.Count) { throw "Hashing failed (exit $($proc.ExitCode)); backend.json unchanged." }

$config = [IO.File]::ReadAllText($path) | ConvertFrom-Json
$users = for ($i = 0; $i -lt $accounts.Count; $i++) {
    [pscustomobject][ordered]@{ login = $accounts[$i].login; userId = $accounts[$i].userId; role = $accounts[$i].role; bcrypt = $hashes[$i] }
}
$config | Add-Member -NotePropertyName $authKey -NotePropertyValue ([pscustomobject]@{ users = @($users) }) -Force
[IO.File]::WriteAllText($path, ($config | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
$check = [IO.File]::ReadAllText($path) | ConvertFrom-Json
if (@($check.$authKey.users).Count -ne $accounts.Count) { throw 'backend.json verification failed.' }
$config = $null; $check = $null; $hashes = $null
Write-Output 'Đã ghi tài khoản đăng nhập demo vào .local\backend.json (chỉ lưu hash BCrypt):'
foreach ($a in $accounts) { Write-Output ("  {0,-10} {1}" -f $a.login, $a.role) }
Write-Output 'Khởi động lại backend: .\tools\Stop-Demo.ps1 rồi .\tools\Start-Demo.ps1'
