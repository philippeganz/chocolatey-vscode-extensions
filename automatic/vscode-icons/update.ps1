[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vscode-icons-team"
$global:ExtensionName = "vscode-icons"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
