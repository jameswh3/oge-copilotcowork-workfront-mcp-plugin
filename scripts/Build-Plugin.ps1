[CmdletBinding()]
param(
    [string]$OutputPath = "dist\workfront-cowork-plugin.zip",
    [switch]$Online,
    [string]$EnvironmentPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$validateArguments = @{}
if ($Online) {
    $validateArguments.Online = $true
}
if (-not [string]::IsNullOrWhiteSpace($EnvironmentPath)) {
    $validateArguments.EnvironmentPath = $EnvironmentPath
}

& (Join-Path $PSScriptRoot "Validate-Plugin.ps1") @validateArguments

$resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
}
else {
    Join-Path $root $OutputPath
}

$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

if (Test-Path -LiteralPath $resolvedOutputPath) {
    Remove-Item -LiteralPath $resolvedOutputPath -Force
}

$packageContents = @(
    (Join-Path $root "manifest.json"),
    (Join-Path $root "color.png"),
    (Join-Path $root "outline.png"),
    (Join-Path $root "skills")
)

Compress-Archive -LiteralPath $packageContents -DestinationPath $resolvedOutputPath -CompressionLevel Optimal
Write-Host "Created $resolvedOutputPath" -ForegroundColor Green
