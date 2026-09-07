[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "eamodio"
$global:ExtensionName = "gitlens"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
