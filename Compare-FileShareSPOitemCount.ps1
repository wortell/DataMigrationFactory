#Compare files and folders from a file share against the destination SharePoint Online site
#Version: 2.0
#Author: Andries den Haan
#Organisation: Wortell

function Get-FileShareItemCount {
    param (
        [string]$UNCPath,
        [array]$excludedFolders,
        [array]$excludedExtensions
    )

    try {

        #Record the start time
        $startTime = Get-Date

        #Specify the literal path for the fileshare considering the path length limitations
        $SrcFolderFullPath = "\\?\UNC\$($UNCPath.Replace('\\',''))"

        #Count all items
        Write-warning "Getting files and folders for `"$UNCPath`". This may take a while depending on the number of items!"

        $items = Get-ChildItem -LiteralPath $SrcFolderFullPath -Recurse -Force

        #Count folders
        $folders = $items | Where-Object { $_.PSIsContainer -eq $true }
        $hiddenFolders = $folders | Where-Object { $_.Attributes -match "Hidden" }
        $systemFolders = $folders | Where-Object { $_.Attributes -match "System" }

        #Count files
        $files = $items | Where-Object { $_.PSIsContainer -eq $false }
        
        if ($excludedExtensions) {

            $excludedFiles = $files | Where-Object { $_.extension -in $excludedExtensions }

        }

        $hiddenFiles = $files | Where-Object { $_.Attributes -match "Hidden" }
        $systemFiles = $files | Where-Object { $_.Attributes -match "System" }


        #Create object and store the gathered data
        $result = New-Object System.Object

        $result | Add-Member -MemberType NoteProperty -Name "UNCPath" -Value $UNCPath
        $result | Add-Member -MemberType NoteProperty -Name "TotalItems" -Value ($folders.Count + $files.Count)
        $result | Add-Member -MemberType NoteProperty -Name "TotalFolders" -Value $folders.Count
        $result | Add-Member -MemberType NoteProperty -Name "HiddenFolders" -Value $hiddenFolders.Count
        $result | Add-Member -MemberType NoteProperty -Name "SystemFolders" -Value $systemFolders.Count
        $result | Add-Member -MemberType NoteProperty -Name "TotalFiles" -Value $files.Count
        $result | Add-Member -MemberType NoteProperty -Name "ExludedFiles" -Value $excludedFiles.Count
        $result | Add-Member -MemberType NoteProperty -Name "HiddenFiles" -Value $hiddenFiles.Count
        $result | Add-Member -MemberType NoteProperty -Name "SystemFiles" -Value $systemFiles.Count
        $result | Add-Member -MemberType NoteProperty -Name "ValidFiles" -Value ($files.Count - ($excludedFiles.Count + $hiddenFiles.Count + $systemFiles.Count))

        #Record the end time
        $endTime = Get-Date

        #Register the processing time
        $result | Add-Member -MemberType NoteProperty -Name "ProcessingTimeSeconds" -Value (New-TimeSpan –Start $startTime –End $endTime).Seconds 

        #Return the result object
        return $result

    }
    catch {

        Write-Error $_.Exception.Message

    }

}

#Count the items in the destination list in SharePoint Online
function Get-SPOListItemCount {
    param (
        [string]$siteURL,
        [string]$listIdentity,
        [PSCredential]$credential,
        [string]$tenantName
    )

    try {

        #Record the start time
        $startTime = Get-Date 

        #Connect to SharePoint Online or OneDrive for Business
        $connection = Connect-PnPOnline -Url $siteURL -Credentials $credential -ReturnConnection

        #Get basic list info
        $list = Get-PnPList -Identity $listIdentity

        if ($null -ne $list) {

            #Get all items in the list - consider max item query threshold
            Write-warning "Getting files and folders for `"$listIdentity`". This may take a while depending on the number of items!"
            $listItems = Get-PnPListitem -List $listIdentity -Query "<view Scope='RecursiveAll'></view>" -PageSize 2000

            #Count folders
            $folders = $listItems | Where-Object { $_.FieldValues.FSObjType -eq 1 }
            $files = $listItems | Where-Object { $_.FieldValues.FSObjType -eq 0 }

            #Create object and store the gathered data
            $result = New-Object System.Object

            $result | Add-Member -MemberType NoteProperty -Name "Title" -Value $list.Title
            $result | Add-Member -MemberType NoteProperty -Name "Id" -Value $list.Id
            $result | Add-Member -MemberType NoteProperty -Name "ServerRelativeUrl" -Value $list.RootFolder.ServerRelativeUrl
            $result | Add-Member -MemberType NoteProperty -Name "BaseTemplate" -Value $list.BaseTemplate
            $result | Add-Member -MemberType NoteProperty -Name "BaseType" -Value $list.BaseType
            $result | Add-Member -MemberType NoteProperty -Name "TotalItems" -Value $list.ItemCount
            $result | Add-Member -MemberType NoteProperty -Name "TotalFolders" -Value $folders.Count
            $result | Add-Member -MemberType NoteProperty -Name "TotalFiles" -Value $files.Count

            #Record the end time
            $endTime = Get-Date

            #Register the processing time
            $result | Add-Member -MemberType NoteProperty -Name "ProcessingTimeSeconds" -Value (New-TimeSpan –Start $startTime –End $endTime).Seconds 


            #Disconnect from SharePoint Online or OneDrive for Business
            Disconnect-PnPOnline -Connection $connection

            #Return the result object
            return $result

        }
        else {

            Write-warning "List `"$listIdentity`" does not exist!"

        }

    }
    catch {

        Write-Error $_.Exception.Message

    }

}

##Perform the comparison

#Set variables
$sourceFolder = '{UNCpath fileshare}'
$tenantName = '{tenantName}'
$dstSite = '{siteURL}'
$dstList = '{ListName}'


#Get the credentials
if ( $null -eq $credential ) {

     $credential = Get-Credential

}

#Get the data from source and destination
$fileShareMetrics = Get-FileShareItemCount -UNCPath $sourceFolder
$SPOListMetrics = Get-SPOListItemCount -siteURL $dstSite -listIdentity $dstList -credential $dstCredential -tenantName $tenantName

#Output the gathered data
Write-Host "Fileshare metrics:"
$fileShareMetrics

Write-Host "SharePoint Online metrics:"
$SPOListMetrics

#Output and difference to be written to the housekeeping list
if (($fileShareMetrics.ValidFiles -ne $SPOListMetrics.TotalFiles) -or ($fileShareMetrics.TotalFolders -ne $SPOListMetrics.TotalFolders)) {

    Write-Warning "Item difference found! Source: $($fileShareMetrics.ValidFiles) files and $($fileShareMetrics.TotalFolders), Destination: $($SPOListMetrics.TotalFiles) files and $($SPOListMetrics.TotalFolders)"

}