[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "redhat"
$global:ExtensionName = "vscode-community-server-connector"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
