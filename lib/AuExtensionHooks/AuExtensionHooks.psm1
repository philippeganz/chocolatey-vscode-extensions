#Requires -Version 7.0
#Requires -Module au

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for AU Engine state')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', '', Justification = 'Required for AU Engine discovery')]
param()

$ErrorActionPreference = 'Stop'

Import-Module ChocoVSCodeCore -ErrorAction SilentlyContinue
Import-Module ChocoVSCodeMarketplace -ErrorAction SilentlyContinue

# =============================================================================
# Loader Engine
# =============================================================================
$publicDir = Join-Path $PSScriptRoot "public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}
