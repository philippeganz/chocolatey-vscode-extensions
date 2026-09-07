[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vscodevim"
$global:ExtensionName = "vim"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
