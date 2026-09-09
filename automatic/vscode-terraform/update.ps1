[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "hashicorp"
$global:ExtensionName = "terraform"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
