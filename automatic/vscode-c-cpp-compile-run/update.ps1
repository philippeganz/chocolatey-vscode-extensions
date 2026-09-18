[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "danielpinto8zz6"
$global:ExtensionName = "c-cpp-compile-run"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
