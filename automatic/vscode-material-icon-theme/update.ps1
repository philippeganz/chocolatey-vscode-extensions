[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "PKief"
$global:ExtensionName = "material-icon-theme"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
