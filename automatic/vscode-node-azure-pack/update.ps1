[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-vscode"
$global:ExtensionName = "vscode-node-azure-pack"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
