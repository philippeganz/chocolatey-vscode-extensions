[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "devsense"
$global:ExtensionName = "phptools-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
