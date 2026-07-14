<#
.SYNOPSIS
Auto-generated install script for Chocolatey.

.DESCRIPTION
Downloads and installs the VSIX extension payload into VS Code.
#>
# -----------------------------------------------------------------------------
# Chocolatey Installation Script
#
# This script is executed by Chocolatey when the package is installed.
# It resolves the path to the bundled .vsix payload and hands it off to the
# 'chocolatey-vscode.extension' dependency, which natively injects the
# extension into Visual Studio Code while remaining entirely offline.
# -----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# The payload is entirely embedded in the package to guarantee Air-Gap compliance.
$vsixPath = Join-Path $toolsDir "techer.open-in-browser-2.0.0.vsix"

# Install-VsCodeExtension is a specialized helper provided by the chocolatey-vscode.extension dependency.
Install-VsCodeExtension -extensionId $vsixPath
