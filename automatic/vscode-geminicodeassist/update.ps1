[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "google"
$global:ExtensionName = "geminicodeassist"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
