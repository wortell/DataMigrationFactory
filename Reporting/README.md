# Compare-FileShareSPOitemCount.ps1
The script compares files and folders from an on-premises fileshare with a SharePoint Online or OneDrive for Business site after a migration
## Dependencies
This script uses cmdlets from the [PnP PowerShell module](https://github.com/pnp/PnP-PowerShell)
## Getting Started
1. If not yet available, download and install the latest version of the SharePointPnPPowerShellOnline module.
2. Ensure you have an Microsoft 365 account which has access to the site to check
3. Set the variables in the script:
 * $sourceFolder = '{UNCpath fileshare}'
 * $tenantName = '{tenantName}'
 * $dstSite = '{siteURL}'
 * $dstList = '{ListName}'
