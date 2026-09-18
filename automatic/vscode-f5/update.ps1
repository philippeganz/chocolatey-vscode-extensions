[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "f5devcentral"
$global:ExtensionName = "vscode-f5"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
