<#
.SYNOPSIS
  Download the OpenSCAD Windows snapshot and lay it out for Tauri resource
  bundling (mirrors download-openscad.sh for macOS).

.DESCRIPTION
  Fetches the OpenSCAD <ver>-x86-64.zip from files.openscad.org/snapshots,
  extracts the top-level folder and copies its contents (openscad.exe + all
  Qt/boost .dll dependencies) into src-tauri/binaries/openscad/. Tauri bundles
  that folder as the `openscad` resource on Windows (see tauri.windows.conf.json).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File apps/ui/src-tauri/scripts/download-openscad-windows.ps1
#>
param(
    [string]$Version = "2026.09.12"
)

$ErrorActionPreference = "Stop"

$Root   = Split-Path -Parent $PSScriptRoot   # -> src-tauri
$BinDir = Join-Path $Root "binaries"
$Dest   = Join-Path $BinDir "openscad"
$Exe    = Join-Path $Dest "openscad.exe"

# Skip if already laid out.
if (Test-Path $Exe) {
    Write-Host "openscad.exe already present at $Dest"
    exit 0
}

$Url = "https://files.openscad.org/snapshots/OpenSCAD-${Version}-x86-64.zip"
$Zip = Join-Path $env:TEMP "openscad-${Version}.zip"
$Extract = Join-Path $env:TEMP "openscad-extract-${Version}"

Write-Host "Downloading $Url"
Invoke-WebRequest -Uri $Url -OutFile $Zip

if (Test-Path $Extract) { Remove-Item -Recurse -Force $Extract }
Expand-Archive -Path $Zip -DestinationPath $Extract

$TopDir = Get-ChildItem -Path $Extract -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "openscad.exe")
} | Select-Object -First 1

if (-not $TopDir) {
    throw "No folder containing openscad.exe found in $Zip"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Recurse -Force (Join-Path $TopDir.FullName "*") $Dest

if (-not (Test-Path $Exe)) {
    throw "openscad.exe not found after extraction into $Dest"
}

Remove-Item -Recurse -Force $Extract
Write-Host "OpenSCAD ${Version} installed at $Dest"