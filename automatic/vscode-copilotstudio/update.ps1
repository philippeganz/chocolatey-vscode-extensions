[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-copilotstudio"
$global:ExtensionName = "vscode-copilotstudio"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
