[CmdletBinding()]
param(
    [string]$EnvironmentPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($EnvironmentPath)) {
    $EnvironmentPath = Join-Path $root ".env"
}
elseif (-not [System.IO.Path]::IsPathRooted($EnvironmentPath)) {
    $EnvironmentPath = Join-Path $root $EnvironmentPath
}

$templatePath = Join-Path $root "manifest.template.json"
$manifestPath = Join-Path $root "manifest.json"

if (-not (Test-Path -LiteralPath $EnvironmentPath -PathType Leaf)) {
    throw "Environment file not found: $EnvironmentPath. Copy .env.example to .env and set your organization values."
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $EnvironmentPath) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
        continue
    }

    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[0])) {
        throw "Invalid environment entry in ${EnvironmentPath}: $line"
    }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    $values[$key] = $value
}

$requiredKeys = @(
    "APP_ID",
    "DEVELOPER_NAME",
    "DEVELOPER_WEBSITE_URL",
    "DEVELOPER_PRIVACY_URL",
    "DEVELOPER_TERMS_URL",
    "APP_SHORT_NAME",
    "APP_FULL_NAME"
)

foreach ($key in $requiredKeys) {
    if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
        throw "Required value $key is missing from $EnvironmentPath."
    }
}

$appId = [guid]::Empty
if (-not [guid]::TryParse($values.APP_ID, [ref]$appId) -or $appId -eq [guid]::Empty) {
    throw "APP_ID must be a non-empty GUID."
}

$manifest = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
$manifest.id = $values.APP_ID
$manifest.developer.name = $values.DEVELOPER_NAME
$manifest.developer.websiteUrl = $values.DEVELOPER_WEBSITE_URL
$manifest.developer.privacyUrl = $values.DEVELOPER_PRIVACY_URL
$manifest.developer.termsOfUseUrl = $values.DEVELOPER_TERMS_URL
$manifest.name.short = $values.APP_SHORT_NAME
$manifest.name.full = $values.APP_FULL_NAME

$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Host "Generated $manifestPath from $EnvironmentPath." -ForegroundColor Green
