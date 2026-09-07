[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-mssql"
$global:ExtensionName = "mssql"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
