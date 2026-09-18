[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-vscode"
$global:ExtensionName = "live-server"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
