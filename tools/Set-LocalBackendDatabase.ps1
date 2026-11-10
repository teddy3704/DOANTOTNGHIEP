[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('dev', 'demo')][string]$Target)
$ErrorActionPreference = 'Stop'
# Switches DB_URL in the git-ignored .local\backend.json between the untouched dev copy and the
# date-shifted demo copy (DOI_NGAY_DEMO). Other values are kept and never printed. Restart the backend after.
$path = Join-Path (Split-Path $PSScriptRoot) '.local\backend.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'LOCAL_DATABASE_CONFIGURATION_REQUIRED (run New-LocalBackendConfig.ps1).' }
$config = [IO.File]::ReadAllText($path) | ConvertFrom-Json
$config.DB_URL = "jdbc:postgresql://127.0.0.1:55432/lms_mobile_group_$Target"
# WriteAllText keeps the existing file and therefore its restricted ACL. -Depth 10: the PORTAL block is nested.
[IO.File]::WriteAllText($path, ($config | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
$config = $null
Write-Output "Backend database set to lms_mobile_group_$Target (other values unchanged, not shown). Restart the backend."
