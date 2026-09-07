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
Import-Module "$PSScriptRoot\..\ChocoVSCodeCore\ChocoVSCodeCore.psm1"

# =============================================================================
# Module State Initialization
# =============================================================================
# The canonical base URL for the Microsoft Visual Studio Code Marketplace API.
# This state is maintained at the module level and natively accessible by all dot-sourced public/private functions.
$script:MarketplaceBaseUrl = "https://marketplace.visualstudio.com"

# =============================================================================
# Loader Engine
# =============================================================================
$publicDir = Join-Path $PSScriptRoot "public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}
