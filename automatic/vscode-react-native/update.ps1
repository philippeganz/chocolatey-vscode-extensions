[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "msjsdiag"
$global:ExtensionName = "vscode-react-native"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
