[CmdletBinding()]
param(
    [switch]$Online,
    [string]$EnvironmentPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "manifest.json"
$expectedServerUrl = "https://mcp.workfront.adobe.com/mcp/v1/workfront"

$manifestArguments = @{}
if (-not [string]::IsNullOrWhiteSpace($EnvironmentPath)) {
    $manifestArguments.EnvironmentPath = $EnvironmentPath
}
& (Join-Path $PSScriptRoot "New-Manifest.ps1") @manifestArguments

function Assert-Condition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Test-PngDimensions {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [int]$Width,
        [Parameter(Mandatory)]
        [int]$Height
    )

    Add-Type -AssemblyName System.Drawing
    $image = [System.Drawing.Image]::FromFile($Path)
    try {
        Assert-Condition ($image.RawFormat.Guid -eq [System.Drawing.Imaging.ImageFormat]::Png.Guid) "$Path must be a PNG file."
        Assert-Condition ($image.Width -eq $Width -and $image.Height -eq $Height) "$Path must be ${Width}x${Height}px; found $($image.Width)x$($image.Height)."
    }
    finally {
        $image.Dispose()
    }
}

Assert-Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) "manifest.json is missing."

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}
catch {
    throw "manifest.json is not valid JSON: $($_.Exception.Message)"
}

Assert-Condition ($manifest.'$schema' -eq "https://developer.microsoft.com/json-schemas/teams/v1.29/MicrosoftTeams.schema.json") "The manifest must use the Microsoft 365 v1.29 schema."
Assert-Condition ($manifest.manifestVersion -eq "1.29") "manifestVersion must be 1.29."
Assert-Condition (@($manifest.agentConnectors).Count -eq 1) "Exactly one Workfront connector is expected."
Assert-Condition (@($manifest.agentSkills).Count -eq 1) "Exactly one Workfront skill is expected."

$connector = @($manifest.agentConnectors)[0]
$remoteServer = $connector.toolSource.remoteMcpServer
Assert-Condition ($remoteServer.mcpServerUrl -eq $expectedServerUrl) "The connector must target Adobe's documented Workfront MCP endpoint."
Assert-Condition (-not ($remoteServer.PSObject.Properties.Name -contains "authorization")) "Workfront uses OAuth dynamic discovery; omit authorization so Cowork can perform dynamic client registration."

$skillFolder = $manifest.agentSkills[0].folder -replace "^\./", ""
$skillPath = Join-Path (Join-Path $root $skillFolder) "SKILL.md"
Assert-Condition (Test-Path -LiteralPath $skillPath -PathType Leaf) "The declared skill is missing: $skillPath"
$skill = Get-Content -LiteralPath $skillPath -Raw
Assert-Condition ($skill -match "(?ms)\A---\s*\r?\nname:\s*workfront-operations\s*\r?\ndescription:\s*.+?\r?\n---") "SKILL.md must contain valid name and description frontmatter."

Test-PngDimensions -Path (Join-Path $root $manifest.icons.color) -Width 192 -Height 192
Test-PngDimensions -Path (Join-Path $root $manifest.icons.outline) -Width 32 -Height 32

if ($Online) {
    $resourceMetadataUri = "https://mcp.workfront.adobe.com/.well-known/oauth-protected-resource/mcp/v1/workfront"
    $authorizationMetadataUri = "https://mcp.workfront.adobe.com/.well-known/oauth-authorization-server"

    $resourceMetadata = Invoke-RestMethod -Uri $resourceMetadataUri
    Assert-Condition ($resourceMetadata.resource -eq $expectedServerUrl) "Adobe's protected-resource metadata does not identify the configured MCP endpoint."
    Assert-Condition (@($resourceMetadata.authorization_servers).Count -gt 0) "Adobe's protected-resource metadata does not advertise an authorization server."

    $authorizationMetadata = Invoke-RestMethod -Uri $authorizationMetadataUri
    Assert-Condition (-not [string]::IsNullOrWhiteSpace($authorizationMetadata.registration_endpoint)) "Adobe's authorization server does not advertise dynamic client registration."
    Assert-Condition (@($authorizationMetadata.grant_types_supported) -contains "authorization_code") "Adobe's authorization server does not advertise the authorization-code grant."
    Assert-Condition (@($authorizationMetadata.code_challenge_methods_supported) -contains "S256") "Adobe's authorization server does not advertise PKCE S256."
}

Write-Host "Plugin validation passed$(if ($Online) { ' (including Adobe OAuth discovery)' })." -ForegroundColor Green
