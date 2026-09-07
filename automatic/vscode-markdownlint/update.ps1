[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "davidanson"
$global:ExtensionName = "vscode-markdownlint"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
