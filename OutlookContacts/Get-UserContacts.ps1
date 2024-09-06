function Get-UserContacts {
    param(
        [Parameter( Mandatory=$true)]
        [string]$userid
    )

    try{
        $thumb = "xx"
        $applicationID ="xx"
        $tenantID ="xx"

        Connect-MgGraph -TenantId $tenantID -ClientID $applicationID -CertificateThumbprint $thumb -ErrorAction Stop

    } catch {
        throw $_.Exception.Message
    }

    Get-MgUserContact -userid $userid -Top 20
    Get-MgUserContactFolder -userid $userid

    $folders = Get-MgUserContactFolder -userid $userid -all

    foreach($folder in $folders){
        Write-Host $folder.DisplayName+" | "+$folder.Id
        Get-MgUserContactFolder -userid $userid -Top 20
    }

    Disconnect-MgGraph
}
