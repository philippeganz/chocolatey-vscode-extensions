[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-azuretools"
$global:ExtensionName = "azure-dev"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
