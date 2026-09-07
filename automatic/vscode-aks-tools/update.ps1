[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-kubernetes-tools"
$global:ExtensionName = "vscode-aks-tools"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
