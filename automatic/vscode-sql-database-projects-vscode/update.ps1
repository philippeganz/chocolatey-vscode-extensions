[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-mssql"
$global:ExtensionName = "sql-database-projects-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
