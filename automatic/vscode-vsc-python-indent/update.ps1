[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "kevinrose"
$global:ExtensionName = "vsc-python-indent"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
