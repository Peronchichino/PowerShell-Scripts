Connect-AzureAd

#new task: add domain to user (can see in email)

function func_user_set_TeamPhoneSettings([string] $UPN){
    try{
        $user = Get-AzADUser -UserPrincipalName $UPN

        $e5GroupDistinguishedName = "CN=gg_lic_O365_E5_Basis,OU=licence,OU=m365,OU=cloudservices,OU=resources,DC=office,DC=lottery,DC=co,DC=at"
        $e5members = Get-ADGroupMember -Identity $e5GroupDistinguishedName

        $isMember = $e5members | Where-Object { $_.UserPrincipalName -eq $UPN }
        if ($user -ne $null) {
            Write-Host "User's phone number: $($user.BusinessPhone)"
            $num = $($user.BusinessPhone) -replace '[()\s-]', ''
            Write-Host "After parse: $num"
        } else {
            Write-Host "User not found."
        }

        if ($isMember) {
            Write-Host "$UPN is a member of E5."
        } else {
            Write-Host "$UPN is not a member of E5."
        }

        $splitEmailDomain = $user.Mail -split '@'
        if($splitEmailDomain.Count -eq 2){
            $domain = $splitEmailDomain[1]
            Write-Host "Domain: $domain`r`n"
        }

    } catch{
        throw $_.Exception
    }
}

function func_group_set_TeamPhoneSettings([string]$group){
    try{
        Get-AzureADGroup -Filter "ObjectId eq '$group'"

        if($group){
            $groupMembers = Get-AzureADGroupMember -objectid $group 
            $e5GroupDistinguishedName = "CN=gg_lic_O365_E5_Basis,OU=licence,OU=m365,OU=cloudservices,OU=resources,DC=office,DC=lottery,DC=co,DC=at"
            #$e5members = Get-AzureADGroupMember -objectid "ce2f8a16-154d-451d-a99b-d34034a7acd5"
            $e5members = Get-ADGroupMember -Identity $e5GroupDistinguishedName

            if ($groupMembers.Count -eq 0) {
                Write-Host "No members found in the group: $groupName"
                return
            }

            if($e5members.Count -eq 0){
                Write-Host "Problem with retrieving E5 group"
                return
            }
            
            foreach($member in $groupMembers){
                #$isInSpecificGroup = $e5members | Where-Object { $_.ObjectId -eq $member.ObjectId }
                $isInSpecificGroup = $e5Members | Where-Object { $_.SamAccountName -eq $member.SamAccountName }
                
                if($isInSpecificGroup){
                    $name = "$($member.DisplayName)(E5)"
                } else {
                    $name = "$($member.DisplayName)"
                }

                if($member.TelephoneNumber){
                    $num = $($member.TelephoneNumber) -replace '[()\s-]', ''
                    Write-Host "Name: $name, E-Mail: $($member.UserPrincipalName), Teams-Phone: $num"
                } else {
                    Write-Host "Name: $name, E-Mail: $($member.UserPrincipalName), Teams-Phone: --- NA ---"
                }

                $splitEmailDomain = $member.Mail -split '@'
                if($splitEmailDomain.Count -eq 2){
                    $domain = $splitEmailDomain[1]
                    Write-Host "Domain: $domain`r`n"
                }
        }
        }
    } catch{
        throw $_.Exception
    }
}

Write-Host @"
Key to getting user or group"
-Group -> g
-User -> u
"@

[string]$in = Read-Host -Prompt "User or group"

switch($in){
    g {
        $choice = Read-Host -Prompt "Enter group ID"
        func_group_set_TeamPhoneSettings($choice)
        break
    }
    u {
        $choice = Read-Host -Prompt "User email"
        func_user_set_TeamPhoneSettings($choice)
        break
    }
    default{
        Write-Host "Input is not valid"
        return
    }
}

Disconnect-AzureAD