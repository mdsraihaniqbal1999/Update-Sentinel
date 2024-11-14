# Update-Sentinel

# Update-Sentinel

A PowerShell script for automatically updating Microsoft Sentinel solutions in your Azure workspace.

## Description

This script automates the process of updating installed Microsoft Sentinel solutions to their latest available versions. It uses Azure REST APIs to identify installed solutions, compare their versions with available updates, and deploy newer versions when available.

## Prerequisites

- PowerShell 5.1 or higher
- Azure subscription with appropriate permissions
- Service Principal with necessary permissions to:
  - Access the Azure Sentinel workspace
  - Deploy ARM templates
  - Modify resource groups

## Required PowerShell Modules

The script will automatically install the following modules if they're not present:
- Az
- Az.Resources
- Az.SecurityInsights (version 2.0.0-preview)
- Az.OperationalInsights

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| WorkspaceName | String | Yes | Name of the Azure Sentinel workspace |
| SubscriptionId | String | Yes | Azure subscription ID |
| TeamName | String | Yes | Name of the team |
| TenantId | String | Yes | Azure AD tenant ID |
| ClientId | String | Yes | Service Principal application (client) ID |
| ClientSecret | String | Yes | Service Principal secret |
| ResourceGroupName | String | Yes | Name of the resource group containing the workspace |

## Usage

```powershell
.\Update-Sentinel.ps1 `
    -WorkspaceName "your-workspace-name" `
    -SubscriptionId "your-subscription-id" `
    -TeamName "your-team-name" `
    -TenantId "your-tenant-id" `
    -ClientId "your-client-id" `
    -ClientSecret "your-client-secret" `
    -ResourceGroupName "your-resource-group-name"
```

## Features

- Authenticates using Service Principal credentials
- Retrieves list of installed Sentinel solutions
- Compares installed versions with available updates
- Updates solutions to their latest versions
- Handles up to 10 solutions per execution
- Provides progress feedback during execution

## Limitations

- Updates are limited to 10 solutions per run to prevent timeout issues
- Requires preview version of Az.SecurityInsights module
- Some post-deployment instructions may be stripped due to character limitations

## Error Handling

The script includes basic error handling for deployment failures. All errors are displayed in the console output for troubleshooting purposes.

## Contributing

Feel free to submit issues and enhancement requests. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)

## Author

[Your Name/Organization]

## Disclaimer

This script is provided as-is with no warranties. Always test in a non-production environment first.
