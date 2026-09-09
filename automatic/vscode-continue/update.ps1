[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "continue"
$global:ExtensionName = "continue"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
