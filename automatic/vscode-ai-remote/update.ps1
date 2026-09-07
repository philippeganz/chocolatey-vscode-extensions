[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-toolsai"
$global:ExtensionName = "vscode-ai-remote"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
