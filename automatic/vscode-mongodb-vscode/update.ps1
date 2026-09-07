[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "mongodb"
$global:ExtensionName = "mongodb-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
