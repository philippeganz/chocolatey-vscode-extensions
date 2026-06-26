param(
    [string]$ForcedPackages = ''
)

$ErrorActionPreference = 'Stop'

# Configure AU execution environment
$Env:au_Push = $true
$Env:au_Force = $false

# If forced packages are specified (e.g. "vscode-yaml"), AU will ignore versions and force update them
if ($ForcedPackages) {
    $Env:au_Force = $true
    $Env:au_Packages = $ForcedPackages
}

# Resolve the path to the 'automatic' directory where packages live
$packagesDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "..\automatic"
if (-not (Test-Path $packagesDir)) {
    throw "Automatic packages directory not found: $packagesDir"
}

Push-Location $packagesDir

try {
    # The main AU command to execute the update.ps1 scripts in all subfolders
    Update-AUPackages
} finally {
    Pop-Location
}
