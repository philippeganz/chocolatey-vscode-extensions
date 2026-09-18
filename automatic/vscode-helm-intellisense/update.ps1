[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "tim-koehler"
$global:ExtensionName = "helm-intellisense"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
