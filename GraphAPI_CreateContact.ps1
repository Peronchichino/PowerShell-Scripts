$id = ""

$params = @{
  givenName = "JOhn" #necessary
	surname = "DOe" #necessary
	initials = "J.D."
	emailAddresses = @(#not really necessary
		@{
			address = "johndoe@firma.com"
			name = "john doe"
		}
	)
	businessPhones = @( #very necessary
	    "+101 421389083190"
    )
    categories = @( #necessary
        "test cat"
    )
	BusinessAddress = @( #could be cool
		@{#doesnt do anything in the contact
			street = "Street Hellish 1231"
			city = "wien"
			state = "wien"
			countryOrRegion = "Austria"
			postalCode = "1010"
		}
	)
	companyName = "Cuisino Example" #necessary
	department = "test department" #maybe necessary
	officeLocation = "basically just a string blablalblallblalblablabblal limit test" #necessary
	lastModifiedDateTime = Get-Date
}

New-MgUserContact -UserId $id -BodyParameter $params
