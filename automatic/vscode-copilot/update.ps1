[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "GitHub"
$global:ExtensionName = "copilot"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
