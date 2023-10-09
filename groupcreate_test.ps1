<#
.SYNOPSIS
    Creates an M365 group in AD
.DESCRIPTION
    Script that creates a group without the welcome message/email, however certain parameters still need to be set such as the group name, the alias and which format you want to use (default, light, max, custom)
.EXAMPLE
    Enter new group name: Engineering Department
    Enter group alias: engdep

    Would you like to add members right now? (y/n): y
    Key to adding members to Engineering Department group .... etcetc
    Choice: s
    User E-Mail: max.mustermann@supermail.at
    Members, Owners, or Subscribers: members

.OUTPUTS
    Either exception messages that group has been created and then the formatting of the group or that the group already exists
.NOTES
    This is just a prototype made by trainee but should work quite well for basic group creation
#>
# ---------------------
# ----- Functions -----
# ---------------------

function addSingleUser{
    $in = Read-Host -Prompt "User E-Mail"
    $type = Read-Host -Prompt "Members, Owners, or Subscribers"
    try{
        Add-UnifiedGroupLinks -Identity $grp_name -LinkType $type -Links $in
        Write-Host "User "$in" added to group "$grp_name
    } catch{
        throw $_.Exception
    }
}

function addMultiUsers{
    try{
        #prototype still needs to be tested and checked
        $path = Read-Host -Prompt "Enter full path name to CSV file"
        Import-Csv $path | ForEach-Object{Add-UnifiedGroupLinks -Identity $grp_name -LinkType Members -Links $_.upn -Whatif}
    } catch{
        throw $_.Exception
    }
    
}

function addUsersFromGrp{
    $grp = Read-Host "Enter group name for new members"
    try{
        $mems = Get-User -ResultSize unlimited | where {$_.Department -eq $input}
        Add-UnifiedGroupLinks -Identity $grp_name -LinkType Members -Links ($mems.upn) #not sure if to use upn or UserPrincipalName
    } catch{
        throw $_.Exception
    }
}

# ---------------------
# ----- Main Code -----
# ---------------------

#group creation
[string]$grp_name = Read-Host -Prompt "Enter new group name"
[string]$grp_alias = Read-Host -Prompt "Enter group alias"

try{
    New-UnifiedGroup -DisplayName $grp_name -Alias $grp_alias `
        -AccessType Private `
        -AlwaysSubscribeMembersToCalendarEvents:$false

    Set-UnifiedGroup -Identity $grp_name `
        -UnifiedGroupWelcomeMessageEnabled:$false `
        -HiddenFromExchangeClientsEnabled:$true `
        -HiddenFromAddressListsEnabled:$true

    Set-Group -Identity $grp_name `
        -Notes "Test group, delete if necessary"

} catch {
    throw $_.Exception
}

#adding members
[string]$addMem_yn = Read-Host "Would you like to add members right now? (y/n)"

if($addMem_yn -eq 'y'){
    #do nothing and continue
} elseif($addMem_yn -eq 'n'){
    Write-Host "Creating group "$grp_name" without adding members"
    Get-UnifiedGroup -Identity $grp_name | Format-List
    exit
} else {
    Write-Host "Incorrect input, exiting without adding members"
    Get-UnifiedGroup -Identity $grp_name | Format-List
    exit
}

Write-Host @"
Key to adding members to "$grp_name":"
-Single user -> s
-Multiple specific users (CSV) -> m
-Users from an existing group -> g
-Exit/quit -> q
"@

$buf = Read-Host "Choice"
Write-Host "Please wait a moment to let the previous commands process properly"

Start-Sleep -Seconds 120

switch($buf){
    s {addSingleUser; break;}
    m {addMultiUsers; break;}
    g {addUsersFromGrp; break;}
    q {exit}
    default{return}
}

#wait 1min to allow processing time
Start-Sleep -Seconds 60

#print group
Get-UnifiedGroup -Identity $grp_name | Format-List

exit