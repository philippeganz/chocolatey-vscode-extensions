[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "timonwong"
$global:ExtensionName = "shellcheck"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
