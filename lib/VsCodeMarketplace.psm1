#Requires -Version 7.0
#Requires -Module powershell-yaml

<#
.SYNOPSIS
Centralized helper module for interacting with the Visual Studio Code Marketplace API.
Contains robust, self-healing functions to abstract away API quirks, rate limits,
and platform-specific payload ambiguities.
#>

# =============================================================================
# Global Error Handling
# =============================================================================
# Enforce strict fail-fast behavior across this entire script/module.
# Any cmdlet or module import failure will immediately throw a terminating error.
# Override locally with -ErrorAction SilentlyContinue when needed.
$ErrorActionPreference = 'Stop'

# =============================================================================
# Import Modules
# =============================================================================
Import-Module "$PSScriptRoot\CoreHelpers.psm1"

# The absolute path to the root of the repository, resolved once during module load.
# This prevents brittle relative pathing (`$PSScriptRoot\..\..\`) inside nested component files.
$script:ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path

# The canonical base URL for the Microsoft Visual Studio Code Marketplace API.
# This state is maintained at the module level and natively accessible by all dot-sourced public/private functions.
$script:MarketplaceBaseUrl = "https://marketplace.visualstudio.com"

$publicDir = Join-Path $PSScriptRoot "VsCodeMarketplace\Public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}

Export-ModuleMember -Function Get-VsCodeMarketplaceMetadata, Get-VsCodeExtensionUrl, Invoke-RobustDownload, Expand-VsCodePayload, Update-NuspecDependency, Get-VsCodeNuspecMetadata, New-VerificationFile, Update-VsCodeNuspecMetadata, Save-VsCodeIcon, Update-NuspecCDataDescription, Save-NuspecXml, Invoke-WithMarketplaceRetry
