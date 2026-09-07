[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "johnpapa"
$global:ExtensionName = "vscode-peacock"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
