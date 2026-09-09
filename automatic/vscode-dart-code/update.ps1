[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "dart-code"
$global:ExtensionName = "dart-code"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
