[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "monokai"
$global:ExtensionName = "theme-monokai-pro-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
