<#
.SYNOPSIS
    Removes special characters from business phone number from user and applies various policies.
.DESCRIPTION
    From a specified group via parameter input, all users' in group get their phone number chaned, i.e. the special characters removed.
    Additionally, phone direct routing is enabled.
    The following policies are also enabled: (add these accordingly)
    Users are also checked to see if they are part of the E5 group, aka if they have an E5 license-
.PARAMETER groupId
    Object ID of group who's members should get their numbers parsed and policies assigned/applied
    Type = String
    Expected Value Format = xxxxyyyy-xxxx-yyyy-xxxxyyyy
.EXAMPLE
    .\PhoneParseV2.ps1 xxxxxxxx
.EXAMPLE
    .\PhoneParseV2.ps1
    groupId:xxxxxxx
.OUTPUTS
    The parsed number of the user is then assigned as the new number in AD and the various policies are assigned/applied
#>

#todo: active filter, parameter for exec (object), 

Param(
    [Parameter(Position=0,mandatory=$true)]
    [string]$groupId
)

function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$csvLogging = "x"

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

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
                Get-CsOnlineUser $memberId | Grant-CsOnlineVoiceRoutingPolicy -PolicyName "xx"
                Get-CsOnlineUser $memberId | Grant-CsTenantDialPlan -PolicyName "xx"
                Get-CsOnlineUser $memberId | Set-CsTeamsCallingPolicy -Policyname "xx"
                
                $msg = "[INFO] Number parsed: $($memberId) (E5) -> $($num), policies applied"
                WriteLog($msg)
                Write-Host($msg)
            }

        }

    } catch {
        throw $_.Exception
    }
}


$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
