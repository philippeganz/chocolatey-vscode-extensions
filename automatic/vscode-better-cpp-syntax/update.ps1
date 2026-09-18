[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "jeff-hykin"
$global:ExtensionName = "better-cpp-syntax"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
