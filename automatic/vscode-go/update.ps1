[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "golang"
$global:ExtensionName = "go"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
