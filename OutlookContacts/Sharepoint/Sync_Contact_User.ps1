
function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

$groupId = "x"
#$group = Get-AzureADGroup -Filter "ObjectId eq '$groupId'"

$bla = @("Buchmayer Lukas")
$members = Get-AzureADGroupMember -ObjectId $groupId | Where-Object { $_.DisplayName -in $bla }
#$members = Get-AzureADGroupMember -ObjectId $groupId


#TODO: add source
$csvLogging = "x"

# $csvFilePath = "x"
# $outputFile = "x"
# $data = Get-Content -Path $csvFilePath

# $processedData = $data | Select-Object -Skip 1 | ForEach-Object {
#     $columns = $_ -split ';'
#     [PSCustomObject]@{
#         GivenName = $columns[1].Trim('"')
#         Surname = $columns[2].Trim('"')
#         emailAddresses = $columns[3].Trim('"')
#         businessPhones = $columns[4].Trim('"')
#         mobilePhone = $columns[5].Trim('"').Replace(' ', '')
#         CompanyName = $columns[6].Trim('"')
#         Department = $columns[7].Trim('"')
#         OfficeLocation = $columns[8].Trim('"')
#         categories = ''
#     }
# } | ConvertTo-Csv -NoTypeInformation
# $processedData | Set-Content -Path $outputFile -Encoding UTF8

$csvFilePath = "x"
$outputFile = "x"

$data = Get-Content -Path $csvFilePath

$processedData = $data | ForEach-Object {
    $columns = $_ -split ';'
    [PSCustomObject]@{
        GivenName = $columns[1].Trim('"')
        Surname = $columns[2].Trim('"')
        emailAddresses = $columns[3].Trim('"')
        businessPhones = $columns[4].Trim('"')
        mobilePhone = $columns[5].Trim('"').Replace(' ', '')
        CompanyName = $columns[6].Trim('"')
        Department = $columns[7].Trim('"')
        OfficeLocation = $columns[8].Trim('"')
        categories = ''
    }
} | ConvertTo-Csv -NoTypeInformation

$headers = "GivenName,Surname,emailAddresses,businessPhones,mobilePhone,CompanyName,Department,OfficeLocation,categories"
$processedData = $headers + "`n" + $processedData

$processedData | Set-Content -Path $outputFile -Encoding UTF8

# $csvFilePathDel = "x"
# $outputFileDel = "x"
# $dataDel = Get-Content -Path $csvFilePathDel

# $processedDataDel = $dataDel | Select-Object -Skip 1 | ForEach-Object {
#     $columns = $_ -split ';'
#     [PSCustomObject]@{
#         GivenName = $columns[1].Trim('"')
#         Surname = $columns[2].Trim('"')
#         emailAddresses = $columns[3].Trim('"')
#         businessPhones = $columns[4].Trim('"')
#         mobilePhone = $columns[5].Trim('"').Replace(' ', '')
#         CompanyName = $columns[6].Trim('"')
#         Department = $columns[7].Trim('"')
#         OfficeLocation = $columns[8].Trim('"')
#         categories = ''
#     }
# } | ConvertTo-Csv -NoTypeInformation
# $processedDataDel | Set-Content -Path $outputFileDel -Encoding UTF8


$csvFilePathDel = "x"
$outputFileDel = "x"

$dataDel = Get-Content -Path $csvFilePathDel

$processedDataDel = $dataDel | ForEach-Object {
    $columns = $_ -split ';'
    [PSCustomObject]@{
        GivenName = $columns[1]
        Surname = $columns[2]
        emailAddresses = $columns[3]
        businessPhones = $columns[4]
        mobilePhone = $columns[5]
        CompanyName = $columns[6]
        Department = $columns[7]
        OfficeLocation = $columns[8]
        categories = ''
    }
} | ConvertTo-Csv -NoTypeInformation

$headers = "GivenName,Surname,emailAddresses,businessPhones,mobilePhone,CompanyName,Department,OfficeLocation,categories"
$processedDataDel = $headers + "`n" + $processedDataDel

$processedDataDel | Set-Content -Path $outputFileDel -Encoding UTF8


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

    #TODO: filter for contacts and folder
    $existingFolder = Get-MgUserContactFolder -userid $memberId | Where-Object { $_.DisplayName -eq "CAL Contacts"}
    if($null -eq $existingFolder){ #folder doesnt exist
        $msg = "[ERROR] Folder 'CAL Contacts' doesnt exist for user $($memberId)"
        WriteLog($msg)
    } else {
        $folderId = $existingFolder.Id
    }

    $contacts = Import-Csv -Path $outputFile
    $contactsDel = Import-Csv -Path $outputFileDel

    foreach($contact in $contacts){
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

        New-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId -BodyParameter $params


        # $existingContact = Get-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId -Filter "mobilePhone eq '$($contact.mobilePhone)'"

        # if($null -eq $existingContact){
        #     New-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderId -BodyParameter $params
        #     WriteLog('[INFO] Created new contact, did not exist')
        # } else {
        #     $oldParams = @{
        #         givenName = $existingContact.GivenName
        #         surname = $existingContact.Surname
        #         emailAddresses = @(
        #             @{
        #                 address = $existingContact.EmailAddresses
        #                 name = $contact.emailNames
        #             }
        #         )
        #         businessPhones = @($existingContact.BusinessPhones)
        #         mobilePhone = $existingContact.MobilePhone
        #         CompanyName = $existingContact.CompanyName
        #         Department = $existingContact.Department
        #         OfficeLocation = $existingContact.OfficeLocation
        #         categories = @("CAL Contacts")
        #     }

        #     $diff = Compare-Object -ReferenceObject $oldParams -DifferenceObject $params -Property * -PassThru
        #     #-CaseSensitive:$false

        #     if($diff){
        #         Remove-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderId -ContactId $existingContact.Id
        #         $msg = "[INFO] Updated contact $($existingContact.BusinessPhones)"
        #         New-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId -BodyParameter $params
        #         WriteLog($msg)
        #     } else {
        #         #do nothing
        #         $msg = "[INFO] Contact up-to-date $($existingContact.BusinessPhones)"
        #         WriteLog($msg)
        #     }

        #     Remove-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderId -ContactId $existingContact.Id
        #     $msg = "[INFO] Updated contact $($existingContact.mobilePhone)"
        #     New-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId -BodyParameter $params
        #     WriteLog($msg)
        # }
    }

    foreach($contactDel in $contactsDel){
        $toDelete = Get-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId -Filter "mobilePhone eq '$($contactDel.mobilePhone)'"
        if($toDelete){
            Remove-MgUserContactFolderContact -userid $memberId -ContactFolderId $folderId $toDelete.Id
            $msg = "[INFO] Deleted contact $($toDelete.mobilePhone)"
            WriteLog($msg)
        }
    }
}

# delete created files to remove bloat
if(Test-Path $outputFileDel){
    Remove-Item $outputFileDel -Verbose
} else {
    WriteLog("[FILE] Couldnt delete outputFileDel, check file/path")
}

if(Test-Path $outputFile){
    Remove-Item $outputFile -Verbose
} else {
    WriteLog("[FILE] Couldnt delete outputFile, check file/path")
}

#benchmark
$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
