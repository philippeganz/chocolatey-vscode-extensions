[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "dart-code"
$global:ExtensionName = "flutter"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
