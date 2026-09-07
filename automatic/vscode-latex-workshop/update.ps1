[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "james-yu"
$global:ExtensionName = "latex-workshop"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
