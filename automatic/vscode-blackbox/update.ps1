[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "blackboxapp"
$global:ExtensionName = "blackbox"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
