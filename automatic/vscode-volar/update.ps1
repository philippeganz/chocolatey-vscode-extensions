[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vue"
$global:ExtensionName = "volar"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
