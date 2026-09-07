[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "grapecity"
$global:ExtensionName = "gc-excelviewer"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
