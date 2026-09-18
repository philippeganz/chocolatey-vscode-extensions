[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "alefragnani"
$global:ExtensionName = "project-manager"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
