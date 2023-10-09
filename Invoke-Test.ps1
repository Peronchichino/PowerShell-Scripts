function RequiredModules {
    $RequiredModules = @{"Az.Accounts" = ""; "Az.Resources" = ""; "AzureAd" = ""; "MSOnline" = ""; "ExchangeOnlineManagement" = ""; "MicrosoftTeams" = ""; "ADDInternals" = ""; "Microsoft.Online.SharePoint.Powershell" = ""; "PnP.PowerShell" ="1.12.0"; "Microsoft.Graph.Identity.SignIns" = ""; "Microsoft.Graph.Applications" = ""; "Microsoft.Graph.Users" = ""; "Microsoft.Graph.Groups" = ""}
    $missingModules = @{}
    $installedModules = @{}

    Write-Host "Checking for dependencies"
     $installedModules_count = 0

     foreach($module in $RequiredModules.Keys){
        try{
            if($RequiredModules[$module] -ne ""){
                Get-InstalledModule -Name $module -RequiredVersion $RequiredModules[$module] -ErrorAction Stop

                $installedModules_count++
                $installedModules[$module] = $RequiredModules[$module]
            } else {
                Get-InstalledModule -Name $module -ErrorAction Stop
                $installedModules_count++
                $installedModules[$module] = $RequiredModules[$module]
            }
        } catch{
            $missingModules[$module] = $RequiredModules[$module]
        }
     }

     if($installedModules_count -eq $RequiredModules.Count){
        Write-Host "All required modules available and installed"
        Write-Host "Continuing"
        $allow = $null
     } elseif($installedModules_count -lt $RequireModules.Count){
        Write-Host $installedModules_count / $($RequireModules.Count)" modules currently installed"
        Write-Host "Required modules that are missing:`n$(missingModules.Keys)"
        $allow = Read-Host -Prompt "Install missing modules? (y/n)"

        if($null -eq $allow){
            #continue
        } elseif($allow -notin "No","no","N","n"){
            Write-Host "Installing mossing modules"
            Set-ExecutionPolicy Unrestricted -Force
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

            foreach($module in $missingModules.Keys){
                Write-Host "'$module' does not exist, installing now"

                try{
                    if($missingModules[$module] -eq ""){
                        Install-Module -Name $module -Confirm:$false -WarningAction SilentlyContinue -ErrorAction Stop
                        $installedModules[$module] = $RequiredModules[$module]
                        Write-Host "Successfully installed module $module"
                    } else{
                        Install-Module -Name $module -RequiredVersion $missingModules[$module] -Confirm:$false -WarningAction SilentlyContinue -ErrorAction Stop
                        $installedModules[$module] = $RequiredModules[$module]
                        Write-Host "Successfully installed module $module"
                    }
                } catch{
                    Write-Host "Failed to install, skipping module $module"
                }
            }
        }else {
            Write-Host "some functions may fail if there are missing modules"
         }
     }

    Write-Host "Importing all moduels to current run space"
    foreach($module in $installedModules.Keys){

    }

}