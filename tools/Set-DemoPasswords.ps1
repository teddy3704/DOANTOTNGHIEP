[CmdletBinding()]
param(
    # Automation only (e.g. an agent's test session): one password per line, same order as the accounts.
    # The file must live outside the repository; the caller deletes it afterwards. Owners use the hidden prompts.
    [string]$PasswordFile = ''
)
$ErrorActionPreference = 'Stop'
# Needs .NET (Core) process APIs: rerun under PowerShell 7 when started from Windows PowerShell 5.
if ($PSVersionTable.PSEdition -ne 'Core') {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { Write-Host 'Cần PowerShell 7 (pwsh).' -ForegroundColor Red; exit 1 }
    $a = @('-NoProfile', '-File', $PSCommandPath); if ($PasswordFile) { $a += @('-PasswordFile', $PasswordFile) }
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
$config | Add-Member -NotePropertyName AUTH -NotePropertyValue ([pscustomobject]@{ users = @($users) }) -Force
[IO.File]::WriteAllText($path, ($config | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
$check = [IO.File]::ReadAllText($path) | ConvertFrom-Json
if (@($check.AUTH.users).Count -ne $accounts.Count) { throw 'backend.json verification failed.' }
$config = $null; $check = $null; $hashes = $null
Write-Output 'Đã ghi tài khoản đăng nhập demo vào .local\backend.json (chỉ lưu hash BCrypt):'
foreach ($a in $accounts) { Write-Output ("  {0,-10} {1}" -f $a.login, $a.role) }
Write-Output 'Khởi động lại backend: .\tools\Stop-Demo.ps1 rồi .\tools\Start-Demo.ps1'
