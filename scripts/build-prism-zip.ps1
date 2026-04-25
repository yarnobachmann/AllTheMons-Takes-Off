$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Read-DeploymentConfig {
    $configPath = ".\deployment.json"
    if (-not (Test-Path $configPath)) {
        $configPath = ".\deployment.example.json"
    }
    if (-not (Test-Path $configPath)) {
        throw "deployment.example.json is missing."
    }
    return Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
}

function Get-PackVersion {
    $packText = Get-Content -Raw -LiteralPath ".\pack.toml"
    if ($packText -match '(?m)^version\s*=\s*"([^"]+)"') {
        return $Matches[1]
    }
    return (Get-Date -Format "yyyyMMdd-HHmm")
}

function Set-Utf8NoBom {
    param([string]$Path, [string]$Value)
    $Value = $Value -replace "`r`n", "`n"
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

& "$PSScriptRoot\refresh-pack.ps1"

$config = Read-DeploymentConfig
$instanceName = $config.instanceName
$minecraftVersion = $config.minecraftVersion
$loaderVersion = $config.loaderVersion
$packUrl = $config.packUrl
$memoryMb = $config.memoryMb
$iconFile = $config.iconFile
$iconKey = $config.iconKey

if ([string]::IsNullOrWhiteSpace($instanceName)) { throw "instanceName is missing from deployment config." }
if ([string]::IsNullOrWhiteSpace($minecraftVersion)) { throw "minecraftVersion is missing from deployment config." }
if ([string]::IsNullOrWhiteSpace($loaderVersion)) { throw "loaderVersion is missing from deployment config." }
if ([string]::IsNullOrWhiteSpace($packUrl)) { throw "packUrl is missing from deployment config." }
if (-not $memoryMb) { $memoryMb = 8192 }
if ([string]::IsNullOrWhiteSpace($iconKey)) { $iconKey = "all-the-mons-takes-off" }

$dist = Join-Path $Root "dist"
$stagingRoot = Join-Path $dist "prism-staging"
$minecraftRoot = Join-Path $stagingRoot "minecraft"
$bootstrapPath = Join-Path $minecraftRoot "packwiz-installer-bootstrap.jar"

if (Test-Path $stagingRoot) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $minecraftRoot | Out-Null

$instanceCfg = @"
name=$instanceName
InstanceType=OneSix
MCLaunchMethod=LauncherPart
iconKey=$iconKey
OverrideCommands=true
PreLaunchCommand=`"`$INST_JAVA`" -jar packwiz-installer-bootstrap.jar $packUrl
OverrideMemory=true
MinMemAlloc=$memoryMb
MaxMemAlloc=$memoryMb
"@
Set-Utf8NoBom -Path (Join-Path $stagingRoot "instance.cfg") -Value $instanceCfg

if (-not [string]::IsNullOrWhiteSpace($iconFile)) {
    $iconPath = Join-Path $Root $iconFile
    if (Test-Path -LiteralPath $iconPath -PathType Leaf) {
        Copy-Item -LiteralPath $iconPath -Destination (Join-Path $stagingRoot "$iconKey.png") -Force
    } else {
        Write-Warning "Configured icon file was not found: $iconFile"
    }
}

$mmcPack = [ordered]@{
    components = @(
        [ordered]@{
            cachedName = "Minecraft"
            important = $true
            uid = "net.minecraft"
            version = $minecraftVersion
        },
        [ordered]@{
            cachedName = "NeoForge"
            uid = "net.neoforged"
            version = $loaderVersion
        }
    )
    formatVersion = 1
}
Set-Utf8NoBom -Path (Join-Path $stagingRoot "mmc-pack.json") -Value ($mmcPack | ConvertTo-Json -Depth 5)

$localBootstrap = Join-Path $Root "packwiz-installer-bootstrap.jar"
if (Test-Path -LiteralPath $localBootstrap -PathType Leaf) {
    Copy-Item -LiteralPath $localBootstrap -Destination $bootstrapPath -Force
} else {
    $bootstrapUrl = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"
    Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapPath
}

$safeName = ($instanceName -replace '[^A-Za-z0-9._-]+', '-').Trim("-")
$version = Get-PackVersion
$zipPath = Join-Path $dist "$safeName-$version-prism.zip"
if (Test-Path $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

$stagingFiles = Get-ChildItem -LiteralPath $stagingRoot -Force
Compress-Archive -LiteralPath $stagingFiles.FullName -DestinationPath $zipPath -Force
$rootZipPath = Join-Path $Root "$safeName-$version-prism.zip"
Copy-Item -LiteralPath $zipPath -Destination $rootZipPath -Force
Remove-Item -LiteralPath $stagingRoot -Recurse -Force
Write-Host "Created $zipPath"
Write-Host "Copied $rootZipPath"
