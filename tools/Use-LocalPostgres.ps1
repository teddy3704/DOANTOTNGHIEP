[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Check', 'Start', 'Stop', 'Status', 'Verify')][string]$Action)
$ErrorActionPreference = 'Stop'
# Group-only PostgreSQL 18 cluster, everything on D, loopback only, no Windows service.
# initdb is NOT run by this script: the owner runs the documented initdb command in their own
# console (password typed at the hidden prompt). Verify prompts for the password; never pass it.
# Only the signature-verified set; never the unverified zip extract in ...\pgsql-18.
$pgBin = 'D:\DLU-LMS\Toolchains\pgsql-18-verified\bin'
if (-not (Test-Path (Join-Path $pgBin 'postgres.exe'))) { throw "Verified PostgreSQL binaries not found at $pgBin." }
$pgData = 'D:\DLU-LMS\PostgreSQL\data'
$pgLogs = 'D:\DLU-LMS\PostgreSQL\logs'
$pgPort = 55432
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

function Invoke-Pg([string]$exe, [string[]]$arguments) {
    & (Join-Path $pgBin $exe) @arguments
    if ($LASTEXITCODE -ne 0) { throw "$exe failed with exit $LASTEXITCODE." }
}

# Static pre-start check of the new cluster's own files; reads only.
function Test-ClusterConfig {
    if (((Get-PSDrive C).Free / 1GB) -lt 15) { throw 'STORAGE_BLOCKED' }
    if (-not (Test-Path (Join-Path $pgData 'PG_VERSION'))) { throw "$pgData is not an initialised cluster." }
    if ((Get-Item $pgData).LinkType -or (Get-Item (Join-Path $pgData 'pg_wal')).LinkType) { throw 'PGDATA or pg_wal is a link; verify its real drive first.' }
    if (Get-ChildItem (Join-Path $pgData 'pg_tblspc') -Force) { throw 'pg_tblspc is not empty.' }
    $settings = @{}
    foreach ($file in 'postgresql.conf', 'postgresql.auto.conf') {
        foreach ($line in Get-Content (Join-Path $pgData $file)) {
            if ($line -match "^\s*(\w+)\s*=\s*'?([^'#]*?)'?\s*(#.*)?$") { $settings[$Matches[1]] = $Matches[2].Trim() }
        }
    }
    $expected = @{ listen_addresses = '127.0.0.1'; port = "$pgPort"; logging_collector = 'on'; log_directory = ($pgLogs -replace '\\', '/') }
    foreach ($key in $expected.Keys) {
        if ($settings[$key] -ne $expected[$key]) { throw "postgresql.conf ${key}='$($settings[$key])', expected '$($expected[$key])'." }
    }
    $hba = Get-Content (Join-Path $pgData 'pg_hba.conf') | Where-Object { $_ -match '^\s*[^#\s]' }
    if ($hba | Where-Object { $_ -notmatch '\sscram-sha-256\s*$' }) { throw 'pg_hba.conf has a rule that is not scram-sha-256.' }
    if (Get-NetTCPConnection -LocalPort $pgPort -State Listen -ErrorAction SilentlyContinue) { throw "Port $pgPort is already in use." }
    Write-Output "Config OK: 127.0.0.1:$pgPort, scram-sha-256 only ($($hba.Count) rules), logs $pgLogs, no tablespaces/links."
}

function Invoke-Verify {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $out = Join-Path $pgLogs "t07a-verify-$stamp.txt"
    $queries = @(
        'SELECT version()',
        "SELECT name, setting FROM pg_settings WHERE name IN ('data_directory','port','listen_addresses','config_file','hba_file','logging_collector','log_directory','password_encryption','data_checksums','server_encoding') ORDER BY name",
        "SELECT current_setting('data_directory') || '\pg_wal' AS wal_dir",
        'SELECT spcname, pg_tablespace_location(oid) AS location FROM pg_tablespace ORDER BY spcname',
        'SELECT datname FROM pg_database ORDER BY datname',
        'SELECT rolname, rolsuper FROM pg_roles WHERE rolcanlogin ORDER BY rolname',
        'SELECT type, database, user_name, address, auth_method FROM pg_hba_file_rules ORDER BY rule_number'
    )
    $psqlArgs = @('-X', '-h', '127.0.0.1', '-p', "$pgPort", '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1')
    foreach ($q in $queries) { $psqlArgs += @('-c', $q) }
    & (Join-Path $pgBin 'psql.exe') @psqlArgs | Tee-Object -FilePath $out
    if ($LASTEXITCODE -ne 0) { throw "psql verify failed with exit $LASTEXITCODE." }
    Write-Output "Verification written to $out"
}

switch ($Action) {
    'Check' { Test-ClusterConfig }
    'Start' {
        Test-ClusterConfig
        New-Item -ItemType Directory -Force $pgLogs | Out-Null
        Invoke-Pg 'pg_ctl.exe' @('start', '-D', $pgData, '-w', '-l', (Join-Path $pgLogs 'pg_ctl.log'))
    }
    'Stop' { Invoke-Pg 'pg_ctl.exe' @('stop', '-D', $pgData, '-m', 'fast', '-w') }
    'Status' { & (Join-Path $pgBin 'pg_ctl.exe') status -D $pgData }
    'Verify' { Invoke-Verify }
}
