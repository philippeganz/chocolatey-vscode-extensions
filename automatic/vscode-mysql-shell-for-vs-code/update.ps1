[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "Oracle"
$global:ExtensionName = "mysql-shell-for-vs-code"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
