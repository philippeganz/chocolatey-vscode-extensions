[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "formulahendry"
$global:ExtensionName = "auto-close-tag"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
