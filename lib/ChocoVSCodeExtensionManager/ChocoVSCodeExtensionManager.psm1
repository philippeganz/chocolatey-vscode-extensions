#Requires -Version 7.0
#Requires -Module ChocoVSCodeCore
#Requires -Module ChocoVSCodeMarketplace

$ErrorActionPreference = 'Stop'

$publicDir = Join-Path $PSScriptRoot "public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | Where-Object { $_.Name -ne "ExtensionEligibilityState.ps1" } | ForEach-Object {
        . $_.FullName
    }
}
