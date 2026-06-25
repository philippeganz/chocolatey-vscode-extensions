$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$vsixPath = Join-Path $toolsDir "esbenp.prettier-vscode-12.4.0.vsix"

# Chocolatey-vscode.extension module provides Install-VsCodeExtension
Install-VsCodeExtension -extensionId $vsixPath

