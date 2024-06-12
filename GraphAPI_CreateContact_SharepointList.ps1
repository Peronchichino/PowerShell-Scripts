
# Benchmark start
$benchmark = New-Object System.Diagnostics.Stopwatch
$benchmark.Start()

$items = Get-PnPListItem -list "list name"

if($items.count -eq 0){
    Write-Host "Items werent retrieved or list is emtpy"
    return
}

foreach($item in $items){
    Write-Host $item.FieldValues
}

$itemsToExport = $items | ForEach-Object {
    [PSCustomObject]@{
        GivenName = $_.FieldValues.Title
        Surname = $_.FieldValues.Surname
        Initials = $_.FieldValues.Initials
        emailAddresses = $_.FieldValues.emailAddresses
        emailNames = $_.FieldValues.emailNames
        businessPhones = $_.FieldValues.businessPhones
        categories = $_.FieldValues.categories
        CompanyName = $_.FieldValues.CompanyName
        Department = $_.FieldValues.Department
        OfficeLocation = $_.FieldValues.OfficeLocation
    }
}

$userUPN = "xxx" # Replace with the specific user's UPN
$userId = "xxx"

foreach ($contact in $itemsToExport) {
    $params = @{
        givenName = $contact.givenName
        surname = $contact.surname
        emailAddresses = @(
            @{
                address = $contact.emailAddresses
                name = $contact.emailNames
            }
        )
        businessPhones = @($contact.businessPhones)
        categories = @($contact.categories)
        CompanyName = $contact.CompanyName
        Department = $contact.Department
        OfficeLocation = $contact.OfficeLocation
    }

    # create new contact for the new user
    New-MgUserContact -UserId $userId -BodyParameter $params
} 

# Benchmark stop 
$benchmark.Stop()
Write-Host "Time elapsed: "$benchmark.Elapsed
Write-Host "Time elapsed (ms): "$benchmark.ElapsedMilliseconds
