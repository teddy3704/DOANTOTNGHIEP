[CmdletBinding()]
param([switch]$Package)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Use-LocalToolchain.ps1')
$backend = Join-Path (Split-Path $PSScriptRoot) 'backend'
$target = if ($Package) { 'package' } else { 'test' }
Push-Location $backend
try {
    & $groupMaven $groupMavenCache -B -ntp clean $target
    if ($LASTEXITCODE -ne 0) { throw 'Backend quality gate failed.' }
} finally { Pop-Location }
