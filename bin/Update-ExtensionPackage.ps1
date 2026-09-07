#Requires -Version 7.0
#Requires -Module au
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    The package-level trigger script for the Chocolatey Automatic Updater (AU) Engine.

.DESCRIPTION
    This script serves as the shared execution stub for all VS Code extensions in the repository.
    Instead of duplicating 150+ lines of AU hook logic inside every single package's `update.ps1` file,
    each package simply sets its required global variables and dot-sources this script.

    This script is responsible for dynamically loading the `AuExtensionHooks` library to map the
    repository-wide `au_GetLatest`, `au_BeforeUpdate`, etc. hooks into the execution scope, and then
    natively triggering the AU `Update-Package` command for the specific calling package.

.EXAMPLE
    # Inside automatic/vscode-ai/update.ps1:
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
    param()

    $global:ExtensionPublisher = "ms-toolsai"
    $global:ExtensionName = "vscode-ai"

    . "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"

.NOTES
    This script is NOT designed to be executed manually or by the CI pipeline. It is strictly
    dot-sourced by the individual `update.ps1` files when the AU engine iterates over the pool.

    MANDATORY STATE: The calling script must define `$global:ExtensionPublisher` and
    `$global:ExtensionName` prior to dot-sourcing this file. These variables are strictly
    required by the underlying AU hooks to dynamically construct API calls.
#>

Import-Module "$PSScriptRoot\..\lib\AuExtensionHooks\AuExtensionHooks.psd1" -Force

# Trigger the native AU update pipeline using the loaded hooks
$pkgResult = Update-Package -ChecksumFor none

if ($pkgResult.Updated) {
    $nupkg = Get-ChildItem -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($nupkg) {
        if (($env:CHOCO_VSCODE_SKIP_VSIX_TEST -eq 'true')) {
            Write-Skip "Skipping Custom Dependency-Free Test for $($nupkg.Name) due to test overrides..." -Indent 1
        }
        else {
            Write-StyledMessage -Color Cyan -Message ">>> Running Custom Dependency-Free Test for $($nupkg.Name)..." -Indent 1
            choco install $nupkg.FullName --ignore-dependencies -y --no-progress
            if ($LASTEXITCODE -ne 0) {
                throw "Custom Test Failed for $($nupkg.Name)! The VSIX payload may be corrupted or uninstallable."
            }

            Write-Success "Test passed! Uninstalling..." -Indent 1
            choco uninstall $pkgResult.Name -y --no-progress
        }
    }
}

return $pkgResult
