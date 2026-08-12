$ErrorActionPreference = 'Stop'
$storageScript = Join-Path $PSScriptRoot 'build_storage.ps1'
$flutterExecutable = 'D:\DLU-LMS\Toolchains\flutter\bin\flutter.bat'
$flutterArguments = @($args)
$exitCode = 1

if ($flutterArguments.Count -eq 0) {
    throw 'Pass a Flutter command, for example: doctor -v or analyze.'
}

try {
    & $storageScript -Action Prepare

    $env:JAVA_HOME = 'D:\DLU-LMS\Toolchains\jdk-17'
    $env:ANDROID_HOME = 'D:\DLU-LMS\Android\Sdk'
    $env:ANDROID_SDK_ROOT = 'D:\DLU-LMS\Android\Sdk'
    $env:ANDROID_AVD_HOME = 'D:\DLU-LMS\Android\AVD'
    $env:ANDROID_EMULATOR_HOME = 'D:\DLU-LMS\Android\EmulatorHome'
    $env:GRADLE_USER_HOME = 'D:\DLU-LMS\Caches\Gradle'
    $env:PUB_CACHE = 'D:\DLU-LMS\Caches\Pub'

    & $flutterExecutable @FlutterArguments
    $exitCode = $LASTEXITCODE
}
finally {
    & $storageScript -Action Cleanup
}

exit $exitCode
