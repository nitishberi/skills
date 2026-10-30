#Requires -Version 5.1
<#
.SYNOPSIS
  Bump revision, publish WinUI self-contained build, and build Setup-rN.exe.

.DESCRIPTION
  Run on Windows with .NET 8 SDK + Windows App SDK workload.
  Outputs:
    dist/publish/                  unpacked app
    dist/SolidCraftAgent-rN.zip    portable zip
    dist/SolidCraftAgent-Setup-rN.exe  Inno Setup installer (if ISCC is available)

  Pass -NoBump to rebuild the current revision without incrementing.
#>
[CmdletBinding()]
param(
    [switch]$NoBump,
    [switch]$SkipInstaller,
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$VersionPath = Join-Path $Root "version.json"
$Dist = Join-Path $Root "dist"
$PublishDir = Join-Path $Dist "publish"
$AppProj = Join-Path $Root "src\SolidCraftAgent.App\SolidCraftAgent.App.csproj"
$Iss = Join-Path $Root "packaging\SolidCraftAgent.iss"

if (-not (Test-Path $VersionPath)) { throw "Missing $VersionPath" }
if (-not (Test-Path $AppProj)) { throw "Missing $AppProj" }

$version = Get-Content $VersionPath -Raw | ConvertFrom-Json
if (-not $NoBump) {
    $version.revision = [int]$version.revision + 1
    $version | ConvertTo-Json -Depth 5 | Set-Content -Path $VersionPath -Encoding utf8
    Write-Host "Bumped revision to r$($version.revision)"
} else {
    Write-Host "Keeping revision r$($version.revision)"
}

$ver = "$($version.major).$($version.minor).$($version.revision)"
$rev = [string]$version.revision
$zipName = "SolidCraftAgent-r$rev-win-x64.zip"
$setupName = "SolidCraftAgent-Setup-r$rev.exe"

if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Path $PublishDir | Out-Null

Write-Host "Publishing SolidCraft Agent $ver (r$rev)..."
dotnet publish $AppProj `
    -c $Configuration `
    -r win-x64 `
    --self-contained true `
    -p:Platform=x64 `
    -p:PublishDir=$PublishDir `
    -p:WindowsPackageType=None `
    -p:WindowsAppSDKSelfContained=true `
    -p:Version=$ver `
    -p:AssemblyVersion="$ver.0" `
    -p:FileVersion="$ver.0" `
    -p:InformationalVersion="$ver+r$rev"

if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed ($LASTEXITCODE)" }

# Prefer SolidCraftAgent.exe; fall back to project assembly name.
$mainExe = Join-Path $PublishDir "SolidCraftAgent.exe"
if (-not (Test-Path $mainExe)) {
    $fallback = Join-Path $PublishDir "SolidCraftAgent.App.exe"
    if (Test-Path $fallback) {
        Copy-Item $fallback $mainExe
    }
}

$zipPath = Join-Path $Dist $zipName
Compress-Archive -Path (Join-Path $PublishDir "*") -DestinationPath $zipPath -Force
Write-Host "Wrote $zipPath"

$setupPath = $null
if (-not $SkipInstaller) {
    $iscc = Get-Command iscc -ErrorAction SilentlyContinue
    if (-not $iscc) {
        $defaultIscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
        if (Test-Path $defaultIscc) { $iscc = @{ Source = $defaultIscc } }
    }
    if ($iscc) {
        $isccPath = if ($iscc.Source) { $iscc.Source } else { $iscc.Path }
        & $isccPath $Iss `
            "/DAppVersion=$ver" `
            "/DAppRevision=$rev" `
            "/DSourceDir=$PublishDir" `
            "/DOutDir=$Dist"
        if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed ($LASTEXITCODE)" }
        $setupPath = Join-Path $Dist $setupName
        if (-not (Test-Path $setupPath)) {
            throw "Expected installer not found: $setupPath"
        }
        Write-Host "Wrote $setupPath"
    } else {
        Write-Warning "ISCC (Inno Setup) not found. Zip only. Install Inno Setup 6 or run CI."
    }
}

Write-Output @{
    Version = $ver
    Revision = $rev
    Zip = $zipPath
    Setup = $setupPath
} | ConvertTo-Json
