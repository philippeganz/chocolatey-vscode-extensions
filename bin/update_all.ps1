param(
    [string]$ForcedPackages = ''
)

$ErrorActionPreference = 'Stop'

# Set the global AU variables directly instead of using the Options dictionary
$global:au_Push = $true
$global:au_Force = $false

if ($ForcedPackages) {
    $global:au_Force = $true
}

$opts = [ordered]@{
    Push = $true
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
