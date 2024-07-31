# $thumb = "xxx"
# Connect-AzureAD -TenantId xxx -ApplicationId  xxx -CertificateThumbprint $thumb
# Connect-MgGraph -TenantId xxx -ClientID xxx -CertificateThumbprint $thumb
# Connect-PnPOnline -url "xxx"

function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    # If File not exists use Add-Content to create it and add content
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

#init folderId variable
$folderId

$groupId = "xxx"
#$group = Get-AzureADGroup -Filter "ObjectId eq '$groupId'"

$bla = @("Buchmayer Lukas") 
$members = Get-AzureADGroupMember -ObjectId $groupId | Where-Object { $_.DisplayName -in $bla }
#$members = Get-AzureADGroupMember -ObjectId $groupId

$csvLogging = "C:\LOG_SyncContact_FuncNum.csv"

$yesterday = (Get-Date).AddDays(-1)
$query = "<View><Query><Where><Geq><FieldRef Name='Modified'/><Value Type='DateTime'>$($yesterday.ToString("yyyy-MM-ddTHH:mm:ssZ"))</Value></Geq></Where></Query></View>"
$items = Get-PnPListItem -list "TestContacts" -Query $query | Select-Object -Unique

if($items.count -eq 0){
    WriteLog('[INFO] Problem with list or item retrieval. Either list is empty or items could not be retrieved')
    return
}

if($members.count -eq 0){
    WriteLog('[INFO] Problem with retrieving group or group is empty')
    return
}

$contacts = $items | ForEach-Object {
    [PSCustomObject]@{
        GivenName = $_.FieldValues.Vorname
        Surname = $_.FieldValues.Nachname
        businessPhones = $_.FieldValues.BusinessPhones
        OfficeLocation = $_.FieldValues.Standort
        Status = $_.FieldValues.Status
    }
}

WriteLog('-------------------------------------------')
WriteLog('[INIT] Script start run')
WriteLog('-------------------------------------------')

foreach($member in $members){
    $memberDets = Get-AzureADUser -ObjectId $member.ObjectId
    $memberId = $memberDets.UserPrincipalName

    $existingFolder = Get-MgUserContactFolder -userid $memberId | Where-Object { $_.DisplayName -eq "CAL Funktionsnummern"}
    if($null -eq $existingFolder){ #folder doesnt exist
        $msg = "[ERROR] Folder 'CAL Contacts' doesnt exist for user $($memberId)"
        WriteLog($msg)
    } else {
        $folderId = $existingFolder.Id
    }

    foreach($contact in $contacts){
        $params = @{
            givenName = $contact.givenName
            surname = $contact.surname
            businessPhones = @($contact.businessPhones)
            OfficeLocation = $contact.OfficeLocation
            categories = @("CAL Funktionsnummern")
        }

        $stat = $contact.Status

        #filter method
        $existingContact = Get-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderId -Filter "businessPhones/any(c: c eq '$($contact.businessPhones[0])')"
        if($null -eq $existingContact){
            New-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderId -BodyParameter $params
            WriteLog('[INFO] Created new contact, did not exist')
        } else {
            #has choice field in sharepoint list called "status" with 2 choices for version control and filtering
            if($stat -eq "Updated"){
                #remove contact
                $msg = "[INFO] Updated contact $($existingContact.BusinessPhones)"
                Remove-MgUserContactFolderContact -UserId $memberId -ContactFolderId -ContactId $existingContact.Id
                New-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId -BodyParameter $params
                WriteLog($msg)
            }
            if($stat -eq "Deleted"){
                $msg = "[INFO] Contact deleted $($existingContact.BusinessPhones)"
                Remove-MgUserContactFolderContact -UserId $memberId -ContactFolderId -ContactId $existingContact.Id
                WriteLog($msg)
            }
        }

    }
}


$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
