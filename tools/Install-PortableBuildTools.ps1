[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$toolRoot = 'D:\DLU-LMS\Toolchains'
$downloadRoot = 'D:\DLU-LMS\Artifacts\GroupToolDownloads'

function Assert-Storage {
    $freeC = (Get-PSDrive C).Free / 1GB
    $freeD = (Get-PSDrive D).Free / 1GB
    Write-Output ('Storage C={0:N1}GB D={1:N1}GB free' -f $freeC, $freeD)
    if ($freeC -lt 15 -or $freeD -lt 3) { throw 'STORAGE_BLOCKED' }
}
function Assert-ArchivePaths([string]$Archive) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -match '(^[/\\]|^[A-Za-z]:|(^|[/\\])\.\.([/\\]|$))') {
                throw 'Unsafe archive entry'
            }
        }
    } finally { $zip.Dispose() }
}

Assert-Storage
New-Item -ItemType Directory -Force -Path $toolRoot, $downloadRoot | Out-Null
$jdkTarget = Join-Path $toolRoot 'group-jdk21'
if (-not (Test-Path -LiteralPath $jdkTarget)) {
    $assets = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
    $package = @($assets)[0].binary.package
    if ($package.link -notlike 'https://github.com/adoptium/temurin21-binaries/*') { throw 'Unexpected JDK origin' }
    $archive = Join-Path $downloadRoot 'temurin21-windows-x64.zip'
    Assert-Storage
    Invoke-WebRequest -Uri $package.link -OutFile $archive
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $package.checksum) { throw 'JDK checksum mismatch' }
    Assert-ArchivePaths $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $jdkTarget
    Assert-Storage
}
$jdkHome = @(Get-ChildItem -LiteralPath $jdkTarget -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\javac.exe') })
if ($jdkHome.Count -ne 1) { throw 'JDK installation is incomplete or ambiguous' }

[xml]$metadata = (Invoke-WebRequest 'https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml').Content
$version = @($metadata.metadata.versioning.versions.version | Where-Object { $_ -match '^3\.9\.[0-9]+$' } | Sort-Object { [version]$_ })[-1]
$mavenTarget = Join-Path $toolRoot "apache-maven-$version"
if (-not (Test-Path -LiteralPath (Join-Path $mavenTarget 'bin\mvn.cmd'))) {
    $uri = "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$version/apache-maven-$version-bin.zip"
    $archive = Join-Path $downloadRoot "apache-maven-$version-bin.zip"
    Assert-Storage
    Invoke-WebRequest -Uri $uri -OutFile $archive
    $expected = ((Invoke-WebRequest -Uri "$uri.sha512").Content.Trim() -split '\s+')[0]
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash -ne $expected) { throw 'Maven checksum mismatch' }
    Assert-ArchivePaths $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $toolRoot
    Assert-Storage
}
$env:JAVA_HOME = $jdkHome[0].FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
& (Join-Path $env:JAVA_HOME 'bin\java.exe') -version
& (Join-Path $mavenTarget 'bin\mvn.cmd') -version
if ($LASTEXITCODE -ne 0) { throw 'Maven toolchain verification failed' }
Write-Output 'Portable tools ready. Global JAVA_HOME and PATH were not changed.'
