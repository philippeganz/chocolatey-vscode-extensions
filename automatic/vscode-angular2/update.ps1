[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "johnpapa"
$global:ExtensionName = "angular2"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
