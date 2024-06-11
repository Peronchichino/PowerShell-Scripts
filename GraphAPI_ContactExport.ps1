$csvFilePath = "C:\...\contactfile.csv"

# User's UPN or ID
$userUPN = "" # Replace with the specific user's UPN
$userId = ""

# Define the Graph API endpoint for creating contacts
$url = "https://graph.microsoft.com/v1.0/users/$userId/contacts"


$contacts = Get-MgUserContact -UserId $userUPN

$contactsToExport = $contacts | Select-Object `
    givenName,`
    surname,`
    initials,`
    @{Name="emailAddresses"; Expression={if ($_.emailAddresses) { $_.emailAddresses[0].address } else { $null }}},`
    @{Name="emailNames"; Expression={if ($_.emailAddresses) { $_.emailAddresses[0].name } else { $null }}},`
    @{Name="businessPhones"; Expression={[string]::Join(";", $_.businessPhones)}},`
    @{Name="categories"; Expression={[string]::Join(";", $_.categories)}},`
    @{Name="BusinessStreet"; Expression={if ($_.BusinessAddress) { $_.BusinessAddress[0].street } else { $null }}},`
    @{Name="BusinessCity"; Expression={if ($_.BusinessAddress) { $_.BusinessAddress[0].city } else { $null }}},`
    @{Name="BusinessState"; Expression={if ($_.BusinessAddress) { $_.BusinessAddress[0].state } else { $null }}},`
    @{Name="BusinessCountryOrRegion"; Expression={if ($_.BusinessAddress) { $_.BusinessAddress[0].countryOrRegion } else { $null }}},`
    @{Name="BusinessPostalCode"; Expression={if ($_.BusinessAddress) { $_.BusinessAddress[0].postalCode } else { $null }}},`
    companyName,`
    department,`
    officeLocation,`
    @{Name="LastModified"; Expression={$_.FieldValues.Modified}}

$contactsToExport | Export-Csv -Path $csvFilePath -NoTypeInformation
