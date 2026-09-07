[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "usernamehw"
$global:ExtensionName = "errorlens"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
