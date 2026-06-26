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

# The main AU command to execute the update.ps1 scripts in all subfolders
Update-AUPackages -Options @{
    Threads = 3
}
