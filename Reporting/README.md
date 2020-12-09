# Compare-FileShareSPOitemCount.ps1
The script compares files and folders from an on-premises fileshare with a SharePoint Online or OneDrive for Business site after a migration.
It's setup with a number of functions that are called for a specific source and destination. For use in a migration scenario, the functions would be called in loop for e.g. a CSV-list with items containing source and destination addresses.

## Dependencies
This script uses cmdlets from the [PnP PowerShell module](https://github.com/pnp/PnP-PowerShell)
## Getting Started
1. If not yet available, download and install the latest version of the SharePointPnPPowerShellOnline module.
2. Ensure you have an Microsoft 365 account which has access to the destination site to check
3. Be sure to run the script with a Windows-account that has access to the source fileshare
4. Set the variables in the script:
   * $sourceFolder = '{UNCpath fileshare}'
   * $tenantName = '{tenantName}'
   * $dstSite = '{siteURL}'
   * $dstList = '{ListName}'

## Points of attention
Consider other means of authentication. e.g. using app-based authentication provisioned through the [Initialize-PnPPowerShellAuthentication](https://docs.microsoft.com/en-us/powershell/module/sharepoint-pnp/initialize-pnppowershellauthentication) cmdlet. This would be especially useful when comparing large amounts of sources and desintations which might trigger throttling.

Implementing this in the script would require a change to the connection logic as follows:

`Connect-PnPOnline -Url "https://$tenantName-admin.sharepoint.com" -ClientId $clientId -Thumbprint $thumbPrint -Tenant "$tenantName.onmicrosoft.com"`
