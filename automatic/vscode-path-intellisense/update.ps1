[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "christian-kohler"
$global:ExtensionName = "path-intellisense"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
