[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "waderyan"
$global:ExtensionName = "gitblame"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
