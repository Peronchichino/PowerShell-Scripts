# data type: hash table list
# currently unsorted, needs to be sorted
# list is retrieved unsorted
    # needs key for sorting
    # fast algorithm for easier sorting
    # question: necessary?
    # goal: cut down runtime

# option 1: change data structure from hash table list to hash table only and then using batch api calls
$contacts = @{}

foreach($item in $data){
    $fields = $item.Fields.AdditionalProperties
    $contact = @{
        id = $item.id
        givenName = $fields.field_1
        surname = $fields.field_2
        status = if($fields.Status -eq $NULL) {""} else {$fields.Status}
    }

    $contacts += $contact
}

$batchRequests = @()

foreach($contact in $contacts) {
    $params = @{
        givenName = $contact.givenName
        surname = $contact.surname
        PersonalNotes = $contact.id
    }

    $request = @{
        id = [guid]::NewGuid().ToString()
        method = "POST"
        url = "/users/$memberId/contactFolders/$folderId/contacts"
        body = $params
    }

    $batchRequests += $request

    # should theoretically reduce overead by using a direct POST method rathing than having to use the API
    if($batchRequests.Count -eq 20) {
        Invoke-MgGraphBatchRequests -BatchRequest $batchRequests
        $batchRequests.Clear()
    }
}

if($batchRequests.Count -gt 0){
    Invoke-MgGraphBatchRequests -BatchRequest $batchRequests
}

#--------------------------------------------------------------------






# option 2: reducing number of API calls in foreach loop, specifically by calling members outside for each loop for ID
try {
    $userId = if ($targetType -eq "User") { $TestUserId } else { $member.Id }
    $memberDets = Get-MgUser -UserId $userId
    $memberId = $memberDets.UserPrincipalName

    $existingFolderSkip = Get-MgUserContactFolder -UserId $memberId | Where-Object { $_.DisplayName -eq $folderName }
} catch {
    WriteLog("[ERROR] Error retrieving member and folder: $($_.Exception.Message)")
}

#change this to another seperate foreach loop just for storing the member IDs, so that it doesnt have to make the API call every time the foreach loop runs

$members = Get-MgGroupMember -GroupId $groupId -ConsistencyLevel eventual -ErrorAction Stop

$membersCollapsed = @{}
foreach($member in $members){
    try {
        $userId = if ($targetType -eq "User") { $TestUserId } else { $member.Id }
        $memberDets = Get-MgUser -UserId $userId
        $membersCollapsed[$member.Id] = $memberDets.UserPrincipalName
    } catch {
        WriteLog("[ERROR] Error retrieving member details: $($_.Exception.Message)")
    }
}


foreach ($member in $members) {
    $memberId = $membersCollapsed[$member.Id]

    #rest of loop, should save an additional 3000+api calls
}


#---------------------------------------------





#-checking e5 status before loop to lessen API calls again

function CheckE5{
    Param ([string]$userIdForCheck_email)
    $searchQuery = "userPrincipalName:$userIdForCheck_email"
    $checkE5 = Get-MgGroupMember -GroupId $e5groupId -search $searchQuery -ConsistencyLevel eventual -ErrorAction Stop -all
    if($checkE5){
        return $true
    } else {
        return $false
    }   
}


$hasE5 = CheckE5($memberId);

# heres a possible fix, once again with a hash table and a simple key comparison between 2 hash tables
$e5GroupMembers = Get-MgGroupMember -GroupId $e5groupId -search $searchQuery -ConsistencyLevel eventual -ErrorAction Stop -all #only 1 api call instead of 3000+
$e5MembersCollapsed = @{} #hashtable

#filling hashtable with user ids
foreach ($member in $e5GroupMembers){
    $e5MembersCollapsed[$member.UserPrincipalName] = $true
}

function IsE5Member {
    param([string]$UserPrincipalName)

    if($e5MembersCollapsed.ContainsKey($UserPrincipalName)) {
        return $true
    } else {
        return $false
    }
}

#in foreach loop for import
foreach($member in $members){
    #other stuff from before


    $hasE5 = IsE5Member($memberId);

    if($hasE5){
        # continue with import

    } else {
        #skip contact
        continue
    }
}
