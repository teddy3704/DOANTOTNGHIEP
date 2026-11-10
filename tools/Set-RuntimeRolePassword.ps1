[CmdletBinding()]
param([ValidateRange(24, 64)][int]$Length = 32)
$ErrorActionPreference = 'Stop'
# Owner-run: rotate the password of the backend runtime role lms_group_app.
#   1. Asks for the postgres password (hidden prompt, process environment only).
#   2. Generates a random alphanumeric password (default 32 chars, CSPRNG, no modulo bias).
#   3. ALTER ROLE via psql stdin (never on a command line), in a session with statement logging off.
#   4. Verifies a real login as lms_group_app with the new password.
#   5. Writes DB_PASSWORD into the git-ignored .local\backend.json (existing file, so its ACL is kept).
# If verification or the file write fails, the old password (read from backend.json) is restored.
# Nothing secret is printed. Restart the backend afterwards (tools\Start-LocalBackend.ps1).
$root = Split-Path $PSScriptRoot
$path = Join-Path $root '.local\backend.json'
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$psql = Join-Path $pgBin 'psql.exe'
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $path)) { throw 'LOCAL_DATABASE_CONFIGURATION_REQUIRED (.local\backend.json not found).' }
if (-not (Test-Path -LiteralPath $psql)) { throw "psql not found at $psql" }
Push-Location $root
try {
    git check-ignore -q '.local/backend.json'
    if ($LASTEXITCODE -ne 0) { throw '.local/backend.json is not git-ignored; stopping.' }
} finally { Pop-Location }

$config = [IO.File]::ReadAllText($path) | ConvertFrom-Json
if ($config.DB_USERNAME -ne 'lms_group_app') { throw 'DB_USERNAME in backend.json is not lms_group_app; stopping.' }
if ($config.DB_URL -notmatch '^jdbc:postgresql://(?:127\.0\.0\.1|localhost):55432/(lms_mobile_group_(?:dev|demo))') {
    throw 'DB_URL is not the local 127.0.0.1:55432 group cluster; stopping.'
}
$database = $Matches[1]
$oldPassword = [string]$config.DB_PASSWORD

function New-RandomPassword([int]$n) {
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $limit = 256 - (256 % $alphabet.Length)   # rejection sampling: uniform over the alphabet
    $chars = [Collections.Generic.List[char]]::new()
    $buffer = [byte[]]::new(64)
    while ($chars.Count -lt $n) {
        [Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
        foreach ($b in $buffer) {
            if ($b -lt $limit -and $chars.Count -lt $n) { $chars.Add($alphabet[$b % $alphabet.Length]) }
        }
    }
    [Array]::Clear($buffer, 0, $buffer.Length)
    -join $chars
}

# Runs SQL (from stdin) as postgres; statement logging is switched off for this session first.
function Invoke-AsPostgres([string]$sql) {
    $script = "SET log_statement = 'none';`nSET log_min_error_statement = 'panic';`nSET log_min_duration_statement = -1;`n$sql`n"
    $null = $script | & $psql -X -q -h 127.0.0.1 -p 55432 -U postgres -d $database -v ON_ERROR_STOP=1 -f - 2>&1
    return $LASTEXITCODE
}

function Test-AppLogin([string]$password) {
    $env:PGPASSWORD = $password
    try {
        $r = & $psql -X -w -q -t -A -h 127.0.0.1 -p 55432 -U lms_group_app -d $database -c 'SELECT 1' 2>$null
        return ($LASTEXITCODE -eq 0 -and "$r".Trim() -eq '1')
    } finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

$secure = Read-Host -AsSecureString 'Password for cluster role postgres'
$new = New-RandomPassword $Length
$changed = $false
try {
    $env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password
    # Alphanumeric only, so no quoting/escaping issues in the literal.
    $code = Invoke-AsPostgres "ALTER ROLE lms_group_app WITH PASSWORD '$new';"
    if ($code -ne 0) { throw "ALTER ROLE failed (psql exit $code). Password unchanged." }
    $changed = $true
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

    if (-not (Test-AppLogin $new)) { throw 'Login as lms_group_app with the new password failed.' }
    Write-Output "Role password changed and verified (length $Length, database $database)."

    $config.DB_PASSWORD = $new
    [IO.File]::WriteAllText($path, ($config | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
    $check = [IO.File]::ReadAllText($path) | ConvertFrom-Json
    if ([string]$check.DB_PASSWORD -ne $new) { throw 'backend.json verification failed.' }
    $check = $null
    $changed = $false   # committed: nothing to roll back
    Write-Output "Updated DB_PASSWORD in $path (other values unchanged, none printed)."
    Write-Output 'Restart the backend: .\tools\Start-LocalBackend.ps1'
} catch {
    if ($changed -and $oldPassword) {
        $env:PGPASSWORD = [Net.NetworkCredential]::new('', $secure).Password
        $restore = Invoke-AsPostgres "ALTER ROLE lms_group_app WITH PASSWORD '$($oldPassword.Replace("'", "''"))';"
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        Write-Warning ("Rolled back to the previous password: " + $(if ($restore -eq 0) { 'OK' } else { "FAILED (exit $restore) — rerun this script" }))
    }
    throw
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $secure.Dispose()
    $new = $null
    $oldPassword = $null
    $config = $null
}
