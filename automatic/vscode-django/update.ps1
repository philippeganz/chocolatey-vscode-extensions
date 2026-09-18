[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "batisteo"
$global:ExtensionName = "vscode-django"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
