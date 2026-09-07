[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "redhat"
$global:ExtensionName = "vscode-yaml"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
