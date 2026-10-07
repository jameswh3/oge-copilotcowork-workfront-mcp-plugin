# Adobe Workfront connector for Copilot Cowork

This repository contains a Microsoft 365 app package that connects Copilot Cowork to Adobe's hosted Workfront MCP server:

`https://mcp.workfront.adobe.com/mcp/v1/workfront`

The package uses Microsoft 365 manifest version 1.29 and OAuth dynamic client registration. It contains no client secret, API key, Workfront hostname, tenant ID, or user credential. Publisher identity and app registration values are supplied locally through `.env`; generated manifests and packages are excluded from source control.

## Authentication model

Cowork discovers Adobe's OAuth metadata from the MCP endpoint and dynamically registers an OAuth client. The user then signs in through Adobe Identity Management System (IMS), selects an Adobe profile and Workfront instance, and grants the resulting connection access under that user's existing Workfront permissions.

For an organization federated with Microsoft Entra ID, Adobe IMS redirects the user through the organization's Entra SSO flow. This connector does not authenticate directly against Entra and does not require an Entra app registration.

## Prerequisites

### Workfront administrator

1. Confirm that the Workfront instance is enabled on Adobe IMS.
2. In **Setup > System > Preferences**, enable **Read-only MCP tools**.
3. Enable **Write MCP tools** only if users should create, update, or delete Workfront data.
4. Confirm that intended users have the required Workfront access levels and object permissions.
5. If Adobe rejects the OAuth callback, add the exact callback URL supplied by the Microsoft connection flow under **System Preferences > MCP preferences > Authorized redirect URLs**. Do not use a wildcard.

### Microsoft 365 administrator

1. Confirm that Copilot Cowork and custom plugin upload are enabled for the test user.
2. Allow the plugin for the intended user or test group.
3. For tenant rollout, upload the package in **Microsoft 365 admin center > Manage apps > Upload custom app**.

### Entra administrator

Ensure the test user is assigned to the enterprise application used by the organization's Adobe federated directory and can complete the configured Conditional Access and multifactor authentication policies.

## Build and validate

Create the local environment file and assign a unique Microsoft 365 app ID:

```powershell
Copy-Item .env.example .env
(Get-Content .env) -replace `
  '00000000-0000-4000-8000-000000000000', `
  ([guid]::NewGuid().ToString()) |
  Set-Content .env
```

Update the developer name, URLs, and display names in `.env`, then run:

```powershell
.\scripts\Validate-Plugin.ps1 -Online
.\scripts\Build-Plugin.ps1 -Online
```

The scripts render the untracked `manifest.json` from `manifest.template.json` and `.env`. To use a different environment file, pass `-EnvironmentPath .env.test` to either script.

`-Online` verifies Adobe's protected-resource and authorization-server metadata, including its dynamic-registration endpoint, authorization-code grant, and PKCE S256 support.

The build creates:

```text
dist\workfront-cowork-plugin.zip
```

The ZIP contains `manifest.json`, both required PNG icons, and the Workfront skill at its package root.

## Test in Cowork

1. Open **Cowork > Customize > Plugins**.
2. Select **Add plugin** and upload `dist\workfront-cowork-plugin.zip`.
3. Choose **Only you** in the sharing dialog.
4. Connect **Adobe Workfront**.
5. Complete Adobe sign-in and the organization's Entra SSO challenge.
6. Select the intended Adobe profile and Workfront instance.
7. Start with read-only checks:
   - `What Workfront actions can you take?`
   - `Find my active Workfront tasks due this week.`
   - `Summarize the status of project <project name>.`
8. If write tools are enabled, test a low-risk change in a Preview instance before Production.

To switch between Preview and Production, disconnect the Workfront connector and reconnect it, selecting the other instance during Adobe sign-in.

## Production checklist

- Set the publishing organization's app ID, developer name, website, privacy statement, terms, and display names in `.env`.
- Replace the placeholder icons with approved brand assets.
- Review the skill's mutation-confirmation policy with the Workfront administrator.
- Validate and test the final package again after any manifest or asset change.
- Use a dedicated test group before tenant-wide deployment.

## References

- [Configure the Adobe Workfront MCP server](https://experienceleague.adobe.com/en/docs/workfront/using/basics/workfront-mcp-server/configure-workfront-mcp-server)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/en-us/microsoft-365/copilot/cowork/cowork-plugin-development)
- [Manage plugins for Copilot Cowork](https://learn.microsoft.com/en-us/microsoft-365/copilot/cowork/cowork-manage-plugins)
- [Register MCP servers as agent connectors](https://learn.microsoft.com/en-us/microsoftteams/platform/m365-apps/agent-connectors)
