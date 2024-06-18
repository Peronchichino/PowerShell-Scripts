#Connect-PnPOnline -url ""

#custom compare function Compare-Object only returned null even with properties
function CompareContacts($existCont,$newCont){
    $properties = @(
        "givenName","surname","emailAddresses","businessPhone","categories","CompanyName","Department","OfficeLocation"
    )

    foreach($property in $properties){
        $existVal = $existCont.$property
        $newVal = $newCont.$property

        if($existVal -is [System.Collections.IEnumerable] -and $newVal -is [System.Collections.IEnumerable]){
            $existVal = @($existVal) -join ","
            $newVal = @($newVal) -join ","
        }

        if($existVal -ne $newVal){
            return $true
        }
    }

    return $false
}

# Benchmark start
$benchmark = [System.Diagnostics.Stopwatch]::StartNew()

$userUPN = ""

$items = Get-PnPListItem -list ""

if($items.count -eq 0){
    Write-Host "Items werent retrieved or list is emtpy"
    return
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

    $existingContact = Get-MgUserContact -UserId $userUPN -Filter "emailAddresses/any(a: a/address eq '$($contact.emailAddresses)')"

    if($null -eq $existingContact){
        New-MgUserContact -UserId $userUPN -BodyParameter $params
    } else {
        $oldParams = @{
            givenName = $existingContact.givenName
            surname = $existingContact.surname
            emailAddresses = @(
                @{
                    address = $existingContact.emailAddresses
                    name = $existingContact.emailNames
                }
            )
            businessPhones = @($existingContact.businessPhones)
            categories = @($existingContact.categories)
            CompanyName = $existingContact.CompanyName
            Department = $existingContact.Department
            OfficeLocation = $existingContact.OfficeLocation
        }

        $differences = CompareContacts -existCont $oldParams -newCont $params

        if($differences){
            Remove-MgUserContact -UserId $userUPN -ContactId $existingContact.Id
            New-MgUserContact -UserId $userUPN -BodyParameter $params
        } else {
            Write-Host "Contact '$($contact.givenName) $($contact.surname)' already exists, contact was skipped"
        }
    }
}

# Benchmark stop 
$benchmark.Stop()

Write-Host "Benchmarking:`n-----------------------------"
Write-Host "Time elapsed: "$benchmark.Elapsed
Write-Host "Time elapsed (ms): "$benchmark.ElapsedMilliseconds"`n"
