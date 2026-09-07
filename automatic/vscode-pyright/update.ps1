[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-pyright"
$global:ExtensionName = "pyright"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
