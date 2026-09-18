[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-edgedevtools"
$global:ExtensionName = "vscode-edge-devtools"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
