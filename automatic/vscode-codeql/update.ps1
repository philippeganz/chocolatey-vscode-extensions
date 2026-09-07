[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "github"
$global:ExtensionName = "vscode-codeql"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
