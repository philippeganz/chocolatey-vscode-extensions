[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "platformio"
$global:ExtensionName = "platformio-ide"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
