[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "editorconfig"
$global:ExtensionName = "editorconfig"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
