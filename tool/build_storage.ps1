param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Prepare', 'Cleanup', 'Status')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$activeLink = Join-Path $projectRoot 'build'
$inactiveRoot = Join-Path $env:LOCALAPPDATA 'DLU-LMS\WorkspaceLinks'
$inactiveLink = Join-Path $inactiveRoot 'DoAnTotNghiep-build'
$expectedTarget = 'D:\DLU-LMS\Build\DoAnTotNghiep'
$stateRoot = 'D:\DLU-LMS\State'
$oneDriveState = Join-Path $stateRoot 'onedrive-build-session.txt'

function Get-OneDriveExecutable {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\OneDrive.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft OneDrive\OneDrive.exe')
    )

    if (${env:ProgramFiles(x86)}) {
        $candidates += Join-Path ${env:ProgramFiles(x86)} 'Microsoft OneDrive\OneDrive.exe'
    }

    return $candidates |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}

function Assert-ExpectedBuildLink([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    $isReparsePoint = [bool](
        $item.Attributes -band [IO.FileAttributes]::ReparsePoint
    )
    $target = [string]$item.Target

    if (-not $isReparsePoint -or $item.LinkType -ne 'Junction') {
        throw "Refusing to move '$Path' because it is not a junction."
    }

    if (-not $target.Equals(
            $expectedTarget,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Unexpected build junction target '$target'."
    }
}

function Stop-OneDriveForBuild {
    $oneDrive = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null

    if (-not $oneDrive) {
        Set-Content -LiteralPath $oneDriveState -Value 'already-stopped'
        return
    }

    $oneDriveExecutable = Get-OneDriveExecutable
    if (-not $oneDriveExecutable) {
        throw 'OneDrive is running but its executable could not be located.'
    }

    & $oneDriveExecutable /shutdown | Out-Null
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (-not (Get-Process -Name OneDrive -ErrorAction SilentlyContinue)) {
            Set-Content -LiteralPath $oneDriveState -Value 'restart'
            return
        }
        Start-Sleep -Milliseconds 250
    }

    throw 'OneDrive did not stop within 10 seconds.'
}

function Start-OneDriveAfterBuild {
    if (-not (Test-Path -LiteralPath $oneDriveState)) {
        return
    }

    $previousState = (Get-Content -LiteralPath $oneDriveState -Raw).Trim()
    if ($previousState -eq 'restart' -and
        -not (Get-Process -Name OneDrive -ErrorAction SilentlyContinue)) {
        $oneDriveExecutable = Get-OneDriveExecutable
        if (-not $oneDriveExecutable) {
            throw 'OneDrive executable could not be located for restart.'
        }
        Start-Process `
            -FilePath $oneDriveExecutable `
            -ArgumentList '/background' `
            -WindowStyle Hidden | Out-Null
    }

    Remove-Item -LiteralPath $oneDriveState -Force
}

function Prepare-BuildStorage {
    $cFreeGb = (Get-PSDrive -Name C).Free / 1GB
    if ($cFreeGb -lt 15) {
        throw ('STORAGE_BLOCKED: C has {0:N2} GB free.' -f $cFreeGb)
    }

    if (-not (Test-Path -LiteralPath $expectedTarget)) {
        New-Item -ItemType Directory -Force -Path $expectedTarget | Out-Null
    }

    Stop-OneDriveForBuild

    try {
        if ((Test-Path -LiteralPath $activeLink) -and
            (Test-Path -LiteralPath $inactiveLink)) {
            throw 'Both active and inactive build junctions exist.'
        }

        if (Test-Path -LiteralPath $activeLink) {
            Assert-ExpectedBuildLink $activeLink
        }
        elseif (Test-Path -LiteralPath $inactiveLink) {
            Assert-ExpectedBuildLink $inactiveLink
            Move-Item -LiteralPath $inactiveLink -Destination $activeLink
        }
        else {
            New-Item `
                -ItemType Directory `
                -Force `
                -Path $inactiveRoot | Out-Null
            New-Item `
                -ItemType Junction `
                -Path $activeLink `
                -Target $expectedTarget | Out-Null
        }

        Assert-ExpectedBuildLink $activeLink
        Write-Output "External build active: $activeLink -> $expectedTarget"
    }
    catch {
        Start-OneDriveAfterBuild
        throw
    }
}

function Cleanup-BuildStorage {
    if ((Test-Path -LiteralPath $activeLink) -and
        (Test-Path -LiteralPath $inactiveLink)) {
        throw 'Both active and inactive build junctions exist.'
    }

    if (Test-Path -LiteralPath $activeLink) {
        Assert-ExpectedBuildLink $activeLink
        New-Item -ItemType Directory -Force -Path $inactiveRoot | Out-Null
        Move-Item -LiteralPath $activeLink -Destination $inactiveLink
    }

    if (Test-Path -LiteralPath $inactiveLink) {
        Assert-ExpectedBuildLink $inactiveLink
    }

    Start-OneDriveAfterBuild
    Write-Output "External build inactive; OneDrive can sync the source tree."
}

function Show-BuildStorageStatus {
    $active = Test-Path -LiteralPath $activeLink
    $inactive = Test-Path -LiteralPath $inactiveLink
    $oneDriveRunning = [bool](
        Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    )
    [pscustomobject]@{
        ActiveBuildLink = $active
        InactiveBuildLink = $inactive
        BuildTarget = $expectedTarget
        OneDriveRunning = $oneDriveRunning
        CFreeGB = [math]::Round((Get-PSDrive -Name C).Free / 1GB, 2)
        DFreeGB = [math]::Round((Get-PSDrive -Name D).Free / 1GB, 2)
    }
}

switch ($Action) {
    'Prepare' { Prepare-BuildStorage }
    'Cleanup' { Cleanup-BuildStorage }
    'Status' { Show-BuildStorageStatus }
}
