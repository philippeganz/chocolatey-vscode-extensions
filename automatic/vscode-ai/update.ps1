[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-toolsai"
$global:ExtensionName = "vscode-ai"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
