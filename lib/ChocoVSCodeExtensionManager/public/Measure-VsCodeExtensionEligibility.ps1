#Requires -Version 7.0

<#
.SYNOPSIS
    Evaluates a VS Code extension for its eligibility to be scaffolded into the Chocolatey ecosystem.

.DESCRIPTION
    A rigorous compliance and validation engine that evaluates an extension against multiple safety
    and policy criteria before it is allowed to enter the workspace.

    The function strictly verifies:
    1. Lexical compliance (publisher.extension formatting).
    2. Character safety (lowercase alphanumeric and hyphens).
    3. State collision (ensuring it isn't already tracked in extensions.json).
    4. Marketplace availability (preventing 404s).
    5. Deprecation status (preventing scaffolding of obsolete extensions).
    6. Abandonware checks (rejecting extensions not updated in 3+ years).
    7. Ownership conflicts (ensuring the user owns the Chocolatey package if it already exists).

    Returns a standardized Hashtable containing the strict State enum and a contextual Message.

.PARAMETER ExtensionId
    The raw extension identifier to evaluate (e.g., 'ms-python.python').

.PARAMETER CurrentState
    The parsed list of already-tracked extension IDs from the extensions.json file.

.EXAMPLE
    Measure-VsCodeExtensionEligibility -ExtensionId "ms-python.python" -CurrentState $poolList

.OUTPUTS
    [System.Collections.Hashtable]
#>
function Measure-VsCodeExtensionEligibility {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $ExtensionId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]
        $CurrentState
    )

    $cleanId = $ExtensionId.ToLower()

    # 1. Format Check
    $parts = $cleanId -split '\.'
    if ($parts.Count -ne 2) {
        return @{ State = [ExtensionEligibilityState]::InvalidFormat; Message = "Invalid ID format. Must be 'publisher.extension'." }
    }

    # 2. Regex Check
    if ($cleanId -notmatch '^[a-z0-9-]+\.[a-z0-9-]+$') {
        return @{ State = [ExtensionEligibilityState]::InvalidCharacters; Message = "Invalid characters. Only lowercase alphanumeric and hyphens allowed." }
    }

    # 3. State Check (Case-Insensitive)
    if ($CurrentState -contains $cleanId) {
        return @{ State = [ExtensionEligibilityState]::AlreadyTracked; Message = "Extension is already tracked locally." }
    }

    # 4. Marketplace Check (404 and Metadata)
    $meta = Get-VsCodeMarketplaceMetadata -Publisher $parts[0] -ExtensionName $parts[1]
    if (-not $meta) {
        return @{ State = [ExtensionEligibilityState]::MarketplaceNotFound; Message = "Extension not found on the VS Code Marketplace." }
    }

    # 5. Health Check (Deprecation & Abandonware)
    $health = Measure-VsCodeExtensionHealth -Metadata $meta

    if ($health.IsDeprecated) {
        return @{ State = [ExtensionEligibilityState]::MarketplaceDeprecated; Message = $health.DeprecationMessage }
    }

    if ($health.IsAbandonware) {
        return @{ State = [ExtensionEligibilityState]::MarketplaceAbandonware; Message = "Extension has not been updated in over 3 years ($($health.YearsOld) years old)." }
    }

    # 7. Chocolatey Ownership Conflict Check
    $pkgName = Get-ChocoVSCodePackageName -ExtensionId $ExtensionId
    $chocoMeta = Get-ChocolateyPackageMetadata -PackageName $pkgName
    if ($chocoMeta -and $chocoMeta.Owners -notmatch 'philippe\.ganz') {
        return @{ State = [ExtensionEligibilityState]::ChocolateyOwnershipConflict; Message = "Package '$pkgName' already exists on Chocolatey, but you are not listed as an owner ($($chocoMeta.Owners))." }
    }

    return @{ State = [ExtensionEligibilityState]::Eligible; Message = "Package is eligible for scaffolding." }
}
