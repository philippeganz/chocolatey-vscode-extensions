[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "MS-vsliveshare"
$global:ExtensionName = "vsliveshare"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
