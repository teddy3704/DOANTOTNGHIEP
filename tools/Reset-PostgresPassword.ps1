[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
# Owner-run recovery for a forgotten password of role "postgres" on the group-only cluster
# (D:\DLU-LMS\PostgreSQL\data, 127.0.0.1:55432, no Windows service).
#
# What it does, in order:
#   1. Refuses unless the cluster is the verified D: instance listening on 127.0.0.1 only.
#   2. Saves pg_hba.conf byte-for-byte to D:\DLU-LMS\PostgreSQL\logs.
#   3. Prepends ONE temporary rule: host postgres postgres 127.0.0.1/32 trust
#      (database "postgres", user "postgres", loopback only), then reloads/starts the server.
#   4. Runs psql \password postgres: you type the new password twice at a hidden prompt; psql hashes it
#      (SCRAM) before sending, so it never appears on screen, in history or in server logs.
#   5. In finally{}: writes the saved pg_hba.conf back byte-for-byte, reloads, checks the hash matches
#      and that a password-less login is refused again.
# Do not close this window while it runs. If it is closed mid-way, restore the backup printed below
# over D:\DLU-LMS\PostgreSQL\data\pg_hba.conf (Use-LocalPostgres.ps1 -Action Start refuses to start
# while any non-scram rule exists, so the cluster cannot silently stay open).
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
$pgData = 'D:\DLU-LMS\PostgreSQL\data'
$pgLogs = 'D:\DLU-LMS\PostgreSQL\logs'
$port = 55432
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
$pgCtl = Join-Path $pgBin 'pg_ctl.exe'
$psql = Join-Path $pgBin 'psql.exe'
$hba = Join-Path $pgData 'pg_hba.conf'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $pgLogs "pg_hba.conf.before-reset-$stamp"
$conn = @('-X', '-w', '-h', '127.0.0.1', '-p', "$port", '-U', 'postgres', '-d', 'postgres')

# ---------------------------------------------------------------- 1. safety checks (read-only)
foreach ($p in $pgCtl, $psql, (Join-Path $pgData 'PG_VERSION'), $hba) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Not found: $p" }
}
$settings = @{}
foreach ($file in 'postgresql.conf', 'postgresql.auto.conf') {
    foreach ($line in Get-Content (Join-Path $pgData $file)) {
        if ($line -match "^\s*(\w+)\s*=\s*'?([^'#]*?)'?\s*(#.*)?$") { $settings[$Matches[1]] = $Matches[2].Trim() }
    }
}
if ($settings['listen_addresses'] -ne '127.0.0.1' -or $settings['port'] -ne "$port") {
    throw "Cluster must listen on 127.0.0.1:$port only (found '$($settings['listen_addresses'])':'$($settings['port'])'). Stopping."
}
$rules = Get-Content $hba | Where-Object { $_ -match '^\s*[^#\s]' }
if ($rules | Where-Object { $_ -notmatch '\sscram-sha-256\s*$' }) {
    throw "pg_hba.conf already has a non-scram rule. Restore it first (see earlier backups in $pgLogs). Stopping."
}
New-Item -ItemType Directory -Force $pgLogs, $env:TEMP | Out-Null

# Native calls run with 'Continue' so stderr text never turns into a terminating error (Windows PowerShell 5.1).
function Invoke-Quiet([string]$Exe, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    & $Exe @Arguments *> $null
    return $LASTEXITCODE
}
function Test-Running { return ((Invoke-Quiet $pgCtl @('status', '-D', $pgData)) -eq 0) }
function Test-NoPasswordLogin { return ((Invoke-Quiet $psql ($conn + @('-tAc', 'SELECT 1'))) -eq 0) }
function Invoke-Reload {
    $code = Invoke-Quiet $pgCtl @('reload', '-D', $pgData)
    if ($code -ne 0) { throw "pg_ctl reload failed ($code)." }
    Start-Sleep -Seconds 2
}

$original = [IO.File]::ReadAllBytes($hba)
[IO.File]::WriteAllBytes($backup, $original)
$originalHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash
Write-Output "Saved pg_hba.conf -> $backup (sha256 $originalHash)"

$opened = $false
try {
    # ------------------------------------------------------------ 2. temporary loopback-only trust rule
    $temp = [Text.Encoding]::ASCII.GetBytes("host    postgres    postgres    127.0.0.1/32    trust`r`n")
    [IO.File]::WriteAllBytes($hba, [byte[]]($temp + $original))
    $opened = $true
    if (Test-Running) {
        Invoke-Reload
        Write-Output 'Server was running: reloaded with the temporary rule.'
    } else {
        # Not redirected: the server child must not inherit a pipe this window waits on.
        $ErrorActionPreference = 'Continue'
        & $pgCtl start -D $pgData -w -l (Join-Path $pgLogs 'pg_ctl.log')
        $code = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($code -ne 0) { throw "pg_ctl start failed ($code); see $pgLogs\pg_ctl.log." }
        Write-Output 'Server started with the temporary rule.'
    }
    if (-not (Test-NoPasswordLogin)) { throw 'Temporary rule did not take effect; nothing was changed.' }

    # ------------------------------------------------------------ 3. new password (hidden prompt, hashed client-side)
    Write-Output ''
    Write-Output 'Type the NEW password for postgres twice (nothing is shown while typing). Save it in a password manager.'
    $ErrorActionPreference = 'Continue'
    & $psql @conn -c '\password postgres'
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($code -ne 0) { throw "Setting the password failed (psql exit $code). Old password unchanged." }
    Write-Output 'Password changed.'
} finally {
    # ------------------------------------------------------------ 4. always restore the original rules
    if ($opened) {
        [IO.File]::WriteAllBytes($hba, $original)
        if (Test-Running) { Invoke-Reload }
        $nowHash = (Get-FileHash -LiteralPath $hba -Algorithm SHA256).Hash
        if ($nowHash -ne $originalHash) {
            Write-Warning "pg_hba.conf hash differs from backup! Copy $backup over $hba by hand, then run: pg_ctl reload."
        } else {
            Write-Output "pg_hba.conf restored byte-for-byte (sha256 $nowHash)."
        }
        if (Test-Running) {
            if (Test-NoPasswordLogin) {
                Write-Warning 'A password-less login still works! Do not continue; restore the backup above and reload.'
            } else {
                Write-Output 'Check OK: login without a password is refused again (scram-sha-256 only).'
            }
        } else {
            Write-Output 'Server is not running; pg_hba.conf restored on disk.'
        }
    }
}
Write-Output 'Server left running. Next: .\tools\Apply-V2Migration.ps1 -CreateDemo -DemoTargetDate <yyyy-MM-dd> with the new password.'
