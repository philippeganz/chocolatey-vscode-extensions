#Requires -Version 7.0

<#
.SYNOPSIS
    Defines the enumeration for extension eligibility states.
.DESCRIPTION
    This script loads the `ExtensionEligibilityState` enum into the PowerShell runspace.
    This enum represents the comprehensive status of a VS Code Extension as it is evaluated
    against the Chocolatey package ecosystem, the VS Code Marketplace, and local state.
#>
if (-not ('ExtensionEligibilityState' -as [type])) {
    Add-Type -TypeDefinition @"
    public enum ExtensionEligibilityState {
        Eligible = 0,
        MarketplaceNotFound = 10,
        AlreadyTracked = 20,
        NotTracked = 30,
        MarketplaceAbandonware = 40,
        InvalidCharacters = 50,
        ChocolateyOwnershipConflict = 60,
        MarketplaceDeprecated = 70,
        DependencyFailure = 80,
        InvalidFormat = 90
    }
"@
}
