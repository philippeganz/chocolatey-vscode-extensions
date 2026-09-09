[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "hashicorp"
$global:ExtensionName = "sentinel"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
