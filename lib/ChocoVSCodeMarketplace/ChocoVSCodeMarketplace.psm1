#Requires -Version 7.0
#Requires -Module ChocoVSCodeCore

$ErrorActionPreference = 'Stop'

$script:MarketplaceBaseUrl = "https://marketplace.visualstudio.com"

$publicDir = Join-Path $PSScriptRoot "public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}
