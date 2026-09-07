[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-azuretools"
$global:ExtensionName = "vscode-azurestorage"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
