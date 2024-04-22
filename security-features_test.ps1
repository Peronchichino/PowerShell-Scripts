<#
.SYNOPSIS
    Script that creates new anti phishing policy/rule, new safe links policy/rule, new safe attachment policy/rule
.DESCRIPTION
    Basic script made by trainee Lukas Buchmayer that has never been run before due to fear of messing up other policies and the like.

    Should make some very standard anti phishing policies with safe links and attachment policies. Nothing special, just wanted to test out the different cmdlets.
.EXAMPLE

.OUTPUTS
    --
.NOTES
    This is just a prototype made by a trainee, not sure if it works or not

    
#>

try{
    New-AntiPhishPolicy -Name "Test Phishing Policy" -AdminDisplayName "Test policy via script" `
        -EnableOrganizationDOmainsProtection $true `
        -EnableTargetedDomainsProtection $true `
        -TargetedDomainsToProtect test-lotterien.at `
        -TargetedDomainProtectionAction Quarantine `
        -EnableTargetedUserProtection $true `
        -TargetedUsersToProtect "cldadm_82816_testlab@testlotterien.at" `
        -TargetedUserProtectionAction Quarantine `
        -EnableMailboxIntelligenceProtection $true `
        -MailboxIntelligenceProtectionAction Quarantine `
        -EnabledSimilarUsersSafetyTips $true `
        -EnableSimilarDomainsSafetyTips $true `
        -EnableUnusualCharactersSafetyTips $true `
        -PhishThreshholdLevel 3 ` #more aggressive, options 1 2 3 4
        -SpoofQuarantineTag DefaultFullAccessWithNotificationPolicy `
        -EnableSpoofIntelligence $true

    New-AntiPhishRule -Name "Test Phishing Rule" `
        -AntiPhishPolicy "Test Phishing Policy" ` #policy name
        -SendToMemberOf "Engineering Department" #group identity/display name

    New-SafeAttachmentPolicy -Name "Test SafeAttach Policy" `
        -Enabled $true `
        -Redirect $true `
        -RedirectAddress "something@domain.at"

    New-SafeAttachmentRule

    New-SafeLinksPolicy

    New-SafeLinksRule

} catch{
    throw $_.Exception
}

Get-AntiPhishPolicy -Name "Test Phishing Policy" | Format-List
Get-AntiPhishRule -Name "Test Phishing Rule" | Format-List
Get-SafeAttachmentPolicy -Name "Test SafeAttach Policy" | Format-List
Get-SafeAttachmentRule -Name "Test SafeAttach Rule" | Format-List
Get-SafeLinksPolicy -Name "Test SafeLink Policy" | Format-List
Get-SafeLinksRule -Name "Test SafeLink Rule" | Format-List
