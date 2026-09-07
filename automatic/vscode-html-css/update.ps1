[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ecmel"
$global:ExtensionName = "vscode-html-css"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
