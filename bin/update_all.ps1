[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param(
    [string]$ForcedPackages = ''
)

$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# AU ORCHESTRATOR CONFIGURATION
# -----------------------------------------------------------------------------
# The Chocolatey AU Engine evaluates parameters from the $global scope before it
# falls back to its Options dictionary. Due to a known parsing bug with the 'Force'
# parameter in Update-AUPackages, we explicitly inject our configurations globally.
#
# $global:au_Push = $true -> Ensures the package is uploaded to the Community Gallery
# $global:au_NoCheckRegistry = $true -> Prevents Test-Package from scanning the Windows Registry (Add/Remove Programs) since VS Code extensions don't write to it.
# -----------------------------------------------------------------------------
$global:au_Push = $true
$global:au_Force = $false
$global:au_NoCheckRegistry = $true

if ($ForcedPackages) {
    # Bypasses the internal math that aborts updates when local and remote versions match.
    $global:au_Force = $true
}

$opts = [ordered]@{
    Push  = $true
    Force = if ($ForcedPackages) { $true } else { $false }
}

# Resolve the path to the 'automatic' directory where packages live
$packagesDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "..\automatic"
if (-not (Test-Path $packagesDir)) {
    throw "Automatic packages directory not found: $packagesDir"
}

Push-Location $packagesDir

try {
    if ($ForcedPackages) {
        Update-AUPackages -Name $ForcedPackages -Options $opts
    } else {
        Update-AUPackages -Options $opts
    }
} finally {
    Pop-Location
}
