# =============================================================================
# Global Error Handling
# =============================================================================
$ErrorActionPreference = 'Stop'

# =============================================================================
# Import Modules
# =============================================================================
Import-Module "$PSScriptRoot\..\ChocoVSCodeCore\ChocoVSCodeCore.psm1"
Import-Module "$PSScriptRoot\..\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psm1"

# =============================================================================
# Loader Engine
# =============================================================================
$publicDir = Join-Path $PSScriptRoot "public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}
