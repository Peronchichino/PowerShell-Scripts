<#
.SYNOPSIS
    Intune Remediation Script - Edge Update Version Pin Cleanup
.DESCRIPTION
    Removes TargetVersionPrefix and Rollback values from registry paths and triggers Edge Update.
#>

$Paths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate",
    "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\EdgeUpdate"
)

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        $RegistryKey = Get-Item -Path $Path -ErrorAction SilentlyContinue
        $ValueNames = $RegistryKey.GetValueNames() | Where-Object { 
            $_ -like "TargetVersionPrefix*" -or $_ -like "RollbackToTargetVersion*" 
        }
        
        foreach ($Name in $ValueNames) {
            try {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
                Write-Output "Successfully removed $Name from $Path"
            }
            catch {
                Write-Error "Failed to remove $Name from $Path. Reason: $_"
            }
        }
    }
}

# Force Edge Update execution to bypass the 600-minute timer for an instant check
$EdgeUpdateExe = "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
if (Test-Path $EdgeUpdateExe) {
    try {
        Write-Output "Triggering background Microsoft Edge Update check..."
        Start-Process -FilePath $EdgeUpdateExe -ArgumentList "/ua /installsource scheduler" -NoNewWindow
        Write-Output "Edge Update triggered successfully."
    }
    catch {
        Write-Output "Could not trigger Edge Update executable: $_"
    }
}

exit 0