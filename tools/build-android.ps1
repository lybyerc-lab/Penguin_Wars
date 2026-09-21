param([switch]$WorkspaceToolchain)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$previousAppData = $env:APPDATA
$previousJavaHome = $env:JAVA_HOME
try {
    if ($WorkspaceToolchain) {
        $workspaceRoot = Split-Path $projectRoot -Parent
        $toolRoot = Join-Path $workspaceRoot '.android-tools'
        $jdk = Get-ChildItem -LiteralPath $toolRoot -Directory -Filter 'jdk-17*' | Select-Object -First 1
        if (-not $jdk) { throw 'Workspace Java 17 installation not found.' }
        $env:JAVA_HOME = $jdk.FullName
        $env:APPDATA = Join-Path $workspaceRoot '.runtime'
        if (-not (Test-Path (Join-Path $env:APPDATA 'Godot/editor_settings-4.7.tres'))) {
            throw 'Workspace Godot Android settings are not configured.'
        }
    }
    New-Item -ItemType Directory -Force (Join-Path $projectRoot 'builds') | Out-Null
    & godot --headless --path $projectRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    & godot --headless --path $projectRoot --export-debug Android
    if ($LASTEXITCODE -ne 0) { throw 'Android export failed.' }
    Get-Item (Join-Path $projectRoot 'builds/penguin-wars-debug.apk') | Select-Object FullName, Length, LastWriteTime
} finally {
    $env:APPDATA = $previousAppData
    $env:JAVA_HOME = $previousJavaHome
}
