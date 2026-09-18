[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-azuretools"
$global:ExtensionName = "vscode-azurecontainerapps"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
