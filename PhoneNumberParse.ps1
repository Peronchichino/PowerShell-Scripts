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

function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$csvLogging = "x"


$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

#TODO: refactor
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

        #azure attributes for phone numbers: BusinessPhone -> TelephoneNumber; MobilePhone -> Mobile
        if($member -ne $null){
            $num = $($member.TelephoneNumber) -replace '[()\s-]', ''
            Write-Host($num)
            $domainbuff = $member.Mail -split '@'
            if($domainbuff.Count -eq 2){
                $domain = $domainbuff[1]
            }

            #change number
            Set-AzureADUser -ObjectId $member.ObjectId -TelephoneNumber $num
            $msg = "[INFO] Number parsed: $($memberId) -> $($num)"
            WriteLog($msg)
        }

        Write-Host($memberId+": "+$num+" | "+$domain);
    } catch {
        throw $_.Exception
    }
}


$benchmark.Stop()
$time = "[Benchmark] $($benchmark.ElapsedMilliseconds) ms"
WriteLog($time)
WriteLog('-------------------------------------------')
