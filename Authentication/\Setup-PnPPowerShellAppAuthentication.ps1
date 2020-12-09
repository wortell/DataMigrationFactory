#Register an Azure AD app for certificate based authentication to SharePoint Online
#Version: 1.0
#Author: Andries den Haan
#Organisation: Wortell

#Set variables
$applicationName = '{ApplicationName}'
$tenantName = '{tenantName}'
$outputPath = 'C:\temp'

#Register the Azure AD App - Self-signed cert only for development or demo-purposes
$App = Initialize-PnPPowerShellAuthentication -ApplicationName $applicationName -Tenant "$tenantName.onmicrosoft.com" -OutPath $outputPath -CommonName $applicationName

#Give permission consent in Azure AD...wait for 60 seconds

#Install the certificate (including the private key) in the personal store
$cert = Import-PfxCertificate -FilePath "$outputPath\$applicationName.pfx" -CertStoreLocation 'cert:\localMachine\my'

#Get the Azure Client ID and Cert Thumbnail
$clientId = $App.AzureAppId
$thumbPrint = $cert.Thumbprint

#Connect to SharePoint Online using the Azure AD App
Connect-PnPOnline -Url "https://$tenantName-admin.sharepoint.com" -ClientId $clientId -Thumbprint $thumbPrint -Tenant "$tenantName.onmicrosoft.com"

#Verify the connection is valid
Get-PnPContext

#Add the credentials to the Windows credential store
Add-PnPStoredCredential -Name "$applicationName" -Username $clientId -Password $(ConvertTo-SecureString $thumbPrint -AsPlainText -Force)

#Clean up exported certificate files
Get-ChildItem -Path $outputPath | Where-Object { $_.Name -like "*$applicationName*" } | Remove-Item -Force
