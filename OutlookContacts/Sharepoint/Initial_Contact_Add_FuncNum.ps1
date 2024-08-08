
function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    # If File not exists use Add-Content to create it and add content
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

$folder = "CAL Contacts"

$groupId = "xxx"
#$group = Get-AzureADGroup -Filter "ObjectId eq '$groupId'"

$bla = @("Buchmayer Lukas")
$members = Get-AzureADGroupMember -ObjectId $groupId | Where-Object { $_.DisplayName -in $bla }
#$members = Get-AzureADGroupMember -ObjectId $groupId

$csvLogging = "C:\LOG_InitialContactAdd_FuncNum.csv"

$items = Get-PnPListItem -list "TestContacts"

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

    New-MgUserContactFolder -userid $memberId -DisplayName "CAL Funktionsnummern"
    $folder = Get-MgUserContactFolder -userid $memberId | Where-Object { $_.DisplayName -eq "CAL Funktionsnummern" }
    $folderid = $folder.id

    foreach($contact in $contacts){
        $params = @{
            givenName = $contact.givenName
            surname = $contact.surname
            businessPhones = @($contact.businessPhones)
            categories = @("CAL Funktionsnummern")
            OfficeLocation = $contact.OfficeLocation
        }

        New-MgUserContactFolderContact -userId $memberId -ContactFolderId $folderid -BodyParameter $params
    }

    $logmsg = "[INFO] Func Numbers added for $($memberDets.DisplayName), $($memberId)"
    WriteLog($logmsg) 
}

$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
