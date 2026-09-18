[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-vscode"
$global:ExtensionName = "remote-explorer"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
