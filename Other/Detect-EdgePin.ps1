<#
.SYNOPSIS
    Intune Detection Script - Edge Update Version Pin
.DESCRIPTION
    Checks both 64-bit and 32-bit registry paths for TargetVersionPrefix entries.
#>

$Paths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate",
    "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\EdgeUpdate"
)

$TargetFound = $false

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        $RegistryKey = Get-Item -Path $Path -ErrorAction SilentlyContinue
        
        # Scan for any property starting with TargetVersionPrefix
        $ValueNames = $RegistryKey.GetValueNames() | Where-Object { $_ -like "TargetVersionPrefix*" }
        
        if ($ValueNames) {
            $TargetFound = $true
            foreach ($Name in $ValueNames) {
                $Value = $RegistryKey.GetValue($Name)
                Write-Output "Non-Compliant: Found $Name = $Value at $Path"
            }
        }
    }
}

if ($TargetFound) {
    # Exit 1 tells Intune the device needs Remediation
    exit 1
} else {
    Write-Output "Compliant: No Edge TargetVersionPrefix pins found."
    exit 0
}