<#
.SYNOPSIS
Auto-generated uninstall script for Chocolatey.

.DESCRIPTION
Removes the installed VSIX extension from VS Code.
#>
$ErrorActionPreference = 'Stop'

Uninstall-VsCodeExtension -extensionId "ms-vscode.hexeditor"
