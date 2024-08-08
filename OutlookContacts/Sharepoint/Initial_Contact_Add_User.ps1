

function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    # If File not exists use Add-Content to create it and add content
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

$groupId = "x"
#$group = Get-AzureADGroup -Filter "ObjectId eq '$groupId'"

$bla = @("x")
$members = Get-AzureADGroupMember -ObjectId $groupId | Where-Object { $_.DisplayName -in $bla }
#$members = Get-AzureADGroupMember -ObjectId $groupId

$csvLogging = "x"

$csvFilePath = "x"
$outputFile = "x"
$data = Get-Content -Path $csvFilePath

$processedData = $data | Select-Object -Skip 1 | ForEach-Object {
    $columns = $_ -split ';'
    [PSCustomObject]@{
        GivenName = $columns[1].Trim('"')
        Surname = $columns[2].Trim('"')
        emailAddresses = $columns[3].Trim('"')
        businessPhones = $columns[4].Trim('"')
        mobilePhone = $columns[5].Trim('"').Replace(' ', '') # add + sign and remove spaces '+' + 
        CompanyName = $columns[6].Trim('"')
        Department = $columns[7].Trim('"')
        OfficeLocation = $columns[8].Trim('"')
        categories = '' # assuming this column is empty or not present in the original data
    }
} | ConvertTo-Csv -NoTypeInformation

$processedData | Set-Content -Path $outputFile -Encoding UTF8

if($members.count -eq 0){
    WriteLog('[INFO] Problem with retrieving group or group is empty')
    return
}

WriteLog('-------------------------------------------')
WriteLog('[INIT] Script start run')
WriteLog('-------------------------------------------')

foreach($member in $members){
    $memberDets = Get-AzureADUser -ObjectId $member.ObjectId
    $memberId = $memberDets.UserPrincipalName

    New-MgUserContactFolder -userid $memberId -DisplayName "CAL Contacts"
    $folder = Get-MgUserContactFolder -userid $memberId | Where-Object { $_.DisplayName -eq "CAL Contacts" }
    $folderid = $folder.id
    $importedContacts = Import-Csv -Path $outputFile -Encoding UTF8

    foreach($contact in $importedContacts){
        $params = @{
            givenName = $contact.givenName
            surname = $contact.surname
            businessPhones = @($contact.businessPhones)
            mobilePhone = $contact.mobilePhone
            CompanyName = $contact.CompanyName
            Department = $contact.Department
            OfficeLocation = $contact.OfficeLocation
            categories = @("CAL Contacts")
        }

        New-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderid -BodyParameter $params

    }
    $logmsg = "[INFO] Contacts added for $($memberDets.DisplayName), $($memberId)"
    WriteLog($logmsg) 
}

$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
