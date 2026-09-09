[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "github"
$global:ExtensionName = "github-vscode-theme"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
