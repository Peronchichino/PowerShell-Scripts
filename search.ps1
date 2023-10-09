#primary input for what you want to find
$input = Read-Host "What do you want to find"

Get-Command -Name $input #alias
Get-Command -Verb $input
Get-Command -Noun $input

#Get-Command -Name $input Args Cert: -Syntax

Write-Host "`!!!----- All Files -----!!!"
Get-ChildItem -Recurse | Select-String $input -List | Select Path

Write-Host "!!!----- All Scripts -----!!!"
Find-Script -Name $input | Format-List -Property Name, Version, Author, Description

exit