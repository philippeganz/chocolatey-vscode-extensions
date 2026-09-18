[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "graphql"
$global:ExtensionName = "vscode-graphql-execution"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
