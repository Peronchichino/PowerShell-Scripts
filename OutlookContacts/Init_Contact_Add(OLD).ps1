$thumb = "xxx"
Connect-AzureAD -TenantId xxx -ApplicationId  xxx -CertificateThumbprint $thumb
Connect-MgGraph -TenantId xxx -ClientID xxx -CertificateThumbprint $thumb
Connect-PnPOnline -url "xxx//"


function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    # If File not exists use Add-Content to create it and add content
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

#contact folder display name 
$folder = "CAL Contacts"

$groupId = "xxx"
#$group = Get-AzureADGroup -Filter "ObjectId eq '$groupId'"

$bla = @("Buchmayer Lukas", "Ferner Andreas")

$members = Get-AzureADGroupMember -ObjectId "xxx" | Where-Object { $_.DisplayName -in $bla }

$csvLogging = "C:\...\graphapilogfile.csv"

$items = Get-PnPListItem -list "TestContacts"

if($items.count -eq 0){
    WriteLog('[INFO] Problem with list or item retrieval. Either list is empty or items could not be retrievewd')
    return
}

if($members.count -eq 0){
    WriteLog('[INFO] Problem with retrieving group or gromp is empty')
    return
}

$itemsToExport = $items | ForEach-Object {
    [PSCustomObject]@{
        GivenName = $_.FieldValues.Title
        Surname = $_.FieldValues.Surname
        Initials = $_.FieldValues.Initials
        emailAddresses = $_.FieldValues.emailAddresses
        emailNames = $_.FieldValues.emailNames
        businessPhones = $_.FieldValues.businessPhones
        categories = $_.FieldValues.categories
        CompanyName = $_.FieldValues.CompanyName
        Department = $_.FieldValues.Department
        OfficeLocation = $_.FieldValues.OfficeLocation
    }
}

foreach($member in $members){
    $memberDets = Get-AzureADUser -ObjectId $member.ObjectId
    $memberId = $memberDets.UserPrincipalName


    $contactFolders = Get-MgUserContactFolder -userid $memberId

    $existingFolder = $contactFolders | Where-Object { $_.DisplayName -eq "CAL Contacts" }

    if($null -eq $existingFolder){
        $createFolder = New-MgUserContactFolder -userid $memberId -DisplayName "CAL Contacts"
        $folderId = $createFolder.Id
        WriteLog('[CMD] Folder created')
    } else {
        $folderId = $existingFolder.Id
        WriteLog('[INFO] Folder already exists')
    }


    foreach($contact in $itemsToExport){
        $params = @{
            givenName = $contact.givenName
            surname = $contact.surname
            emailAddresses = @(
                @{
                    address = $contact.emailAddresses
                    name = $contact.emailNames
                }
            )
            businessPhones = @($contact.businessPhones)
            categories = @($contact.categories)
            CompanyName = $contact.CompanyName
            Department = $contact.Department
            OfficeLocation = $contact.OfficeLocation
        }

        New-MgUserContactFolderContact -userId $memberId -ContactFolderId $folderId -BodyParameter $params
    }

}

WriteLog('[CMD] Script finished, all successes')

$benchmark.Stop()

Write-Host "Benchmarking:`n-----------------------------"
Write-Host "Time elapsed: "$benchmark.Elapsed
Write-Host "Time elapsed (ms): "$benchmark.ElapsedMilliseconds"`n"
