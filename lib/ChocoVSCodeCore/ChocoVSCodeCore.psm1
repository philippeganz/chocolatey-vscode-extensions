# =============================================================================
# Global Error Handling
# =============================================================================
$ErrorActionPreference = 'Stop'

# =============================================================================
# Loader Engine
# =============================================================================
$publicDir = Join-Path $PSScriptRoot "public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}
