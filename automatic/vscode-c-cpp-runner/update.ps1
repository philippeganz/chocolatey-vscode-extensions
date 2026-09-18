[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "franneck94"
$global:ExtensionName = "c-cpp-runner"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
