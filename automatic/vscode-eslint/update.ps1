[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "dbaeumer"
$global:ExtensionName = "vscode-eslint"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
