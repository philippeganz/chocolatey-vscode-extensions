[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "Oracle"
$global:ExtensionName = "oracledevtools"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
