[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "redhat"
$global:ExtensionName = "fabric8-analytics"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
