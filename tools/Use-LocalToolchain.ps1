$ErrorActionPreference = 'Stop'
$toolRoot = 'D:\DLU-LMS\Toolchains'
$jdkCandidates = @(Get-ChildItem -LiteralPath (Join-Path $toolRoot 'group-jdk21') -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\java.exe') })
$mavenCandidates = @(Get-ChildItem -LiteralPath $toolRoot -Directory -Filter 'apache-maven-3.9.*' | Sort-Object Name -Descending | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\mvn.cmd') })
if ($jdkCandidates.Count -ne 1 -or $mavenCandidates.Count -lt 1) { throw 'Run tools/Install-PortableBuildTools.ps1 first.' }
$env:JAVA_HOME = $jdkCandidates[0].FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:GRADLE_USER_HOME = 'D:\DLU-LMS\Caches\Gradle'
$env:PUB_CACHE = 'D:\DLU-LMS\Caches\Pub'
$env:TEMP = 'D:\DLU-LMS\Temp'
$env:TMP = $env:TEMP
$env:ANDROID_HOME = 'D:\DLU-LMS\Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$groupMaven = Join-Path $mavenCandidates[0].FullName 'bin\mvn.cmd'
$groupFlutter = 'D:\DLU-LMS\Toolchains\flutter\bin\flutter.bat'
$groupDart = 'D:\DLU-LMS\Toolchains\flutter\bin\dart.bat'
$groupMavenCache = '-Dmaven.repo.local=D:\DLU-LMS\Caches\Maven'
# Dot-source in a task process only. This never sets machine/user environment values.
