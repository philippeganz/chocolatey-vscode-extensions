[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-playwright"
$global:ExtensionName = "playwright"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
