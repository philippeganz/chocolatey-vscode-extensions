$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$vsixPath = Join-Path $toolsDir "{{Publisher}}.{{ExtensionName}}-{{Version}}.vsix"

# Chocolatey-vscode.extension module provides Install-VsCodeExtension
Install-VsCodeExtension -extensionId $vsixPath
