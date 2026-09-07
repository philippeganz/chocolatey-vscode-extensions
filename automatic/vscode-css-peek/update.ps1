[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "pranaygp"
$global:ExtensionName = "vscode-css-peek"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
