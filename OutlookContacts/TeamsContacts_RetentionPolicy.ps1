$csvLogging = ""

$thumb = ""
$applicationID = ""
$tenantID = ""
$folderName = ""

$groupId = ""
$e5groupId = ""

$folderName = "" #CAL Kontake, CAL Funktionsnummern

$batchSize = 20

function WriteLog {
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" .f (Get-Date)
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Retention Policy Changes Logging"}
    Add-Content $csvLogging -Value "$dateTime $logString"
}


function IsE5Member {
    param ($userPrincipalName)
    return $e5MembersTable.ContainsKey($userPrincipalName)
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

WriteLog('-------------------------------------------')
WriteLog("[INIT] Script start run, group: $groupId")
WriteLog('-------------------------------------------')


try{
    Connect-MgGraph -TenantId $tenantID -ClientId $applicationID -CertificateThumbprint $thumb
    $members = Get-MgGroupMember -GroupId $groupId -ConsistencyLevel eventual -All

    if($members.Count -eq 0){
        WriteLog('[WARNING] Problem with retrieving group or group is empty.')
        return
    }

} catch {
    WriteLog("[ERROR] Error/Exception in List and Member retrieval: $($_.Exception.Message)")
    WriteLog("[ERROR] $($_.Exception.StackTrace)")
}

$userIdTable = @{}
foreach ($member in $members) {
    try {
        $userId = if ($targetType -eq "User") { $TestUserId } else { $member.Id }
        $memberDets = Get-MgUser -UserId $userId
        $userIdTable[$member.Id] = $memberDets.UserPrincipalName
    } catch {
        WriteLog "[ERROR] Error retrieving member: $($_.Exception.Message)"
    }
}
WriteLog "[INFO] Prefetched $($userIdTable.Count) users."

$e5GroupMembers = Get-MgGroupMember -GroupId $e5GroupId -ConsistencyLevel eventual -All
$e5MembersTable = @()
foreach($member in $e5GroupMembers){
    $e5MembersTable[$member.UserPrincipalName] = $true
}

foreach($member in $members){
    $memberId = $userIdTable[$member.Id]
    if (-not $memberId) {
        WriteLog "[WARN] Skipping member with missing UserPrincipalName: $($member.Id)"
        continue
    }

    if (-not (IsE5Member $memberId)) {
        continue
    }

    try{
        for ($i = 0; $i -lt $contacts.Count; $i += $batchSize) {
            $batch = $contacts[$i..([math]::Min($i + $batchSize - 1, $contacts.Count - 1))]

            foreach ($contact in $batch) {
                $params = @{
                    givenName      = $contact.givenName
                    surname        = $contact.surname
                    businessPhones = @($contact.businessPhones)
                    categories     = @($folderName)
                    officeLocation = $contact.officeLocation
                    personalNotes  = $contact.id
                }

                try {
                    New-MgUserContactFolderContact -UserId $memberId -ContactFolderId $folderId -BodyParameter $params
                } catch {
                    WriteLog "[ERROR] Failed to create contact $($contact.givenName) $($contact.surname) for $($memberId): $($_.Exception.Message)"
                }
            }
        }


        WriteLog "[INFO] Retention policy updated for $($memberId)"

    } catch {
        WriteLog "[ERROR] Error processing user $($memberId): $($_.Exception.Message)"
    }

}

Disconnect-MgGraph

$benchmark.Stop()
WriteLog("[Benchmark] $($benchmark.ElapsedMilliseconds) ms")
WriteLog('-------------------------------------------')
