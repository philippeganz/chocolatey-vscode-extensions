[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "graphql"
$global:ExtensionName = "vscode-graphql-syntax"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
