[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "bmewburn"
$global:ExtensionName = "vscode-intelephense-client"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
