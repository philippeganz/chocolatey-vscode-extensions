[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ritwickdey"
$global:ExtensionName = "LiveServer"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
