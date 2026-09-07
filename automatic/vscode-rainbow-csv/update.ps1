[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "mechatroner"
$global:ExtensionName = "rainbow-csv"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
