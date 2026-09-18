[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "rangav"
$global:ExtensionName = "vscode-thunder-client"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
