[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-dotnettools"
$global:ExtensionName = "csdevkit"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
