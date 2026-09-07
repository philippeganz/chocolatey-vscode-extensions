[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "onecentlin"
$global:ExtensionName = "laravel-blade"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
