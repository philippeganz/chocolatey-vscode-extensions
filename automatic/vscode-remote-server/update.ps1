[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-vscode"
$global:ExtensionName = "remote-server"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
