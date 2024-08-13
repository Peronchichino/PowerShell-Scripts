<#
.SYNOPSIS
    IDK
.DESCRIPTION
    Parses a AD User's phone number, removing all extra characters from the string and leaving just the numbers and area code.
.EXAMPLE
    +43 (0110) - 11111 00011101 -> +4301101111100011101
.OUTPUTS
    The parsed number of the user is then assigned as the new number of the user in AD
#>

#todo: e5 + active filter, parameter for exec (object), 

function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$csvLogging = "x"

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

$groupId = "x"

$bla = @("Buchmayer Lukas")
$members = Get-AzureADGroupMember -ObjectId $groupId | Where-Object { $_.DisplayName -in $bla }

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

    try{
        $checkE5 = Get-AzureADUserMembership -ObjectID $member.ObjectId | where-object objectid -eq "xx"
        #azure attributes for phone numbers: BusinessPhone -> TelephoneNumber; MobilePhone -> Mobile
        if($member -ne $null){
            $num = $($member.TelephoneNumber) -replace '[()\s-]', ''
            if($checkE5 -ne $null){
                Set-AzureADUser -ObjectId $member.ObjectId -TelephoneNumber $num

                Set-CsPhoneNumberAssignment -Identity $memberId -PhoneNumber $num -PhoneNumberType DirectRouting
                Get-CsOnlineUser $memberId | Grant-CsOnlineVoiceRoutingPolicy -PolicyName "CAL_VRP_INT"
                Get-CsOnlineUser $memberId | Grant-CsTenantDialPlan -PolicyName "CAL DP 79070"
                Get-CsOnlineUser $memberId | Set-CsTeamsCallingPolicy -Policyname "General - no forwarding to external numbers"
                
                $msg = "[INFO] Number parsed: $($memberId) (E5) -> $($num)"
                WriteLog($msg)
                Write-Host($msg)
            }

        }

        $msg = "[RES] $($memberId): $($num), | $($domain)"
        WriteLog($msg)
        Write-Host($msg)
    } catch {
        throw $_.Exception
    }
}


$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
